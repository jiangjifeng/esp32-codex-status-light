param(
    [string]$Python = "python"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$hookScript = Join-Path $repoRoot "hooks\codex_status_light_hook.ps1"

if (-not (Test-Path -LiteralPath $hookScript)) {
    throw "Missing hook script: $hookScript"
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex_status_light_hook_test_" + [guid]::NewGuid().ToString("N"))
$fakeCodexHome = Join-Path $tempRoot ".codex"
$fakeSender = Join-Path $tempRoot "fake_sender.ps1"
$sentFile = Join-Path $tempRoot "sent_status.txt"
$logFile = Join-Path $tempRoot "hook.log"

New-Item -ItemType Directory -Force -Path $fakeCodexHome | Out-Null

@'
param(
    [string]$Status,
    [string]$Port,
    [int]$BaudRate
)

Add-Content -LiteralPath $env:CODEX_STATUS_LIGHT_TEST_SENT -Value $Status
'@ | Set-Content -LiteralPath $fakeSender -Encoding UTF8

function Clear-SentStatus {
    if (Test-Path -LiteralPath $sentFile) {
        Remove-Item -LiteralPath $sentFile -Force
    }
}

function Get-SentStatus {
    if (-not (Test-Path -LiteralPath $sentFile)) {
        return ""
    }

    return (Get-Content -LiteralPath $sentFile | Select-Object -Last 1).Trim()
}

function Set-GoalStatus {
    param(
        [string]$Status
    )

    $dbPath = Join-Path $fakeCodexHome "goals_1.sqlite"
    $env:CODEX_STATUS_LIGHT_TEST_DB = $dbPath
    $env:CODEX_STATUS_LIGHT_TEST_GOAL = $Status

    & $Python -c @'
import os
import sqlite3
import time

path = os.environ["CODEX_STATUS_LIGHT_TEST_DB"]
status = os.environ["CODEX_STATUS_LIGHT_TEST_GOAL"]

con = sqlite3.connect(path)
con.execute("drop table if exists thread_goals")
con.execute("create table thread_goals (status text, updated_at_ms integer)")
con.execute(
    "insert into thread_goals(status, updated_at_ms) values (?, ?)",
    (status, int(time.time() * 1000)),
)
con.commit()
con.close()
'@
}

function Invoke-Hook {
    param(
        [string]$Status,
        [string]$InputText = ""
    )

    Clear-SentStatus
    $env:CODEX_STATUS_LIGHT_TEST_SENT = $sentFile

    $args = @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $hookScript,
        $Status,
        "-SenderScript",
        $fakeSender,
        "-Port",
        "TEST",
        "-CodexHome",
        $fakeCodexHome,
        "-LogPath",
        $logFile
    )

    if ($InputText) {
        $InputText | powershell.exe @args | Out-Null
    } else {
        powershell.exe @args | Out-Null
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Hook exited with code $LASTEXITCODE for status '$Status'"
    }

    Get-SentStatus
}

function Assert-Status {
    param(
        [string]$Name,
        [string]$Actual,
        [string]$Expected
    )

    if ($Actual -ne $Expected) {
        throw "$Name expected '$Expected', got '$Actual'"
    }

    Write-Host "PASS $Name -> $Actual"
}

try {
    Assert-Status "generic tool" (Invoke-Hook -Status "tool" -InputText '{"tool":"shell_command","command":"idf.py build"}') "tool"
    Assert-Status "apply patch stays tool" (Invoke-Hook -Status "tool" -InputText '{"tool":"apply_patch","command":"apply_patch"}') "tool"
    Assert-Status "git command" (Invoke-Hook -Status "tool" -InputText '{"command":"git push"}') "git"
    Assert-Status "gh command" (Invoke-Hook -Status "tool" -InputText '{"command":"gh pr view"}') "git"

    Set-GoalStatus "active"
    Assert-Status "after tool active goal" (Invoke-Hook -Status "after_tool") "running"
    Assert-Status "active goal" (Invoke-Hook -Status "stop") "running"

    Remove-Item -LiteralPath (Join-Path $fakeCodexHome "goals_1.sqlite") -Force
    Assert-Status "after tool no goal db" (Invoke-Hook -Status "after_tool") "thinking"

    Set-GoalStatus "usage_limited"
    Assert-Status "usage limited" (Invoke-Hook -Status "stop") "limited"

    Set-GoalStatus "blocked"
    Assert-Status "blocked goal" (Invoke-Hook -Status "stop") "error"

    Remove-Item -LiteralPath (Join-Path $fakeCodexHome "goals_1.sqlite") -Force
    Assert-Status "no goal db" (Invoke-Hook -Status "stop") "done"

    Write-Host "All hook tests passed."
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
