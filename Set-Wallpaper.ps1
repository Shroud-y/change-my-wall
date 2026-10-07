# Sets one image as both the desktop wallpaper and the lock screen.
# Usage: powershell -ExecutionPolicy Bypass -File Set-Wallpaper.ps1 "C:\pics\cat.jpg"
# -Gui shows errors in a message box (used by the context menu, which has no console).

param(
    [Parameter(Mandatory)][string]$Path,
    [switch]$Gui
)

try {
    . "$PSScriptRoot\WallLib.ps1"
    $full = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
    Set-DesktopWallpaper $full
    Set-LockScreenImage $full
} catch {
    if (-not $Gui) { throw }
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show("$Path`n`n$($_.Exception.Message)", 'Set-Wallpaper', 'OK', 'Error')
    exit 1
}
