; Inno Setup script for the Russian language pack installer.
;
; Build:
;   ISCC.exe /DMyAppVersion=0.1.0 installer\installer.iss
;
; Expects the staged payload in ..\payload (see .github/workflows/release.yml).

#define MyAppName "Русская локализация DeepSeek Harness"
#define MyAppPublisher "dsh-locale-ru"
#define MyAppURL "https://github.com/cptn73m0/dsh-locale-ru"
#ifndef MyAppVersion
  #define MyAppVersion "0.1.0"
#endif

[Setup]
AppId={{9C8E2E8B-6F3A-4C7E-9D2B-2A7C4F1E5D10}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={userprofile}\.dsh\locale-packs\ru
DisableDirPage=yes
DisableProgramGroupPage=yes
UsePreviousAppDir=no
LicenseFile=..\LICENSE
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=dsh-locale-ru-setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupLogging=yes
UninstallDisplayName={#MyAppName}
MinVersion=10.0
ArchitecturesAllowed=x64compatible

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Files]
Source: "..\payload\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Удалить русскую локализацию"; Filename: "{uninstallexe}"

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\install-offline.ps1"" -PackDir ""{app}"" -Quiet"; Flags: runhidden waituntilterminated; StatusMsg: "Включаю русскую локализацию..."; Check: ProfileExists

[UninstallRun]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\uninstall-offline.ps1"" -Quiet"; Flags: runhidden waituntilterminated; RunOnceId: "RemoveRussianLocale"

[Code]
function ProfileDir(): String;
begin
  Result := ExpandConstant('{userprofile}\.dsh\profiles\desktop');
end;

function ProfileExists(): Boolean;
begin
  Result := DirExists(ProfileDir());
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and (not ProfileExists()) then
    MsgBox('Профиль DeepSeek Harness не найден.' + #13#10 +
           'Запустите DeepSeek Harness один раз, затем запустите установщик снова, ' +
           'чтобы включить русский язык.', mbInformation, MB_OK);
end;
