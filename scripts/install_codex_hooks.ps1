param(
    [string]$Port = "COM6",

    [int]$BaudRate = 115200,

    [string]$CodexHome = (Join-Path $env:USERPROFILE ".codex")
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$hookScript = Join-Path $repoRoot "hooks\codex_status_light_hook.ps1"
$senderScript = Join-Path $repoRoot "codex_status_light.ps1"
$hooksJson = Join-Path $CodexHome "hooks.json"

if (-not (Test-Path -LiteralPath $hookScript)) {
    throw "Missing hook script: $hookScript"
}

if (-not (Test-Path -LiteralPath $senderScript)) {
    throw "Missing sender script: $senderScript"
}

New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null

if (Test-Path -LiteralPath $hooksJson) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item -LiteralPath $hooksJson -Destination "$hooksJson.bak-$timestamp" -Force
    $config = Get-Content -Raw -LiteralPath $hooksJson | ConvertFrom-Json
} else {
    $config = [pscustomobject]@{}
}

if (-not $config.PSObject.Properties["hooks"]) {
    $config | Add-Member -MemberType NoteProperty -Name hooks -Value ([pscustomobject]@{})
}

function New-StatusLightCommand {
    param(
        [string]$Status
    )

    $escapedHookScript = $hookScript.Replace('"', '\"')
    $escapedSenderScript = $senderScript.Replace('"', '\"')

    return "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$escapedHookScript`" $Status -SenderScript `"$escapedSenderScript`" -Port $Port -BaudRate $BaudRate"
}

function New-StatusLightHook {
    param(
        [string]$Status
    )

    $command = New-StatusLightCommand -Status $Status

    return [pscustomobject]@{
        type = "command"
        command = $command
        commandWindows = $command
        timeout = 5
        statusMessage = "Setting Codex status light to $Status"
    }
}

function Set-CodexEventHook {
    param(
        [string]$EventName,
        [string]$Status,
        [string]$Matcher = $null
    )

    $entry = [pscustomobject]@{
        hooks = @((New-StatusLightHook -Status $Status))
    }

    if ($Matcher) {
        $entry | Add-Member -MemberType NoteProperty -Name matcher -Value $Matcher
    }

    $existingEntries = @()
    if ($config.hooks.PSObject.Properties[$EventName]) {
        $existingEntries = @($config.hooks.$EventName)
    }

    $keptEntries = @(
        $existingEntries | Where-Object {
            $serialized = $_ | ConvertTo-Json -Depth 20 -Compress
            $serialized -notmatch "codex_status_light_hook\.ps1" -and
                $serialized -notmatch "Setting Codex status light"
        }
    )

    $newEntries = @($keptEntries) + @($entry)

    if ($config.hooks.PSObject.Properties[$EventName]) {
        $config.hooks.$EventName = $newEntries
    } else {
        $config.hooks | Add-Member -MemberType NoteProperty -Name $EventName -Value $newEntries
    }
}

Set-CodexEventHook -EventName "SessionStart" -Status "idle" -Matcher "startup|resume|clear"
Set-CodexEventHook -EventName "UserPromptSubmit" -Status "running"
Set-CodexEventHook -EventName "PermissionRequest" -Status "permission" -Matcher ".*"
Set-CodexEventHook -EventName "Stop" -Status "done"

$config | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $hooksJson -Encoding UTF8

Write-Host "Installed Codex status light hooks:"
Write-Host "  $hooksJson"
Write-Host "Using sender:"
Write-Host "  $senderScript"
Write-Host "Port: $Port"
