; Inno Setup script for the legacy Russian language pack cleanup tool.
;
; The tool removes the community language pack installed by dsh-locale-ru
; 0.1.x. DeepSeek Harness 0.2.2+ ships Russian officially, so the pack is no
; longer needed and conflicts with the built-in dictionaries.
;
; Build:
;   ISCC.exe /DMyAppVersion=0.2.0 installer\cleanup.iss
;
; Expects the staged script in ..\payload (see .github/workflows/release.yml).

#define MyAppName "Очистка русской локализации DeepSeek Harness"
#define MyAppPublisher "dsh-locale-ru"
#define MyAppURL "https://github.com/cptn73m0/dsh-locale-ru"
#ifndef MyAppVersion
  #define MyAppVersion "0.2.0"
#endif

[Setup]
; A separate AppId: the tool is not installed, it removes the old pack.
AppId={{7C4D9E1A-3B2F-4A8C-9E6D-5F1B2C3D4E5F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
CreateAppDir=no
Uninstallable=no
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=dsh-locale-ru-cleanup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupLogging=yes
MinVersion=10.0
ArchitecturesAllowed=x64compatible
InfoAfterFile=..\cleanup\cleanup-info.txt

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Files]
Source: "..\payload\cleanup-offline.ps1"; DestDir: "{tmp}"; Flags: ignoreversion

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{tmp}\cleanup-offline.ps1"""; Flags: runhidden waituntilterminated; StatusMsg: "Удаляю устаревший языковой пакет…"
