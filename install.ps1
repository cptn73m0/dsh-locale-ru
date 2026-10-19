# Ручная установка русской локализации DeepSeek Harness.
#
# Запуск из распакованного архива:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1

param(
    [string]$ProfileDir = $env:DSH_PROFILE_DIR
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $ProfileDir) {
    $ProfileDir = Join-Path $env:USERPROFILE '.dsh\profiles\desktop'
}

$packDir = Join-Path (Join-Path $env:USERPROFILE '.dsh') 'locale-packs\ru'

Write-Host 'Копирую языковой пакет...' -ForegroundColor Cyan
if (Test-Path $packDir) { Remove-Item $packDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $packDir | Out-Null
foreach ($item in @('package.json', 'README.md', 'install-offline.ps1', 'uninstall-offline.ps1')) {
    $src = Join-Path $here $item
    if (Test-Path $src) { Copy-Item $src (Join-Path $packDir $item) -Force }
}
foreach ($item in @('lib', 'locale')) {
    $src = Join-Path $here $item
    if (Test-Path $src) { Copy-Item $src (Join-Path $packDir $item) -Recurse -Force }
}

& (Join-Path $packDir 'install-offline.ps1') -ProfileDir $ProfileDir -PackDir $packDir
