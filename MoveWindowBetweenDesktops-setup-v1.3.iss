;
; Move Window Between Desktops - Inno Setup Installer Script v1.3 (final feature version)
;
#define AppName        "Move Window Between Desktops"
#define AppVersion     "1.3"
#define AppPublisher   "FAI-Solutions"
#define AppURL         "https://fai-solutions.codeberg.page/move-window-between-desktops/"
#define AppSupportURL  "https://codeberg.org/FAI-Solutions/move-window-between-desktops/issues"
#define AppUpdatesURL  "https://codeberg.org/FAI-Solutions/move-window-between-desktops/releases"
#define TaskName       "MoveWindowBetweenDesktops"

; Windows 10 (all builds)
#define DLL_URL_WIN10         "https://github.com/Ciantic/VirtualDesktopAccessor/releases/download/2019-windows10/VirtualDesktopAccessor.dll"
#define DLL_HASH_WIN10        "145431bc2090281838de31824bc829dd35688b13488f4850f4bc5f25f5e599da"

; Windows 11 Legacy (21H2, 22H2) - builds 22000-22630
#define DLL_URL_WIN11_LEGACY  "https://github.com/Ciantic/VirtualDesktopAccessor/releases/download/2023-11-10-windows11/VirtualDesktopAccessor.dll"
#define DLL_HASH_WIN11_LEGACY "6fde6f5f409b026688f01ac44973a9d95fb37ae71632e4cbdd8bdd8c7f7c9c17"

; Windows 11 23H2 - builds 22631-26099
#define DLL_URL_WIN11_23H2    "https://github.com/Ciantic/VirtualDesktopAccessor/releases/download/2024-01-25-windows11/VirtualDesktopAccessor.dll"
#define DLL_HASH_WIN11_23H2   "f78ff6334f6c0ef5175ec0819026cec31d421a564b9ed1ee1ac4b6ed98d4f999"

; Windows 11 24H2+ - builds 26100+
#define DLL_URL_WIN11_24H2    "https://github.com/Ciantic/VirtualDesktopAccessor/releases/download/2024-12-16-windows11/VirtualDesktopAccessor.dll"
#define DLL_HASH_WIN11_24H2   "8740c572a1c000e3b87ffeb1e4c397eae9af3bd4a2abdc3bcffacab4493f8ff5"
; =============================================================================

