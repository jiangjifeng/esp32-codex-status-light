param(
    [ValidateSet("idle", "thinking", "tool", "editing", "git", "done", "running", "marquee", "chase", "permission", "limited", "error", "off", "test", "help")]
    [string]$Status = "idle",

    [string]$Port = "COM6",

    [int]$BaudRate = 115200
)

$serial = [System.IO.Ports.SerialPort]::new($Port, $BaudRate, "None", 8, "One")
$serial.NewLine = "`n"
$serial.DtrEnable = $false
$serial.RtsEnable = $false

try {
    $serial.Open()
    Start-Sleep -Milliseconds 150
    $serial.WriteLine($Status)
    Write-Host "Sent '$Status' to $Port"
}
finally {
    if ($serial.IsOpen) {
        $serial.Close()
    }
    $serial.Dispose()
}
