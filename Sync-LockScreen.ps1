# Background watcher: whenever the desktop wallpaper changes (by any means),
# applies the same image to the lock screen. Started at logon by Install.ps1.

param([int]$IntervalSeconds = 2)

. "$PSScriptRoot\WallLib.ps1"

$mutex = [Threading.Mutex]::new($false, 'Local\WallSyncWatcher')
if (-not $mutex.WaitOne(0)) { exit }  # already running

$stateDir = Join-Path $env:LOCALAPPDATA 'WallSync'
$logFile = Join-Path $stateDir 'sync.log'
$transcoded = Join-Path $env:APPDATA 'Microsoft\Windows\Themes\TranscodedWallpaper'
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

function Write-Log([string]$Message) {
    $line = '{0:yyyy-MM-dd HH:mm:ss}  {1}' -f (Get-Date), $Message
    Add-Content -LiteralPath $logFile -Value $line -Encoding UTF8
}

# Wallpaper path in registry + timestamp of Windows' cached copy. Slideshows and
# apps that reuse the same path only change the cached copy, so watch both.
function Get-WallpaperSignature {
    $reg = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallPaper -ErrorAction SilentlyContinue).WallPaper
    $stamp = if (Test-Path -LiteralPath $transcoded) { (Get-Item -LiteralPath $transcoded).LastWriteTimeUtc.Ticks } else { 0 }
    [pscustomobject]@{ Path = $reg; Key = "$reg|$stamp" }
}

function Sync-Once($Signature) {
    # Prefer the original file (full quality); fall back to Windows' cached copy.
    $source = $Signature.Path
    if ($source -and (Test-Path -LiteralPath $source -PathType Leaf)) {
        try { Set-LockScreenImage $source; Write-Log "synced: $source"; return } catch {
            Write-Log "original failed ($($_.Exception.Message)), using cached copy"
        }
    }
    if (-not (Test-Path -LiteralPath $transcoded)) { Write-Log 'no wallpaper to sync'; return }

    # Fresh name each time so the lock screen never treats it as the same file.
    Get-ChildItem -LiteralPath $stateDir -Filter 'lockscreen-*.jpg' | Remove-Item -Force -ErrorAction SilentlyContinue
    $copy = Join-Path $stateDir ("lockscreen-{0}.jpg" -f [DateTime]::UtcNow.Ticks)
    Copy-Item -LiteralPath $transcoded -Destination $copy -Force
    Set-LockScreenImage $copy
    Write-Log "synced: cached copy of $source"
}

$last = $null
while ($true) {
    try {
        $sig = Get-WallpaperSignature
        if ($sig.Key -ne $last) {
            Start-Sleep -Seconds 1  # let Windows finish writing the cached copy
            $sig = Get-WallpaperSignature
            Sync-Once $sig
            $last = $sig.Key
        }
    } catch {
        Write-Log "error: $($_.Exception.Message)"
        $last = $sig.Key  # don't retry the same failing wallpaper every tick
    }
    Start-Sleep -Seconds $IntervalSeconds
}
