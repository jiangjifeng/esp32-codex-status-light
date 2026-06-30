#include <ctype.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

/*
 * Board label defaults:
 *   D5 -> GPIO5  green
 *   D6 -> GPIO6  yellow
 *   D7 -> GPIO7  red
 *
 * If your ESP32-S3 board maps D5/D6/D7 differently, only change these values.
 */
#define GREEN_LED_GPIO GPIO_NUM_5
#define YELLOW_LED_GPIO GPIO_NUM_6
#define RED_LED_GPIO GPIO_NUM_7

/* GND/R/Y/G traffic-light modules are usually active-high. */
#define LED_ACTIVE_LEVEL 1
#define LED_INACTIVE_LEVEL 0

typedef enum {
    STATUS_IDLE,
    STATUS_DONE,
    STATUS_RUNNING,
    STATUS_PERMISSION,
    STATUS_ERROR,
    STATUS_OFF,
} codex_status_t;

static volatile codex_status_t s_status = STATUS_IDLE;

static void set_one_led(gpio_num_t gpio, int on)
{
    gpio_set_level(gpio, on ? LED_ACTIVE_LEVEL : LED_INACTIVE_LEVEL);
}

static void set_lights(int green, int yellow, int red)
{
    set_one_led(GREEN_LED_GPIO, green);
    set_one_led(YELLOW_LED_GPIO, yellow);
    set_one_led(RED_LED_GPIO, red);
}

static void run_lamp_test(void)
{
    set_lights(1, 0, 0);
    vTaskDelay(pdMS_TO_TICKS(300));
    set_lights(0, 1, 0);
    vTaskDelay(pdMS_TO_TICKS(300));
    set_lights(0, 0, 1);
    vTaskDelay(pdMS_TO_TICKS(300));
    set_lights(1, 1, 1);
    vTaskDelay(pdMS_TO_TICKS(300));
    set_lights(0, 0, 0);
    vTaskDelay(pdMS_TO_TICKS(200));
}

static void configure_gpio(void)
{
    gpio_config_t io_conf = {
        .pin_bit_mask = (1ULL << GREEN_LED_GPIO) | (1ULL << YELLOW_LED_GPIO) | (1ULL << RED_LED_GPIO),
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };

    gpio_config(&io_conf);
    set_lights(0, 0, 0);
}

static void print_help(void)
{
    printf("\nCodex status light commands:\n");
    printf("  running | busy | yellow      -> yellow blinking, AI is working\n");
    printf("  permission | approval | auth -> red fast blink, go approve/deny\n");
    printf("  done | complete | green      -> green on, work finished\n");
    printf("  idle | ready                 -> green slow blink, waiting for command\n");
    printf("  error | blocked              -> red slow blink, needs attention\n");
    printf("  off                          -> all off\n");
    printf("  test                         -> cycle all lamps\n");
    printf("  help                         -> show this help\n\n");
}

static void lowercase(char *text)
{
    for (size_t i = 0; text[i] != '\0'; ++i) {
        text[i] = (char)tolower((unsigned char)text[i]);
    }
}

static void handle_command(char *command)
{
    lowercase(command);

    if (strcmp(command, "idle") == 0 || strcmp(command, "ready") == 0 ||
        strcmp(command, "waiting") == 0) {
        s_status = STATUS_IDLE;
        printf("status=idle\n");
    } else if (strcmp(command, "done") == 0 || strcmp(command, "complete") == 0 ||
               strcmp(command, "completed") == 0 || strcmp(command, "finished") == 0 ||
               strcmp(command, "green") == 0 || strcmp(command, "g") == 0) {
        s_status = STATUS_DONE;
        printf("status=done\n");
    } else if (strcmp(command, "running") == 0 || strcmp(command, "run") == 0 ||
               strcmp(command, "busy") == 0 || strcmp(command, "thinking") == 0 ||
               strcmp(command, "yellow") == 0 || strcmp(command, "y") == 0) {
        s_status = STATUS_RUNNING;
        printf("status=running\n");
    } else if (strcmp(command, "permission") == 0 || strcmp(command, "approval") == 0 ||
               strcmp(command, "approve") == 0 || strcmp(command, "auth") == 0 ||
               strcmp(command, "authorize") == 0 || strcmp(command, "needs_permission") == 0) {
        s_status = STATUS_PERMISSION;
        printf("status=permission\n");
    } else if (strcmp(command, "error") == 0 || strcmp(command, "blocked") == 0 ||
               strcmp(command, "failed") == 0 || strcmp(command, "attention") == 0 ||
               strcmp(command, "red") == 0 || strcmp(command, "r") == 0) {
        s_status = STATUS_ERROR;
        printf("status=error\n");
    } else if (strcmp(command, "off") == 0 || strcmp(command, "0") == 0) {
        s_status = STATUS_OFF;
        printf("status=off\n");
    } else if (strcmp(command, "test") == 0) {
        printf("running lamp test\n");
        run_lamp_test();
    } else if (strcmp(command, "help") == 0 || strcmp(command, "?") == 0) {
        print_help();
    } else if (command[0] != '\0') {
        printf("unknown command: %s\n", command);
        print_help();
    }
}

static void status_render_task(void *arg)
{
    (void)arg;
    bool blink_on = false;

    while (true) {
        switch (s_status) {
        case STATUS_IDLE:
            blink_on = !blink_on;
            set_lights(blink_on, 0, 0);
            vTaskDelay(pdMS_TO_TICKS(blink_on ? 120 : 1880));
            break;
        case STATUS_DONE:
            set_lights(1, 0, 0);
            vTaskDelay(pdMS_TO_TICKS(200));
            break;
        case STATUS_RUNNING:
            blink_on = !blink_on;
            set_lights(0, blink_on, 0);
            vTaskDelay(pdMS_TO_TICKS(450));
            break;
        case STATUS_PERMISSION:
            blink_on = !blink_on;
            set_lights(0, 0, blink_on);
            vTaskDelay(pdMS_TO_TICKS(150));
            break;
        case STATUS_ERROR:
            blink_on = !blink_on;
            set_lights(0, 0, blink_on);
            vTaskDelay(pdMS_TO_TICKS(900));
            break;
        case STATUS_OFF:
        default:
            set_lights(0, 0, 0);
            vTaskDelay(pdMS_TO_TICKS(200));
            break;
        }
    }
}

static void serial_command_task(void *arg)
{
    (void)arg;
    char line[48] = {0};
    size_t length = 0;

    print_help();
    printf("ready; default status=idle\n");

    while (true) {
        int ch = getchar();

        if (ch == EOF) {
            vTaskDelay(pdMS_TO_TICKS(20));
            continue;
        }

        if (ch == '\r' || ch == '\n') {
            line[length] = '\0';
            handle_command(line);
            length = 0;
            memset(line, 0, sizeof(line));
            continue;
        }

        if (length < sizeof(line) - 1) {
            line[length++] = (char)ch;
        }
    }
}

void app_main(void)
{
    configure_gpio();
    run_lamp_test();

    xTaskCreate(status_render_task, "status_render", 2048, NULL, 5, NULL);
    xTaskCreate(serial_command_task, "serial_command", 3072, NULL, 5, NULL);
}
