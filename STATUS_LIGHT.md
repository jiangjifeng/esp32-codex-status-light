# Codex Status Light

Traffic-light module wiring:

| ESP32-S3 | Module |
| --- | --- |
| GND | GND |
| D5 / GPIO5 | Green |
| D6 / GPIO6 | Yellow |
| D7 / GPIO7 | Red |

## Status Mapping

| AI status | Command | Light effect | Meaning |
| --- | --- | --- | --- |
| Needs your permission | `permission` | red fast blink | Go approve or deny the request |
| Error / blocked | `error` | red slow blink | Something failed; go inspect it |
| Working | `running` | green/yellow/red chase | AI is thinking or editing |
| Finished | `done` | green solid | Work is done |
| Idle | `idle` | green slow blink | Waiting for your next instruction |
| Off | `off` | all off | Disabled / no signal |

## Build And Flash

```powershell
.\start_esp_idf_terminal.bat
idf.py -p COM6 flash
```

## Send Status

```powershell
.\codex_status_light.ps1 idle
.\codex_status_light.ps1 done
.\codex_status_light.ps1 running
.\codex_status_light.ps1 marquee
.\codex_status_light.ps1 chase
.\codex_status_light.ps1 permission
.\codex_status_light.ps1 error
.\codex_status_light.ps1 off
.\codex_status_light.ps1 test
```

The script does not track projects. If another tool is coordinating multiple AI
tasks, it should choose the highest-priority final status and send only that one
command to the lamp.

## Global Codex Hooks

Install the hook entries into your global Codex config:

```powershell
.\scripts\install_codex_hooks.ps1 -Port COM6
```

The installer backs up an existing `hooks.json`, preserves unrelated hooks, and
adds or replaces only the status-light entries. The generated global config is
written to:

```text
%USERPROFILE%\.codex\hooks.json
```

The committed hook template lives at:

```text
hooks\codex_status_light_hook.ps1
hooks\hooks.example.json
```

Hook mapping:

| Codex event | Lamp command |
| --- | --- |
| `SessionStart` | `idle` |
| `UserPromptSubmit` | `running` |
| `PostToolUse` | `running` |
| `PermissionRequest` | `permission` |
| `Stop` | `running` if a Codex goal is still active, otherwise `done` |

Restart Codex after changing hooks. The first time Codex sees these command
hooks, run `/hooks` and trust them.

The hook writes a small diagnostic log to:

```text
%TEMP%\codex_status_light_hook.log
```

## GPIO Mapping

If the wrong lamp turns on, update these macros in
`codex_status_light/main/codex_status_light_main.c`:

```c
#define GREEN_LED_GPIO GPIO_NUM_5
#define YELLOW_LED_GPIO GPIO_NUM_6
#define RED_LED_GPIO GPIO_NUM_7
```
