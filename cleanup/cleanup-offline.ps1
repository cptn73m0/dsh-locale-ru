# Удаление устаревшей русской локализации DeepSeek Harness (пакет 0.1.x).
#
# Начиная с DSH 0.2.2 русский язык входит в DeepSeek Harness официально:
# клиент регистрирует язык "ru" и словари для всех разделов интерфейса.
# Старый пакет 0.1.x в такой версии конфликтует с встроенным русским и не
# загружается (ошибка "dsh-locale-ru: failed" при загрузке web-клиента).
#
# Скрипт идемпотентен: его можно запускать повторно. Он:
#   1. запускает штатный деинсталлятор пакета, если тот установлен через .exe;
#   2. убирает зависимость и запись загрузчика из профиля DSH;
#   3. удаляет каталог языкового пакета.
#
# Используется средством очистки dsh-locale-ru-cleanup-*.exe.

param(
    [string]$ProfileDir = $env:DSH_PROFILE_DIR,
    [string]$PackDir = (Join-Path $env:USERPROFILE '.dsh\locale-packs\ru'),
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$problems = New-Object System.Collections.Generic.List[string]

function Write-Info([string]$Message) {
    if (-not $Quiet) { Write-Host $Message -ForegroundColor Cyan }
}
function Write-WarningLine([string]$Message) {
    if (-not $Quiet) { Write-Host $Message -ForegroundColor Yellow }
}

if (-not $ProfileDir) {
    $ProfileDir = Join-Path $env:USERPROFILE '.dsh\profiles\desktop'
}

Write-Info 'Удаляю устаревшую русскую локализацию DeepSeek Harness (пакет 0.1.x)...'

# --- 1. Штатный деинсталлятор старого пакета (установка через .exe) ----------
$uninstaller = Join-Path $PackDir 'unins000.exe'
if (Test-Path $uninstaller) {
    Write-Info "Запускаю деинсталлятор пакета: $uninstaller"
    try {
        $process = Start-Process -FilePath $uninstaller `
            -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' `
            -Wait -PassThru
        Write-Info "Деинсталлятор завершён с кодом $($process.ExitCode)."
    } catch {
        Write-WarningLine "Не удалось запустить деинсталлятор: $($_.Exception.Message)"
    }
}

# --- 2. Чистка профиля DSH ---------------------------------------------------
$manifestPath = Join-Path $ProfileDir 'package.json'
$patchPath = Join-Path $ProfileDir 'cordis.patch.yml'

if (Test-Path $manifestPath) {
    try {
        $pkg = Get-Content $manifestPath -Raw | ConvertFrom-Json
        $changed = $false
        if ($null -ne $pkg -and $null -ne $pkg.dependencies) {
            $dependency = @($pkg.dependencies.PSObject.Properties | Where-Object { $_.Name -eq 'dsh-locale-ru' })
            if ($dependency.Count -gt 0) {
                $pkg.dependencies.PSObject.Properties.Remove('dsh-locale-ru')
                $changed = $true
            }
        }
        if ($null -ne $pkg -and $null -ne $pkg.dsh -and $null -ne $pkg.dsh.profile) {
            $bundles = @(@($pkg.dsh.profile.bundles) | Where-Object { $_ -ne 'dsh-locale-ru' })
            if ($bundles.Count -ne @($pkg.dsh.profile.bundles).Count) {
                $pkg.dsh.profile.bundles = $bundles
                $changed = $true
            }
        }
        if ($changed) {
            $json = $pkg | ConvertTo-Json -Depth 20
            [System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding($false)))
            Write-Info 'Из профиля убрана зависимость dsh-locale-ru.'
        }
    } catch {
        $problems.Add("Не удалось очистить package.json профиля: $($_.Exception.Message)")
    }
}

