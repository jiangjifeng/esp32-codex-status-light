param(
    [ValidateSet("idle", "thinking", "tool", "git", "done", "running", "permission", "limited", "error", "off", "after_tool", "stop")]
    [string]$Status = "idle",

    [string]$SenderScript = (Join-Path (Split-Path $PSScriptRoot -Parent) "codex_status_light.ps1"),

    [string]$Port = "COM6",

    [int]$BaudRate = 115200,

    [string]$CodexHome = (Join-Path $env:USERPROFILE ".codex"),

    [string]$LogPath = (Join-Path $env:TEMP "codex_status_light_hook.log")
)

$ErrorActionPreference = "SilentlyContinue"

function Write-HookLog {
    param(
        [string]$Message
    )

    if (-not $LogPath) {
        return
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $LogPath -Value "[$timestamp] $Message"
}

function Get-LatestGoalStatus {
    $dbPath = Join-Path $CodexHome "goals_1.sqlite"

    if (-not (Test-Path -LiteralPath $dbPath)) {
        return "none"
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        return "unknown"
    }

    $env:CODEX_STATUS_LIGHT_GOALS_DB = $dbPath
    $code = @'
import os
import sqlite3

path = os.environ.get('CODEX_STATUS_LIGHT_GOALS_DB')

try:
    con = sqlite3.connect('file:' + path + '?mode=ro', uri=True, timeout=0.2)
    row = con.execute(
        'select status from thread_goals order by updated_at_ms desc limit 1'
    ).fetchone()
    con.close()
    print(row[0] if row else 'none')
except Exception:
    print('unknown')
'@

    $result = & $python.Source -c $code
    $firstLine = $result | Select-Object -First 1

    if ($firstLine) {
        return $firstLine.Trim()
    }

    return "unknown"
}

function Read-HookInput {
    if (-not [Console]::IsInputRedirected) {
        return ""
    }

    return [Console]::In.ReadToEnd()
}

function Resolve-ToolStatus {
    param(
        [string]$RawInput
    )

    if (-not $RawInput) {
        return "tool"
    }

    if ($RawInput -match "(?i)(^|[\s`"'])git\s+(status|add|commit|push|pull|fetch|merge|rebase|checkout|switch|branch|tag|diff|show|log|restore|reset|remote|clone|mv)\b" -or
        $RawInput -match "(?i)(^|[\s`"'])gh\s+(pr|repo|issue|auth|run|workflow)\b") {
        return "git"
    }

    return "tool"
}

if (-not (Test-Path -LiteralPath $SenderScript)) {
    Write-HookLog "sender missing: $SenderScript"
    exit 0
}

$targetStatus = $Status

if ($Status -eq "tool") {
    $hookInput = Read-HookInput
    $targetStatus = Resolve-ToolStatus -RawInput $hookInput
    Write-HookLog "tool event: target_status=$targetStatus input_length=$($hookInput.Length)"
} elseif ($Status -eq "after_tool") {
    $goalStatus = Get-LatestGoalStatus

    switch ($goalStatus) {
        "active" { $targetStatus = "running" }
        "blocked" { $targetStatus = "error" }
        "budget_limited" { $targetStatus = "limited" }
        "usage_limited" { $targetStatus = "limited" }
        "paused" { $targetStatus = "idle" }
        default { $targetStatus = "thinking" }
    }

    Write-HookLog "after_tool event: latest_goal_status=$goalStatus target_status=$targetStatus"
} elseif ($Status -eq "stop") {
    $goalStatus = Get-LatestGoalStatus

    switch ($goalStatus) {
        "active" { $targetStatus = "running" }
        "blocked" { $targetStatus = "error" }
        "budget_limited" { $targetStatus = "limited" }
        "usage_limited" { $targetStatus = "limited" }
        "paused" { $targetStatus = "idle" }
        default { $targetStatus = "done" }
    }

    Write-HookLog "stop event: latest_goal_status=$goalStatus target_status=$targetStatus"
} else {
    Write-HookLog "event status=$Status target_status=$targetStatus"
}

& $SenderScript $targetStatus -Port $Port -BaudRate $BaudRate | Out-Null
exit 0
