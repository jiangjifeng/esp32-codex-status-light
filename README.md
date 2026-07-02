# ESP32 Codex Status Light / ESP32 Codex 状态灯

一个基于 ESP32-S3 的 Codex 状态灯项目。固件通过串口接收状态命令，并用三色交通灯模块显示当前 AI/工作状态。

An ESP32-S3 traffic-light status lamp for Codex or other desktop tools. The firmware listens for serial commands and displays the current AI/work status with a three-light module.

## What It Does / 功能说明

| Command / 命令 | Light effect / 灯光效果 | Meaning / 含义 |
| --- | --- | --- |
| `idle` | green slow blink / 绿灯慢闪 | Waiting for the next instruction / 等待下一条指令 |
| `thinking` | yellow slow blink / 黄灯慢闪 | Codex is reasoning / Codex 正在思考 |
| `tool` | yellow fast blink / 黄灯快闪 | A tool or command is running / 正在调用工具或命令 |
| `git` | green+yellow blink / 绿黄同时闪 | Git or GitHub operation / Git 或 GitHub 操作 |
| `running` | green/yellow/red chase / 绿黄红跑马灯 | A goal is progressing / 目标正在推进 |
| `permission` | red fast blink / 红灯快闪 | Codex needs approval / Codex 需要你授权 |
| `limited` | yellow/red alternating / 黄红交替 | Usage, quota, or budget limit reached / 达到使用、额度或预算限制 |
| `done` | green solid / 绿灯常亮 | Work is finished / 工作已完成 |
| `error` | red slow blink / 红灯慢闪 | Something is blocked or failed / 出现阻塞或失败 |
| `off` | all off / 全部关闭 | Disabled / 关闭状态灯 |
| `test` | cycles all lights / 依次点亮所有灯 | Hardware check / 硬件测试 |

`marquee` and `chase` are aliases for `running`. `editing`, `edit`, and `write` are accepted for compatibility and use the same effect as `tool`.

`marquee` 和 `chase` 是 `running` 的别名。`editing`、`edit`、`write` 会作为兼容别名接收，灯效等同于 `tool`。

## Hardware / 硬件

需要一块 ESP32-S3 开发板和一个简单的三色交通灯 LED 模块。

This project expects an ESP32-S3 board and a simple traffic-light LED module.

| ESP32-S3 | Traffic light module / 交通灯模块 |
| --- | --- |
| GND | GND |
| D5 / GPIO5 | Green / 绿灯 |
| D6 / GPIO6 | Yellow / 黄灯 |
| D7 / GPIO7 | Red / 红灯 |

如果你的开发板 D5、D6、D7 对应的 GPIO 不同，请修改这里的宏：
[codex_status_light/main/codex_status_light_main.c](codex_status_light/main/codex_status_light_main.c)

If your board labels map to different GPIOs, update the macros in:
[codex_status_light/main/codex_status_light_main.c](codex_status_light/main/codex_status_light_main.c)

## Software Requirements / 软件要求

- Windows PowerShell
- Git
- ESP-IDF installed locally / 本地已安装 ESP-IDF
- Python used by ESP-IDF / ESP-IDF 使用的 Python
- A serial port connected to the ESP32-S3, for example `COM6` / ESP32-S3 对应的串口，例如 `COM6`

辅助脚本默认使用这些本地路径：

The helper script defaults to these local paths:

```text
IDF_TOOLS_PATH=C:\Espressif\tools
IDF_EXPORT_PS1=C:\Espressif\frameworks\esp-idf-v6.0.2\export.ps1
IDF_PYTHON_DIR=%LOCALAPPDATA%\Programs\Python\Python312
```

如果你的 ESP-IDF 安装路径不同，请先设置这些环境变量，再运行 `start_esp_idf_terminal.bat`。

If your ESP-IDF install is different, set those environment variables before running `start_esp_idf_terminal.bat`.

## Clone / 克隆项目

```powershell
git clone https://github.com/jiangjifeng/esp32-codex-status-light.git
cd esp32-codex-status-light
```

## Build And Flash / 编译和烧录

在仓库目录打开 ESP-IDF 终端：

Open an ESP-IDF terminal from the repo:

```powershell
.\start_esp_idf_terminal.bat
```

在 ESP-IDF 终端中烧录固件：

In the ESP-IDF terminal, flash the firmware:

```powershell
idf.py -p COM6 flash
```

如果你的串口不是 `COM6`，请替换成实际串口。

Use your actual serial port instead of `COM6` if needed.

## Manual Test / 手动测试

烧录完成后，在仓库根目录发送状态命令：

After flashing, send commands from the repo root:

```powershell
.\codex_status_light.ps1 test -Port COM6
.\codex_status_light.ps1 thinking -Port COM6
.\codex_status_light.ps1 tool -Port COM6
.\codex_status_light.ps1 git -Port COM6
.\codex_status_light.ps1 running -Port COM6
.\codex_status_light.ps1 permission -Port COM6
.\codex_status_light.ps1 limited -Port COM6
.\codex_status_light.ps1 done -Port COM6
.\codex_status_light.ps1 idle -Port COM6
```

如果 `running` 正常，灯光会按绿、黄、红、黄循环跑马。

If `running` works, the light should chase green, yellow, red, then yellow.

## Install Codex Hooks / 安装 Codex Hooks

安装全局 Codex hooks，让 Codex 自动更新状态灯：

Install global Codex hooks for automatic status updates:

```powershell
.\scripts\install_codex_hooks.ps1 -Port COM6
```

安装脚本会：

The installer:

- backs up the existing `%USERPROFILE%\.codex\hooks.json` / 备份现有 `%USERPROFILE%\.codex\hooks.json`
- preserves unrelated hooks / 保留其它无关 hooks
- writes UTF-8 JSON without BOM / 写入无 BOM 的 UTF-8 JSON
- adds status-light hooks for Codex lifecycle events / 添加 Codex 生命周期状态灯 hooks

安装后请重启 Codex。如果 Codex 要求你审核 hooks，请运行：

After installing hooks, restart Codex. If Codex asks you to review hooks, run:

```text
/hooks
```

然后信任新增或变更的 command hooks。

Then trust the new or changed command hooks.

## Hook Behavior / Hook 行为

| Codex event / Codex 事件 | Lamp command / 灯光命令 |
| --- | --- |
| `SessionStart` | `idle` |
| `UserPromptSubmit` | `thinking` |
| `PreToolUse` | `tool`, or `git` when the hook input exposes a Git/GitHub command |
| `PostToolUse` | `running` if an active goal continues, otherwise `thinking` / 如果目标仍在执行则发送 `running`，否则回到 `thinking` |
| `PermissionRequest` | `permission` |
| `Stop` | sends `running` while an active goal continues, `limited` for usage/budget limits, otherwise `done` / 如果目标仍在执行则发送 `running` 跑马灯，达到使用/预算限制时发送 `limited`，否则切到 `done` |

Git detection is best-effort. If Codex does not provide command text to the hook,
Git operations fall back to the generic `tool` effect.

Git 识别是尽力而为：如果 Codex 没有把具体命令文本传给 hook，Git 操作会退化成普通 `tool` 灯效。

hook 诊断日志写入：

The hook writes diagnostics to:

```text
%TEMP%\codex_status_light_hook.log
```

To verify hook behavior without using the real serial port:

无需真实串口即可验证 hook 行为：

```powershell
.\scripts\test_codex_status_light_hook.ps1
```

更多细节见 [STATUS_LIGHT.md](STATUS_LIGHT.md)。

More details are in [STATUS_LIGHT.md](STATUS_LIGHT.md).