if (Test-Path $patchPath) {
    try {
        $patch = Get-Content $patchPath -Raw
        $original = $patch
        $patch = [regex]::Replace($patch, "(?ms)^- id: locale-ru\r?\n(?:[ \t]+.*\r?\n)*", "")
        $patch = [regex]::Replace($patch, "(?ms)^- insert:\r?\n    - id: locale-ru\r?\n      name: dsh-locale-ru\r?\n?", "")
        $entries = @($patch -split "`r?`n" | Where-Object {
            $line = $_.Trim()
            $line -ne '' -and -not $line.StartsWith('#')
        })
        if ($entries.Count -eq 0) { $patch = "[]`r`n" }
        elseif ($patch.Trim() -ne '') { $patch = $patch.TrimEnd() + "`r`n" }
        if ($patch -ne $original) {
            [System.IO.File]::WriteAllText($patchPath, $patch, (New-Object System.Text.UTF8Encoding($false)))
            Write-Info 'Из cordis.patch.yml убрана запись загрузчика dsh-locale-ru.'
        }
    } catch {
        $problems.Add("Не удалось очистить cordis.patch.yml профиля: $($_.Exception.Message)")
    }
}

$target = Join-Path $ProfileDir 'node_modules\dsh-locale-ru'
if (Test-Path $target) {
    try {
        Remove-Item $target -Recurse -Force
        Write-Info 'Удалена копия пакета из node_modules профиля.'
    } catch {
        $problems.Add("Не удалось удалить $($target): $($_.Exception.Message)")
    }
}

# --- 3. Каталог пакета (в т.ч. ручная установка из архива) ------------------
if (Test-Path $PackDir) {
    $looksLikePack = $false
    try {
        $packManifest = Join-Path $PackDir 'package.json'
        if (Test-Path $packManifest) {
            $looksLikePack = (Get-Content $packManifest -Raw) -match 'dsh-locale-ru'
        }
        if (-not $looksLikePack) { $looksLikePack = Test-Path (Join-Path $PackDir 'unins000.exe') }
    } catch { }
    if ($looksLikePack) {
        try {
            Remove-Item $PackDir -Recurse -Force
            Write-Info "Удалён каталог пакета: $PackDir"
        } catch {
            $problems.Add("Не удалось удалить $($PackDir): $($_.Exception.Message)")
        }
    } else {
        Write-WarningLine "Каталог $PackDir не похож на пакет dsh-locale-ru — пропускаю удаление."
    }
}

# --- 4. Запись в «Приложениях и возможностях», если деинсталлятор не сработал
try {
    $uninstallRoot = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall'
    Get-ChildItem $uninstallRoot -ErrorAction SilentlyContinue | ForEach-Object {
        $entry = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($null -ne $entry.DisplayName -and $entry.DisplayName -match 'локализация DeepSeek Harness' -and
            $null -ne $entry.UninstallString -and $entry.UninstallString -match 'locale-packs') {
            Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Info 'Удалена запись «Русская локализация DeepSeek Harness» из списка приложений.'
        }
    }
} catch {
    $problems.Add("Не удалось проверить записи деинсталляции: $($_.Exception.Message)")
}

# --- 5. Проверка результата --------------------------------------------------
$leftovers = @()
if (Test-Path $PackDir) { $leftovers += "каталог $PackDir" }
if (Test-Path (Join-Path $ProfileDir 'node_modules\dsh-locale-ru')) { $leftovers += 'копия пакета в профиле' }
if (Test-Path $manifestPath) {
    if ((Get-Content $manifestPath -Raw) -match 'dsh-locale-ru') { $leftovers += 'упоминание в package.json профиля' }
}
if (Test-Path $patchPath) {
    if ((Get-Content $patchPath -Raw) -match 'dsh-locale-ru|locale-ru') { $leftovers += 'упоминание в cordis.patch.yml' }
}

foreach ($problem in $problems) { [Console]::Error.WriteLine("Ошибка: $problem") }
if ($leftovers.Count -gt 0) {
    foreach ($item in $leftovers) { [Console]::Error.WriteLine("Осталось: $item") }
    if (-not $Quiet) {
        Write-WarningLine 'Не всё удалось удалить. Перезапустите DeepSeek Harness и запустите очистку ещё раз.'
    }
    exit 1
}

if (-not $Quiet) {
    Write-Host ''
    Write-Host 'Готово: устаревший языковой пакет удалён.' -ForegroundColor Green
    Write-Host 'Русский язык теперь встроен в DeepSeek Harness: Настройки -> Общие -> Язык -> Русский.' -ForegroundColor Green
    Write-Host 'Перезапустите DeepSeek Harness, чтобы интерфейс загрузился без ошибок.' -ForegroundColor Yellow
}
exit 0
