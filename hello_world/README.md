# Codex Status Light Firmware

This ESP-IDF project runs on an ESP32-S3 and controls a three-light status
module over GPIO. It listens on the serial console for text commands such as
`idle`, `running`, `permission`, `done`, `error`, `off`, and `test`.

## Build

From this directory:

```powershell
idf.py set-target esp32s3
idf.py build
idf.py -p COM6 flash
```

## GPIO Defaults

| Signal | GPIO |
| --- | --- |
| Green | GPIO5 |
| Yellow | GPIO6 |
| Red | GPIO7 |

If your board maps the D5, D6, or D7 labels differently, update the GPIO macros
in [main/hello_world_main.c](main/hello_world_main.c).
