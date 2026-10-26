#Requires AutoHotkey v2.0
#SingleInstance Off
#NoTrayIcon

; Move Window Between Desktops (homepage and repositories)
; https://fai-solutions.codeberg.page/move-window-between-desktops/
; https://github.com/FAI-Solutions/move-window-between-desktops
; https://codeberg.org/FAI-Solutions/move-window-between-desktops
; -----------------------------------------------------------------
; Info about install-switches: /install /uninstall /start /silent   (default: no switch, interactive install)

; Version / paths
global ScriptVersion    := "1.4"
;@Ahk2Exe-Let U_Version = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%
;@Ahk2Exe-SetVersion %U_Version%
;@Ahk2Exe-SetProductName Move Window Between Desktops
;@Ahk2Exe-SetDescription Move Window Between Desktops - Autostart Setup
;@Ahk2Exe-SetCompanyName FAI-Solutions
;@Ahk2Exe-SetCopyright Copyright (c) 2026 Johannes Faber - MIT License
;@Ahk2Exe-SetMainIcon ..\assets\app_icon.ico
global ScriptName       := "Move Window Between Desktops - Setup"
global taskName         := "MoveWindowBetweenDesktops"
global watchdogTaskName := "MoveWindowBetweenDesktops-Watchdog"
global startupFolder    := A_Startup "\" taskName ".lnk"
global Silent           := HasArg("/silent")

; Target either compiled exe or AHK script
if A_IsCompiled {
    global targetExe    := A_ScriptDir "\move-window-between-desktops.exe"
    global targetArgs   := ""
} else {
    global targetExe    := FindAhkExe()
    global targetArgs   := '"' A_ScriptDir '\move-window-between-desktops.ahk"'
}
if !FileExist(A_ScriptDir (A_IsCompiled ? "\move-window-between-desktops.exe" : "\move-window-between-desktops.ahk"))
    Fail("Could not find the main " (A_IsCompiled ? "exe" : "script") " in the same folder as this setup.")
if (targetExe = "")
    Fail("Could not find AutoHotkey v2. Please install AutoHotkey v2.0 first.")

; Switch routing
if HasArg("/uninstall")
    ExitApp(RemoveAll() ? 0 : 1)
if HasArg("/install") {
    ok := A_IsAdmin ? CreateTasks() : CreateShortcut()
    ExitApp(ok ? 0 : 1)
}
if HasArg("/start")
    ExitApp(StartApp() ? 0 : 1)

; Interactive (default)
if !A_IsAdmin {
    try {
        Run('*RunAs "' (A_IsCompiled ? A_ScriptFullPath : A_AhkPath '" "' A_ScriptFullPath) '"')
        ExitApp
    }
    Interactive(false)      ; UAC declined -> startup shortcut
} else {
    Interactive(true)
}
ExitApp

Interactive(admin) {
    exists := admin ? (TaskExists(taskName) || TaskExists(watchdogTaskName)) : FileExist(startupFolder)
    if exists {
        choice := MsgBox("Autostart is already configured.`n`nYes = Remove autostart`nNo = Recreate (recommended after updating)`nCancel = Exit", ScriptName, 3 + 32)
        if (choice = "Cancel")
            return
        if (choice = "Yes") {
            RemoveAll()
            MsgBox "Autostart removed.`n`nThe app will no longer start automatically.", ScriptName, 64
            return
        }
    }
    if !(admin ? CreateTasks() : CreateShortcut()) {
        MsgBox "Failed to configure autostart.", ScriptName, 16
        return
    }
    msg := admin
        ? "Autostart and watchdog created.`n`nThe app starts with administrator rights at logon and is restarted after unlock or resume if it is not running."
        : "Startup shortcut created.`n`nWithout administrator rights elevated windows (e.g. Task Manager) cannot be moved and no watchdog is installed."
    if MsgBox(msg "`n`nStart the app now?", ScriptName, 4 + 64) = "Yes"
        StartApp()
}

; Actions
CreateTasks() {
    userId := EnvGet("USERDOMAIN") "\" A_UserName
    argBase := Trim(targetArgs " ")
    logonXml := TaskXml("Starts Move Window Between Desktops at logon."
        , LogonTriggerXml(userId, "PT5S"), userId, targetExe, Trim(argBase " --autostart"), A_ScriptDir)
    watchdogXml := TaskXml("Watchdog: starts Move Window Between Desktops if it is not running (logon, unlock, user switch, resume). Event based, no polling."
        , WatchdogTriggersXml(userId), userId, targetExe, Trim(argBase " --watchdog"), A_ScriptDir)
    if !RegisterTaskXml(taskName, logonXml) || !RegisterTaskXml(watchdogTaskName, watchdogXml)
        return false
    if FileExist(startupFolder)
        try FileDelete(startupFolder)
    return true
}

