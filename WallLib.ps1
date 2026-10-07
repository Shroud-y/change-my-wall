# Shared helpers: set the desktop wallpaper and the lock screen image.
# Requires Windows PowerShell 5.1 (powershell.exe) - pwsh 7 has no WinRT projection.

if ($PSVersionTable.PSEdition -eq 'Core') {
    throw 'Run this with Windows PowerShell 5.1 (powershell.exe), not pwsh.'
}

Add-Type -AssemblyName System.Runtime.WindowsRuntime

if (-not ('WallNative' -as [type])) {
    Add-Type @'
using System.Runtime.InteropServices;
public static class WallNative {
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, string pvParam, uint fWinIni);
}
'@
}

$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime]

$script:AsTaskOperation = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
    $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
} | Select-Object -First 1

$script:AsTaskAction = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
    $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction'
} | Select-Object -First 1

# Blocks on a WinRT async call. Pass ResultType for IAsyncOperation<T>, omit it for IAsyncAction.
function Wait-WinRT($Operation, [type]$ResultType) {
    if ($ResultType) {
        $task = $script:AsTaskOperation.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
    } else {
        $task = $script:AsTaskAction.Invoke($null, @($Operation))
    }
    try { $task.Wait() | Out-Null } catch { throw $_.Exception.InnerException.InnerException }
    if ($ResultType) { $task.Result }
}

function Set-DesktopWallpaper([string]$Path) {
    # SPI_SETDESKWALLPAPER = 0x14; SPIF_UPDATEINIFILE | SPIF_SENDWININICHANGE = 0x3
    if (-not [WallNative]::SystemParametersInfo(0x14, 0, $Path, 0x3)) {
        $code = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        throw "SystemParametersInfo failed: $([ComponentModel.Win32Exception]::new($code).Message)"
    }
}

function Set-LockScreenImage([string]$Path) {
    $file = Wait-WinRT ([Windows.Storage.StorageFile]::GetFileFromPathAsync($Path)) ([Windows.Storage.StorageFile])
    Wait-WinRT ([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($file))
}
