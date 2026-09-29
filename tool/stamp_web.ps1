$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$webRoot = Join-Path $projectRoot 'build\web'
$mainPath = Join-Path $webRoot 'main.dart.js'
$bootstrapPath = Join-Path $webRoot 'flutter_bootstrap.js'
$indexPath = Join-Path $webRoot 'index.html'
$mainHash = (Get-FileHash -LiteralPath $mainPath -Algorithm SHA256).Hash.Substring(0, 16).ToLowerInvariant()
$bootstrap = Get-Content -LiteralPath $bootstrapPath -Raw
$pattern = '"mainJsPath"\s*:\s*"main\.dart\.js(?:\?v=[a-z0-9]+)?"'
if (-not [regex]::IsMatch($bootstrap, $pattern)) { throw 'Flutter bootstrap format changed; inspect entrypoint before stamping.' }
$bootstrap = [regex]::Replace($bootstrap, $pattern, '"mainJsPath":"main.dart.js?v=' + $mainHash + '"')
[IO.File]::WriteAllText($bootstrapPath, $bootstrap, [Text.UTF8Encoding]::new($false))
$bootstrapHash = (Get-FileHash -LiteralPath $bootstrapPath -Algorithm SHA256).Hash.Substring(0, 16).ToLowerInvariant()
$index = Get-Content -LiteralPath $indexPath -Raw
$scriptPattern = 'src="flutter_bootstrap\.js(?:\?v=[a-z0-9]+)?"'
if (-not [regex]::IsMatch($index, $scriptPattern)) { throw 'Flutter index entrypoint missing.' }
$index = [regex]::Replace($index, $scriptPattern, 'src="flutter_bootstrap.js?v=' + $bootstrapHash + '"')
[IO.File]::WriteAllText($indexPath, $index, [Text.UTF8Encoding]::new($false))
Write-Output "Web entrypoint stamped: $mainHash"