CreateShortcut() {
    try {
        if FileExist(startupFolder)
            FileDelete(startupFolder)
        sc := ComObject("WScript.Shell").CreateShortcut(startupFolder)
        sc.TargetPath := targetExe
        sc.Arguments := Trim(targetArgs " --autostart")
        sc.WorkingDirectory := A_ScriptDir
        sc.Save()
        return FileExist(startupFolder) != ""
    } catch {
        return false
    }
}

RemoveAll() {
    if A_IsAdmin {
        RunWait('schtasks /Delete /TN "' taskName '" /F',, "Hide")
        RunWait('schtasks /Delete /TN "' watchdogTaskName '" /F',, "Hide")
    }
    if FileExist(startupFolder)
        try FileDelete(startupFolder)
    return !(A_IsAdmin && (TaskExists(taskName) || TaskExists(watchdogTaskName)))
}

; Via Task Scheduler (elevated, detached from the installer)
StartApp() {
    if TaskExists(taskName)
        return RunWait('schtasks /Run /TN "' taskName '"',, "Hide") = 0
    try {
        Run('"' targetExe '" ' targetArgs, A_ScriptDir)
        return true
    } catch {
        return false
    }
}

; Helpers
HasArg(name) {
    for arg in A_Args
        if (arg = name)
            return true
    return false
}

Fail(msg) {
    if !Silent
        MsgBox msg, ScriptName, 16
    ExitApp 1
}

FindAhkExe() {
    exe := A_AhkPath
    scoop := RegExReplace(exe, "i)(\\scoop\\apps\\autohotkey[^\\]*\\)[^\\]+\\", "$1current\")
    if (scoop != exe && FileExist(scoop))
        exe := scoop
    return FileExist(exe) ? exe : ""
}

TaskExists(name) => RunWait('schtasks /Query /TN "' name '"',, "Hide") = 0

RegisterTaskXml(name, xml) {
    tmp := A_Temp "\" name ".xml"
    try FileDelete(tmp)
    f := FileOpen(tmp, "w", "UTF-16")
    f.Write(xml)
    f.Close()
    code := RunWait('schtasks /Create /TN "' name '" /XML "' tmp '" /F',, "Hide")
    try FileDelete(tmp)
    return code = 0
}

XmlEscape(s) => StrReplace(StrReplace(StrReplace(s, "&", "&amp;"), "<", "&lt;"), ">", "&gt;")

LogonTriggerXml(userId, delay) {
    return Format('
(
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>{1}</UserId>
      <Delay>{2}</Delay>
    </LogonTrigger>
)', XmlEscape(userId), delay)
}

WatchdogTriggersXml(userId) {
    ; sleep + hibernation
    resumeQuery := '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name="Microsoft-Windows-Power-Troubleshooter"] and EventID=1]]</Select></Query></QueryList>'
    return Format('
(
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>{1}</UserId>
      <Delay>PT60S</Delay>
    </LogonTrigger>
    <SessionStateChangeTrigger>
      <Enabled>true</Enabled>
      <StateChange>SessionUnlock</StateChange>
      <UserId>{1}</UserId>
      <Delay>PT3S</Delay>
    </SessionStateChangeTrigger>
    <SessionStateChangeTrigger>
      <Enabled>true</Enabled>
      <StateChange>ConsoleConnect</StateChange>
      <UserId>{1}</UserId>
      <Delay>PT3S</Delay>
    </SessionStateChangeTrigger>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>{2}</Subscription>
      <Delay>PT10S</Delay>
    </EventTrigger>
)', XmlEscape(userId), XmlEscape(resumeQuery))
}

TaskXml(description, triggers, userId, command, args, workDir) {
    return Format('
(
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>{1}</Description>
  </RegistrationInfo>
  <Triggers>
{2}
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>{3}</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>4</Priority>
    <RestartOnFailure>
      <Interval>PT1M</Interval>
      <Count>3</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>{4}</Command>
      <Arguments>{5}</Arguments>
      <WorkingDirectory>{6}</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
)', XmlEscape(description), triggers, XmlEscape(userId), XmlEscape(command), XmlEscape(args), XmlEscape(workDir))
}
