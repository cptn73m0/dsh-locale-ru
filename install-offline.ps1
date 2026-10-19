# Установка русской локализации DeepSeek Harness (Windows).
#
# Скрипт копирует пакет в %USERPROFILE%\.dsh\locale-packs\ru и подключает его
# к профилю Desktop без Node.js и без сети — используется установщиком .exe
# и ручной установкой из архива.

param(
    [string]$ProfileDir = $env:DSH_PROFILE_DIR,
    [string]$PackDir = $PSScriptRoot,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

if (-not $ProfileDir) {
    $ProfileDir = Join-Path $env:USERPROFILE '.dsh\profiles\desktop'
}
if (-not (Test-Path $ProfileDir)) {
    throw "Не найден профиль Desktop: $ProfileDir. Запустите DeepSeek Harness один раз и повторите установку."
}

$pack = (Resolve-Path $PackDir).Path
$clientBundle = Join-Path $pack 'lib\client.js'
if (-not (Test-Path $clientBundle)) {
    throw "В папке пакета нет lib\client.js: $pack"
}

$manifestPath = Join-Path $ProfileDir 'package.json'
$patchPath = Join-Path $ProfileDir 'cordis.patch.yml'
if (-not (Test-Path $manifestPath)) {
    throw "Не найден package.json профиля: $manifestPath"
}

$target = Join-Path $ProfileDir 'node_modules\dsh-locale-ru'
if (Test-Path $target) { Remove-Item $target -Recurse -Force }
New-Item -ItemType Directory -Force -Path $target | Out-Null
foreach ($item in @('package.json', 'README.md')) {
    $src = Join-Path $pack $item
    if (Test-Path $src) { Copy-Item $src (Join-Path $target $item) -Force }
}
foreach ($item in @('lib', 'locale')) {
    $src = Join-Path $pack $item
    if (Test-Path $src) { Copy-Item $src (Join-Path $target $item) -Recurse -Force }
}

if (-not $Quiet) { Write-Host 'Пакет скопирован в профиль.' -ForegroundColor Cyan }

# --- package.json: зависимость + убрать из списка бандлов -------------------
Copy-Item $manifestPath "$manifestPath.bak-locale-ru" -Force
$pkg = Get-Content $manifestPath -Raw | ConvertFrom-Json
if ($null -eq $pkg.dependencies) {
    $pkg | Add-Member -MemberType NoteProperty -Name dependencies -Value ([pscustomobject]@{}) -Force
}
$spec = 'file:' + ($pack -replace '\\', '/')
$pkg.dependencies | Add-Member -MemberType NoteProperty -Name 'dsh-locale-ru' -Value $spec -Force
$bundles = @(@($pkg.dsh.profile.bundles) | Where-Object { $_ -ne 'dsh-locale-ru' })
$pkg.dsh.profile.bundles = $bundles
$json = $pkg | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding($false)))

# --- cordis.patch.yml: строка insert с плагином -----------------------------
$patch = Get-Content $patchPath -Raw
$original = $patch
# Строка вида "- id: locale-ru" была бы прочитана как правка конфига, а не вставка.
$patch = [regex]::Replace($patch, "(?ms)^- id: locale-ru\r?\n(?:[ \t]+.*\r?\n)*", "")
# Пустой слой записывается как [], иначе YAML-массив уже закрыт.
$patch = [regex]::Replace($patch, "(?m)^\s*\[\]\s*\r?\n?", "")
if ($patch -notmatch '(?m)^\s*name:\s*dsh-locale-ru\s*$') {
    $insert = "- insert:`r`n    - id: locale-ru`r`n      name: dsh-locale-ru`r`n"
    if ($patch.Trim() -eq '') { $patch = $insert }
    else { $patch = $patch.TrimEnd() + "`r`n" + $insert }
}
if ($patch -ne $original) {
    Copy-Item $patchPath "$patchPath.bak-locale-ru" -Force
    [System.IO.File]::WriteAllText($patchPath, $patch, (New-Object System.Text.UTF8Encoding($false)))
}

if (-not $Quiet) {
    Write-Host ''
    Write-Host 'Готово. Русский язык включён.' -ForegroundColor Green
    Write-Host 'Перезапустите DeepSeek Harness, чтобы интерфейс стал русским.' -ForegroundColor Yellow
    Write-Host 'Переключить язык вручную: Настройки -> Общие -> Язык -> Русский.'
}
