param(
    [Parameter(Mandatory = $true)][string]$ApkPath,
    [string]$AdbPath = 'adb',
    [string]$Serial = 'emulator-5554'
)
$ErrorActionPreference = 'Stop'
# Release-only Android startup failures are invisible to Flutter widget tests.
# Use a disposable emulator: this installs the APK and clears its log buffers.
if ($Serial -notmatch '^emulator-\d+$') {
    throw 'This smoke check is restricted to an emulator, not a personal phone.'
}
$package = 'com.loopgames.pothole_panic'
function Invoke-Adb {
    $result = & $AdbPath -s $Serial @args 2>&1
    if ($LASTEXITCODE -ne 0) { throw ($result -join "`n") }
    return $result
}
Invoke-Adb install -r (Resolve-Path -LiteralPath $ApkPath).Path
for ($attempt = 1; $attempt -le 3; $attempt++) {
    Invoke-Adb shell am force-stop $package
    Invoke-Adb logcat -c
    Invoke-Adb shell am start -n "$package/.MainActivity"
    Start-Sleep -Seconds 10
    $crash = (Invoke-Adb logcat -b crash -d) -join "`n"
    if ($crash -match [regex]::Escape($package)) { throw $crash }
    $appPid = (Invoke-Adb shell pidof $package) -join ''
    if ([string]::IsNullOrWhiteSpace($appPid)) { throw 'App exited after launch.' }
    $activities = (Invoke-Adb shell dumpsys activity activities) -join "`n"
    if ($activities -notmatch "(?:mResumedActivity:|topResumedActivity=|ResumedActivity:).*$([regex]::Escape($package))") {
        throw 'The game did not remain the foreground activity.'
    }
    Write-Output "Cold launch $attempt passed (PID $appPid)."
}
Write-Output 'Release startup smoke check passed. Gameplay and physical-device checks are still required.'
