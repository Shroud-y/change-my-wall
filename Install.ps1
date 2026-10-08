# Installs (or with -Uninstall removes) "Set as desktop + lock screen" in the
# right-click menu of image files, for the current user, no admin needed.
# The menu runs Set-Wallpaper.ps1 from this folder, so re-run Install.ps1 if you move it.

param([switch]$Uninstall)

$menuKey = 'HKCU:\Software\Classes\SystemFileAssociations\image\shell\WallSync'
$ps = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$conhost = "$env:SystemRoot\System32\conhost.exe"  # --headless: no console window flash

# Cleanup for earlier versions, which also ran a background lock screen sync watcher.
Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
    Where-Object { $_.CommandLine -like '*Sync-LockScreen.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Remove-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'WallSync' -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $env:LOCALAPPDATA 'WallSync') -Recurse -Force -ErrorAction SilentlyContinue

if ($Uninstall) {
    Remove-Item -LiteralPath $menuKey -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host 'Removed context menu.'
    return
}

$setScript = Join-Path $PSScriptRoot 'Set-Wallpaper.ps1'

New-Item -Path $menuKey -Force | Out-Null
Set-ItemProperty -LiteralPath $menuKey -Name 'MUIVerb' -Value 'Set as desktop + lock screen'
Set-ItemProperty -LiteralPath $menuKey -Name 'Icon' -Value 'imageres.dll,-5346'
# One image only: with several selected, Explorer would start one script per file and they would race.
Set-ItemProperty -LiteralPath $menuKey -Name 'MultiSelectModel' -Value 'Single'
New-Item -Path "$menuKey\command" -Force | Out-Null
Set-ItemProperty -LiteralPath "$menuKey\command" -Name '(default)' `
    -Value "`"$conhost`" --headless `"$ps`" -NoProfile -ExecutionPolicy Bypass -File `"$setScript`" -Gui `"%1`""

Write-Host 'Installed. Right-click an image -> Show more options -> "Set as desktop + lock screen".'
