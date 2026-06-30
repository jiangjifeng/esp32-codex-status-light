param(
    [ValidateSet("idle", "done", "running", "permission", "error", "off")]
    [string]$Status = "idle",

    [string]$SenderScript = (Join-Path (Split-Path $PSScriptRoot -Parent) "codex_status_light.ps1"),

    [string]$Port = "COM6",

    [int]$BaudRate = 115200
)

$ErrorActionPreference = "SilentlyContinue"

if (-not (Test-Path -LiteralPath $SenderScript)) {
    exit 0
}

& $SenderScript $Status -Port $Port -BaudRate $BaudRate | Out-Null
exit 0