[Setup]
; --- Identity ---
AppName={#AppName}
AppVersion={#AppVersion}
AppId={{B7E8A3C2-4D5F-4E6B-9A1C-3F2D8E7B6A5C}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppSupportURL}
AppUpdatesURL={#AppUpdatesURL}

; --- Install paths ---
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes

; --- Hardware ---
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; --- Output ---
OutputDir=Output
OutputBaseFilename=move-window-between-desktops-setup
SetupIconFile=app_icon.ico

; --- Compression ---
Compression=lzma2/ultra
SolidCompression=yes

; --- Appearance ---
WizardStyle=modern

; --- Privileges ---
; Admin = scheduled task
; Non-admin fallback = startup folder shortcut
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

; --- Platform ---
MinVersion=10.0.0

; --- Info page shown after install, before Finish ---
InfoAfterFile=shortcuts-info-v1.3.rtf

; --- Uninstall ---
UninstallDisplayIcon={app}\move-window-between-desktops.exe
UninstallDisplayName={#AppName}
; =============================================================================

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
; =============================================================================

[Files]
; Main executable (compiled from AHK)
Source: "move-window-between-desktops.exe"; DestDir: "{app}"; Flags: ignoreversion

; Icon file (for tray)
Source: "app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion

; Windows 10 (all builds)
Source: "VirtualDesktopAccessor_Win10.dll";        DestDir: "{app}"; DestName: "VirtualDesktopAccessor.dll"; Check: IsWin10;        Flags: ignoreversion

; Windows 11 Legacy (21H2, 22H2) - builds 22000-22630
Source: "VirtualDesktopAccessor_Win11_Legacy.dll"; DestDir: "{app}"; DestName: "VirtualDesktopAccessor.dll"; Check: IsWin11_Legacy; Flags: ignoreversion

; Windows 11 23H2 - builds 22631-26099
Source: "VirtualDesktopAccessor_Win11_23H2.dll";   DestDir: "{app}"; DestName: "VirtualDesktopAccessor.dll"; Check: IsWin11_23H2;   Flags: ignoreversion

; Windows 11 24H2+ - builds 26100+
Source: "VirtualDesktopAccessor_Win11_24H2.dll";   DestDir: "{app}"; DestName: "VirtualDesktopAccessor.dll"; Check: IsWin11_24H2;   Flags: ignoreversion
; =============================================================================

[Icons]
; Start Menu shortcuts
Name: "{group}\{#AppName}";           Filename: "{app}\move-window-between-desktops.exe"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
; =============================================================================

[Run]
; GUI install: offer to start the app now (checked by default).
Filename: "{app}\move-window-between-desktops.exe"; \
  Description: "Start {#AppName} now"; \
  Flags: postinstall skipifsilent nowait

; Offer to open docs (unchecked by default)
Filename: "{#AppURL}"; \
  Description: "Open online documentation"; \
  Flags: postinstall shellexec skipifsilent unchecked
; =============================================================================

[UninstallRun]
; Remove the Windows Task Scheduler task (admin install path)
Filename: "schtasks.exe"; \
  Parameters: "/Delete /TN ""{#TaskName}"" /F"; \
  Flags: runhidden; \
  RunOnceId: "RemoveScheduledTask"

; Remove the Startup folder shortcut (non-admin install path)
Filename: "cmd.exe"; \
  Parameters: "/C del /F /Q ""{userstartup}\{#TaskName}.lnk"" 2>nul"; \
  Flags: runhidden; \
  RunOnceId: "RemoveStartupShortcut"

; Kill running process before uninstall
Filename: "taskkill.exe"; \
  Parameters: "/F /IM move-window-between-desktops.exe 2>nul"; \
  Flags: runhidden; \
  RunOnceId: "KillProcess"
; =============================================================================

[UninstallDelete]
Type: files; Name: "{app}\VirtualDesktopAccessor.dll"
; =============================================================================

[Code]

// WINDOWS BUILD DETECTION
// Returns the Windows build number (e.g., 19045 for Win10 22H2, 22631 for Win11 23H2)
function GetWindowsBuild(): Integer;
var
  BuildStr: String;
begin
  Result := 0;
  if RegQueryStringValue(HKLM,
    'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
    'CurrentBuildNumber', BuildStr) then
  begin
    Result := StrToIntDef(BuildStr, 0);
  end;
  Log(Format('Windows build number detected: %d', [Result]));
end;

// DLL SELECTION LOGIC
// Windows 10: All builds (typically 10240-19045+)
function IsWin10(): Boolean;
var
  Build: Integer;
begin
  Build := GetWindowsBuild();
  Result := (Build > 0) and (Build < 22000);
  if Result then Log(Format('Selected DLL: Windows 10 (build %d)', [Build]));
end;

// Windows 11 Legacy: 21H2 and 22H2 (builds 22000-22630)
function IsWin11_Legacy(): Boolean;
var
  Build: Integer;
begin
  Build := GetWindowsBuild();
  Result := (Build >= 22000) and (Build < 22631);
  if Result then Log(Format('Selected DLL: Windows 11 Legacy (build %d)', [Build]));
end;

// Windows 11 23H2: builds 22631-26099
function IsWin11_23H2(): Boolean;
var
  Build: Integer;
begin
  Build := GetWindowsBuild();
  Result := (Build >= 22631) and (Build < 26100);
  if Result then Log(Format('Selected DLL: Windows 11 23H2 (build %d)', [Build]));
end;

// Windows 11 24H2+: builds 26100 and above
function IsWin11_24H2(): Boolean;
var
  Build: Integer;
begin
  Build := GetWindowsBuild();
  Result := Build >= 26100;
  if Result then Log(Format('Selected DLL: Windows 11 24H2+ (build %d)', [Build]));
end;

// ADMIN PATH: Create Windows Task Scheduler task via Exec(schtasks.exe)
// NON-ADMIN PATH: Create a Startup folder shortcut instead.
procedure CurStepChanged(CurStep: TSetupStep);
var
  AppExe:      String;
  TaskParams:  String;
  ResultCode:  Integer;
  StartupLnk:  String;
  oShell:      Variant;
  oShortcut:   Variant;
begin
  if CurStep = ssPostInstall then
  begin
    AppExe := ExpandConstant('{app}\move-window-between-desktops.exe');

    if IsAdmin() then
    begin

      TaskParams := '/Create /F /RL HIGHEST /SC ONLOGON'
        + ' /TN "' + '{#TaskName}' + '"'
        + ' /TR "\"' + AppExe + '\""';

      Log('Creating scheduled task with: schtasks.exe ' + TaskParams);

      if not Exec('schtasks.exe', TaskParams, '', SW_HIDE,
                  ewWaitUntilTerminated, ResultCode) then
      begin
        Log('ERROR: Could not launch schtasks.exe. Code: ' + IntToStr(ResultCode));
        MsgBox(
          'Could not create the autostart scheduled task.' + #13#10 +
          'The application was installed but will not start automatically.' + #13#10 + #13#10 +
          'You can create it manually by re-running the installer as Administrator.',
          mbError, MB_OK);
      end
      else if ResultCode <> 0 then
      begin
        Log('WARNING: schtasks.exe exited with code: ' + IntToStr(ResultCode));
        MsgBox(
          'The autostart scheduled task could not be created (exit code: '
          + IntToStr(ResultCode) + ').' + #13#10 +
          'The application was installed but will not start automatically.' + #13#10 + #13#10 +
          'You can create it manually by re-running the installer as Administrator.',
          mbError, MB_OK);
      end
      else
      begin
        Log('Scheduled task created successfully. App will start automatically on next login.');

        // For silent/winget installs: open the install folder in Explorer so the
        // user knows where the app was installed, thus can start the app
        if WizardSilent() then
        begin
          ShellExec('explore', ExpandConstant('{app}'), '', '',
                    SW_SHOW, ewNoWait, ResultCode);
          Log('Opened install folder in Explorer for silent install.');
        end;
      end;
    end
    else
    begin
      // Non-admin fallback: Startup folder shortcut
      Log('Non-admin install — creating Startup folder shortcut as fallback.');

      StartupLnk := ExpandConstant('{userstartup}\{#TaskName}.lnk');

      try
        oShell    := CreateOleObject('WScript.Shell');
        oShortcut := oShell.CreateShortcut(StartupLnk);
        oShortcut.TargetPath       := AppExe;
        oShortcut.WorkingDirectory := ExpandConstant('{app}');
        oShortcut.Save();

        if FileExists(StartupLnk) then
        begin
          Log('Startup folder shortcut created: ' + StartupLnk);
          // ShellExec launches de-elevated (not inheriting installer token)
          ShellExec('open', AppExe, '', ExpandConstant('{app}'),
                    SW_SHOW, ewNoWait, ResultCode);
          Log('App launched via ShellExec after startup shortcut creation.');
          MsgBox(
            'Autostart configured via Startup folder shortcut.' + #13#10 + #13#10 +
            'Note: Without administrator rights, elevated windows (e.g. Task Manager) ' +
            'cannot be moved between desktops.' + #13#10 + #13#10 +
            'To enable full functionality, re-run the installer as Administrator.',
            mbInformation, MB_OK);
        end
        else
          Log('WARNING: Startup folder shortcut creation failed silently.');
      except
        Log('ERROR creating Startup folder shortcut: ' + GetExceptionMessage);
      end;
    end;
  end;
end;

// Stop the running EXE before uninstalling to avoid file-in-use errors.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    Exec('taskkill.exe', '/F /IM move-window-between-desktops.exe', '',
      SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;

// Check Windows version and warn if unsupported.
function InitializeSetup(): Boolean;
var
  Build:    Integer;
  Selected: Boolean;
begin
  Result := True;
  Build  := GetWindowsBuild();
  Selected := False;

  if IsWin10()        then Selected := True;
  if IsWin11_Legacy() then Selected := True;
  if IsWin11_23H2()   then Selected := True;
  if IsWin11_24H2()   then Selected := True;

  if Build = 0 then
  begin
    MsgBox('Could not detect Windows build number.' + #13#10 +
           'The installation will continue, but the application may not work correctly.',
           mbInformation, MB_OK);
  end
  else if Build < 10240 then
  begin
    MsgBox('Warning: Your Windows build (' + IntToStr(Build) + ') is not supported.' + #13#10 +
           'This application requires Windows 10 or later.',
           mbError, MB_OK);
    Result := False;
  end
  else if not Selected then
  begin
    MsgBox('Warning: Your Windows build (' + IntToStr(Build) + ') is newer than expected.' + #13#10 +
           'The application may not work correctly.' + #13#10 + #13#10 +
           'Please check for an updated version of this installer.',
           mbInformation, MB_OK);
  end;
end;
