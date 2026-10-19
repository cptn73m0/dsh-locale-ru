# Удаление русской локализации DeepSeek Harness.
#
# Запуск:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1

param(
    [string]$ProfileDir = $env:DSH_PROFILE_DIR
)

$ErrorActionPreference = 'Stop'

if (-not $ProfileDir) {
    $ProfileDir = Join-Path $env:USERPROFILE '.dsh\profiles\desktop'
}

$packDir = Join-Path (Join-Path $env:USERPROFILE '.dsh') 'locale-packs\ru'
$offline = Join-Path $packDir 'uninstall-offline.ps1'

if (Test-Path $offline) {
    & $offline -ProfileDir $ProfileDir
} else {
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    & (Join-Path $here 'uninstall-offline.ps1') -ProfileDir $ProfileDir
}

if (Test-Path $packDir) { Remove-Item $packDir -Recurse -Force }
Write-Host 'Готово. Перезапустите DeepSeek Harness.' -ForegroundColor Green
