# ESP32 Codex Status Light

An ESP32-S3 traffic-light status lamp for Codex or other desktop tools. The
firmware listens for serial commands and displays the current AI/work status
with a three-light module.

## What It Does

| Command | Light effect | Meaning |
| --- | --- | --- |
| `idle` | green slow blink | Waiting for the next instruction |
| `running` | green/yellow/red chase | Codex is thinking, editing, or continuing a goal |
| `permission` | red fast blink | Codex needs approval |
| `done` | green solid | Work is finished |
| `error` | red slow blink | Something is blocked or failed |
| `off` | all off | Disabled |
| `test` | cycles all lights | Hardware check |

`marquee` and `chase` are aliases for `running`.

## Hardware

This project expects an ESP32-S3 board and a simple traffic-light LED module.

| ESP32-S3 | Traffic light module |
| --- | --- |
| GND | GND |
| D5 / GPIO5 | Green |
| D6 / GPIO6 | Yellow |
| D7 / GPIO7 | Red |

If your board labels map to different GPIOs, update the macros in
[codex_status_light/main/codex_status_light_main.c](codex_status_light/main/codex_status_light_main.c).

## Software Requirements

- Windows PowerShell
- Git
- ESP-IDF installed locally
- Python used by ESP-IDF
- A serial port connected to the ESP32-S3, for example `COM6`

The helper script defaults to these local paths:

```text
IDF_TOOLS_PATH=C:\Espressif\tools
IDF_EXPORT_PS1=C:\Espressif\frameworks\esp-idf-v6.0.2\export.ps1
IDF_PYTHON_DIR=%LOCALAPPDATA%\Programs\Python\Python312
```

If your ESP-IDF install is different, set those environment variables before
running `start_esp_idf_terminal.bat`.

## Clone

```powershell
git clone https://github.com/jiangjifeng/esp32-codex-status-light.git
cd esp32-codex-status-light
```

## Build And Flash

Open an ESP-IDF terminal from the repo:

```powershell
.\start_esp_idf_terminal.bat
```

In the ESP-IDF terminal, flash the firmware:

```powershell
idf.py -p COM6 flash
```

Use your actual serial port instead of `COM6` if needed.

## Manual Test

After flashing, send commands from the repo root:

```powershell
.\codex_status_light.ps1 test -Port COM6
.\codex_status_light.ps1 running -Port COM6
.\codex_status_light.ps1 permission -Port COM6
.\codex_status_light.ps1 done -Port COM6
.\codex_status_light.ps1 idle -Port COM6
```

If `running` works, the light should chase green, yellow, red, then yellow.

## Install Codex Hooks

Install global Codex hooks for automatic status updates:

```powershell
.\scripts\install_codex_hooks.ps1 -Port COM6
```

The installer:

- backs up the existing `%USERPROFILE%\.codex\hooks.json`
- preserves unrelated hooks
- writes UTF-8 JSON without BOM
- adds status-light hooks for Codex lifecycle events

After installing hooks, restart Codex. If Codex asks you to review hooks, run:

```text
/hooks
```

Then trust the new or changed command hooks.

## Hook Behavior

| Codex event | Lamp command |
| --- | --- |
| `SessionStart` | `idle` |
| `UserPromptSubmit` | `running` |
| `PostToolUse` | `running` |
| `PermissionRequest` | `permission` |
| `Stop` | keeps `running` while a Codex goal is active, otherwise `done` |

The hook writes diagnostics to:

```text
%TEMP%\codex_status_light_hook.log
```

More details are in [STATUS_LIGHT.md](STATUS_LIGHT.md).
