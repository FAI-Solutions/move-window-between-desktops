; Move Window Between Desktops - Inno Setup 6.7.x script (7.x compatible)
; Built by build.ps1:  ISCC /DAppVersion=1.4 /DAppVersionNum=1.4.0.0 /Odist installer\setup.iss
#ifndef AppVersion
  #define AppVersion "0.0-dev"
  #define AppVersionNum "0.0.0.0"
#endif
#define AppName    "Move Window Between Desktops"
#define AppExe     "move-window-between-desktops.exe"
#define SetupExe   "setup-autostart.exe"
#define Repo       "https://github.com/FAI-Solutions/move-window-between-desktops"
#define BuildDir   "..\build\app"

[Setup]
AppId={{B7E8A3C2-4D5F-4E6B-9A1C-3F2D8E7B6A5C}
; ^^^ NEVER change: WinGet / Apps & Features identify v1.3 installs by this
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
VersionInfoVersion={#AppVersionNum}
AppPublisher=FAI-Solutions
AppPublisherURL={#Repo}
AppSupportURL={#Repo}/issues
AppUpdatesURL={#Repo}/releases
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.10240
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
OutputBaseFilename=move-window-between-desktops-setup
SetupIconFile=..\assets\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
Compression=lzma2/ultra
SolidCompression=yes
WizardStyle=modern
InfoAfterFile=shortcuts-info.rtf
LicenseFile=..\LICENSE
CloseApplications=no
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[InstallDelete]
; v1.3 put the DLL next to the exe - it would now act as "manual override"
; and pin the old DLL forever. Remove it.
Type: files; Name: "{app}\VirtualDesktopAccessor.dll"
; v1.3 portable leftover
Type: files; Name: "{app}\setup-autostart.ahk"

[Files]
Source: "{#BuildDir}\{#AppExe}";               DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\{#SetupExe}";             DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\app_icon.ico";            DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\LICENSE";                 DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\THIRD-PARTY-NOTICES.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\vda\*.dll";               DestDir: "{app}\vda"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}";           Filename: "{app}\{#SetupExe}"; Parameters: "/start"; IconFilename: "{app}\app_icon.ico"
Name: "{group}\Autostart Settings";   Filename: "{app}\{#SetupExe}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"

[Run]
; Runs elevated (admin install) -> scheduled tasks; non-admin install -> startup shortcut
Filename: "{app}\{#SetupExe}"; Parameters: "/install /silent"; Flags: runhidden waituntilterminated; StatusMsg: "Configuring autostart..."
; Start via Task Scheduler: detached from the installer (and from winget), elevated, no flashing.
; Also in silent mode, so "winget upgrade" does not leave users without hotkeys.
Filename: "{app}\{#SetupExe}"; Parameters: "/start"; Flags: runhidden nowait; StatusMsg: "Starting {#AppName}..."
Filename: "{#Repo}"; Description: "Open online documentation"; Flags: postinstall shellexec skipifsilent unchecked

[UninstallRun]
Filename: "{sys}\taskkill.exe";  Parameters: "/F /IM {#AppExe}"; Flags: runhidden; RunOnceId: "KillApp"
Filename: "{app}\{#SetupExe}";   Parameters: "/uninstall /silent"; Flags: runhidden waituntilterminated; RunOnceId: "RemoveAutostart"

[Code]
const
  VCREDIST_URL = 'https://aka.ms/vs/17/release/vc_redist.x64.exe';

function VCRedistInstalled(): Boolean;
var Installed: Cardinal;
begin
  Result :=
    (RegQueryDWordValue(HKLM64, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Installed', Installed) and (Installed = 1)) or
    (RegQueryDWordValue(HKLM32, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Installed', Installed) and (Installed = 1));
end;

function InstallVCRedist(): Boolean;
var ResultCode: Integer;
begin
  Result := False;
  try
    DownloadTemporaryFile(VCREDIST_URL, 'vc_redist.x64.exe', '', nil);
    Result := Exec(ExpandConstant('{tmp}\vc_redist.x64.exe'), '/install /quiet /norestart', '',
                   SW_HIDE, ewWaitUntilTerminated, ResultCode)
              and ((ResultCode = 0) or (ResultCode = 1638) or (ResultCode = 3010));
    Log('VC++ Redistributable exit code: ' + IntToStr(ResultCode));
  except
    Log('VC++ Redistributable download failed: ' + GetExceptionMessage);
  end;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var ResultCode: Integer;
begin
  Result := '';
  // 1. stop the running app (v1.3 or v1.4) - it holds exe + DLL open
  Exec(ExpandConstant('{sys}\schtasks.exe'), '/End /TN "MoveWindowBetweenDesktops"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM {#AppExe}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(500);
  // 2. VC++ runtime required by VirtualDesktopAccessor.dll
  if not VCRedistInstalled() then
  begin
    Log('VC++ Redistributable missing');
    if not IsAdmin() then
      Log('Non-admin install: cannot install VC++ Redistributable')
    else if WizardSilent() or
      (MsgBox('The Microsoft Visual C++ Redistributable (x64) is required but not installed.' + #13#10 +
              'Download and install it now (about 25 MB)?', mbConfirmation, MB_YESNO) = IDYES) then
      InstallVCRedist();
    if not VCRedistInstalled() and not WizardSilent() then
      MsgBox('The Visual C++ Redistributable (x64) is still missing.' + #13#10 +
             'The app will not start until it is installed:' + #13#10 + VCREDIST_URL,
             mbError, MB_OK);
  end;
end;
