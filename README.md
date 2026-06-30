# ESP32 Codex Status Light

An ESP32-S3 traffic-light style status lamp for Codex or other desktop tools.
The board listens for serial commands from a PowerShell script and maps each
status to a simple green, yellow, or red light pattern.

## Hardware

| ESP32-S3 | Traffic light module |
| --- | --- |
| GND | GND |
| D5 / GPIO5 | Green |
| D6 / GPIO6 | Yellow |
| D7 / GPIO7 | Red |

## Quick Start

Open an ESP-IDF terminal, build, and flash the firmware:

```powershell
.\start_esp_idf_terminal.bat
idf.py -p COM6 flash
```

Send status updates from Windows:

```powershell
.\codex_status_light.ps1 idle
.\codex_status_light.ps1 running
.\codex_status_light.ps1 marquee
.\codex_status_light.ps1 chase
.\codex_status_light.ps1 permission
.\codex_status_light.ps1 done
.\codex_status_light.ps1 error
.\codex_status_light.ps1 off
.\codex_status_light.ps1 test
```

More wiring notes and Codex hook setup details are in [STATUS_LIGHT.md](STATUS_LIGHT.md).

Install Codex hooks for automatic status updates:

```powershell
.\scripts\install_codex_hooks.ps1 -Port COM6
```

When a Codex goal is active, the `Stop` hook keeps the lamp in `running`
instead of switching to `done` between automatic continuations.
