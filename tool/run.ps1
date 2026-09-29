param(
    [ValidateSet('web', 'android', 'test', 'dry-run', 'check', 'build-web', 'apk')]
    [string]$Target = 'web'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$localTools = Join-Path (Split-Path -Parent $projectRoot) '.tooling'
$localFlutter = Join-Path $localTools 'flutter'
if (Test-Path -LiteralPath (Join-Path $localFlutter 'bin\flutter.bat')) {
    # Flutter's native hook runner on Windows needs a path without spaces.
    $fileSystem = New-Object -ComObject Scripting.FileSystemObject
    $flutterSdkPath = $fileSystem.GetFolder($localFlutter).ShortPath
    $flutterCommand = Join-Path $flutterSdkPath 'bin\flutter.bat'
} else {
    $flutterCommand = (Get-Command flutter -ErrorAction Stop).Source
}
$androidSdk = Join-Path $localTools 'android-sdk'
if (Test-Path -LiteralPath $androidSdk) { $env:ANDROID_HOME = $androidSdk }
$gradleCache = Join-Path $localTools 'gradle-home'
if (Test-Path -LiteralPath $gradleCache) { $env:GRADLE_USER_HOME = $gradleCache }
$javaFolder = Get-ChildItem -LiteralPath (Join-Path $localTools 'jdk17') -Directory -ErrorAction SilentlyContinue |
    Select-Object -First 1
if ($javaFolder) { $env:JAVA_HOME = $javaFolder.FullName }
switch ($Target) {
    'web' { & $flutterCommand run -d chrome }
    'android' { & $flutterCommand run }
    'test' { & $flutterCommand test }
    'dry-run' { & $flutterCommand test --dart-define=CAPTURE_DRY_RUN=true }
    'check' { & $flutterCommand analyze }
    'build-web' {
        & $flutterCommand build web --release --no-web-resources-cdn
        $webBuildExit = $LASTEXITCODE
        if ($webBuildExit -eq 0) { & (Join-Path $PSScriptRoot 'stamp_web.ps1') }
        exit $webBuildExit
    }
    'apk' { & $flutterCommand build apk --release }
}
exit $LASTEXITCODE
