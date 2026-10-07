# Installs (or with -Uninstall removes) for the current user, no admin needed:
#  1. "Set as desktop + lock screen" in the right-click menu of image files
#  2. Sync-LockScreen.ps1 watcher, started at logon and right now
# Scripts run from this folder, so re-run Install.ps1 if you move it.

param([switch]$Uninstall)

$menuKey = 'HKCU:\Software\Classes\SystemFileAssociations\image\shell\WallSync'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runName = 'WallSync'
$ps = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$conhost = "$env:SystemRoot\System32\conhost.exe"  # --headless: no console window flash

function Stop-Watcher {
    Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
        Where-Object { $_.CommandLine -like '*Sync-LockScreen.ps1*' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

Stop-Watcher

if ($Uninstall) {
    Remove-Item -LiteralPath $menuKey -Recurse -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -LiteralPath $runKey -Name $runName -ErrorAction SilentlyContinue
    Write-Host 'Removed context menu and watcher.'
    return
}

$setScript = Join-Path $PSScriptRoot 'Set-Wallpaper.ps1'
$syncScript = Join-Path $PSScriptRoot 'Sync-LockScreen.ps1'

New-Item -Path $menuKey -Force | Out-Null
Set-ItemProperty -LiteralPath $menuKey -Name 'MUIVerb' -Value 'Set as desktop + lock screen'
Set-ItemProperty -LiteralPath $menuKey -Name 'Icon' -Value 'imageres.dll,-5346'
New-Item -Path "$menuKey\command" -Force | Out-Null
Set-ItemProperty -LiteralPath "$menuKey\command" -Name '(default)' `
    -Value "`"$conhost`" --headless `"$ps`" -NoProfile -ExecutionPolicy Bypass -File `"$setScript`" -Gui `"%1`""

$syncArgs = "--headless `"$ps`" -NoProfile -ExecutionPolicy Bypass -File `"$syncScript`""
Set-ItemProperty -LiteralPath $runKey -Name $runName -Value "`"$conhost`" $syncArgs"
Start-Process -FilePath $conhost -ArgumentList $syncArgs

Write-Host 'Installed. Right-click an image -> Show more options -> "Set as desktop + lock screen".'
Write-Host "Watcher running; log: $env:LOCALAPPDATA\WallSync\sync.log"
