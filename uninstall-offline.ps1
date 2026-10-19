# Удаление русской локализации DeepSeek Harness.
#
# Используется установщиком .exe и ручным uninstall.ps1.

param(
    [string]$ProfileDir = $env:DSH_PROFILE_DIR,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

if (-not $ProfileDir) {
    $ProfileDir = Join-Path $env:USERPROFILE '.dsh\profiles\desktop'
}
if (-not (Test-Path $ProfileDir)) {
    if (-not $Quiet) { Write-Host 'Профиль Desktop не найден — удалять нечего.' -ForegroundColor Yellow }
    exit 0
}

$manifestPath = Join-Path $ProfileDir 'package.json'
$patchPath = Join-Path $ProfileDir 'cordis.patch.yml'

if (Test-Path $manifestPath) {
    $pkg = Get-Content $manifestPath -Raw | ConvertFrom-Json
    if ($null -ne $pkg.dependencies) {
        $pkg.dependencies.PSObject.Properties.Remove('dsh-locale-ru')
    }
    $bundles = @(@($pkg.dsh.profile.bundles) | Where-Object { $_ -ne 'dsh-locale-ru' })
    $pkg.dsh.profile.bundles = $bundles
    $json = $pkg | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding($false)))
}

if (Test-Path $patchPath) {
    $patch = Get-Content $patchPath -Raw
    $patch = [regex]::Replace($patch, "(?ms)^- id: locale-ru\r?\n(?:[ \t]+.*\r?\n)*", "")
    $patch = [regex]::Replace($patch, "(?ms)^- insert:\r?\n    - id: locale-ru\r?\n      name: dsh-locale-ru\r?\n?", "")
    # Пустой или состоящий только из комментариев patch-файл ломает загрузку.
    $entries = @($patch -split "`r?`n" | Where-Object {
        $line = $_.Trim()
        $line -ne '' -and -not $line.StartsWith('#')
    })
    if ($entries.Count -eq 0) { $patch = "[]`r`n" }
    else { $patch = $patch.TrimEnd() + "`r`n" }
    [System.IO.File]::WriteAllText($patchPath, $patch, (New-Object System.Text.UTF8Encoding($false)))
}

$target = Join-Path $ProfileDir 'node_modules\dsh-locale-ru'
if (Test-Path $target) { Remove-Item $target -Recurse -Force }

if (-not $Quiet) {
    Write-Host 'Локализация удалена. Перезапустите DeepSeek Harness.' -ForegroundColor Green
}
