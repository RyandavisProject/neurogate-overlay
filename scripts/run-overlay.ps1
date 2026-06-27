$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$VenvPython = Join-Path $Root ".venv\Scripts\python.exe"
$StateDir = Join-Path $env:USERPROFILE ".neurogate-usage-overlay"
$ProfilePath = Join-Path $env:USERPROFILE ".neurogate-usage-overlay\browser-profile"
$PidPath = Join-Path $StateDir "overlay.pid"
$EscapedRoot = [regex]::Escape($Root)
$EscapedProfilePath = [regex]::Escape($ProfilePath)

function Stop-OverlayProcess($Process) {
    if (-not $Process) {
        return
    }
    Stop-Process -Id $Process.ProcessId -Force -ErrorAction SilentlyContinue
}

function Test-OverlayPythonProcess($Process) {
    if (-not $Process -or $Process.Name -notin @('python.exe', 'pythonw.exe', 'py.exe')) {
        return $false
    }
    $CommandLine = $Process.CommandLine
    if (-not $CommandLine) {
        return $false
    }
    if ($CommandLine -match '(^|\s)-m\s+neurogate_usage_overlay(\s|$)') {
        return $true
    }
    if (
        $CommandLine -match $EscapedRoot -and
        $CommandLine -match '(^|\s|\\)(vibemode|vibemod|neurogate-api|vibemode-overlay|neurogate-usage-overlay)(\.exe)?(\s|$)'
    ) {
        return $true
    }
    return $false
}

function Stop-OverlayFromPidFile {
    if (-not (Test-Path $PidPath)) {
        return
    }
    $RawPid = (Get-Content -LiteralPath $PidPath -Raw).Trim()
    $ParsedPid = 0
    if (-not [int]::TryParse($RawPid, [ref]$ParsedPid)) {
        Remove-Item -LiteralPath $PidPath -Force -ErrorAction SilentlyContinue
        return
    }
    $Existing = Get-CimInstance Win32_Process -Filter "ProcessId = $ParsedPid" -ErrorAction SilentlyContinue
    if (Test-OverlayPythonProcess $Existing) {
        Stop-OverlayProcess $Existing
        Start-Sleep -Milliseconds 500
    }
    Remove-Item -LiteralPath $PidPath -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path $VenvPython)) {
    Write-Host "Virtual environment not found. Installing first..."
    & (Join-Path $Root "scripts\install.ps1")
}

Stop-OverlayFromPidFile

# Keep one overlay instance. Multiple instances fight for the same Chrome
# profile and can show empty values. This fallback handles old public builds
# that did not yet write overlay.pid.
Get-CimInstance Win32_Process |
    Where-Object {
        $CommandLine = $_.CommandLine
        if (-not $CommandLine) {
            return $false
        }
        (
            (Test-OverlayPythonProcess $_) -or
            ($_.Name -eq 'node.exe' -and $CommandLine -match $EscapedRoot) -or
            ($_.Name -eq 'chrome.exe' -and $CommandLine -match $EscapedProfilePath)
        )
    } |
    ForEach-Object {
        Stop-OverlayProcess $_
    }

& $VenvPython -m neurogate_usage_overlay --interval 60
