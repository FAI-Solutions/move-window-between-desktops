#Requires AutoHotkey v2.0
#SingleInstance Off
#NoTrayIcon
#UseHook True
#MaxThreadsPerHotkey 1

; Move Window Between Desktops (homepage and repositories)
; https://fai-solutions.codeberg.page/move-window-between-desktops/
; https://github.com/FAI-Solutions/move-window-between-desktops
; https://codeberg.org/FAI-Solutions/move-window-between-desktops
; -----------------------------------------------------------------

; --- Version / paths
global ScriptVersion    := "1.4"
;@Ahk2Exe-Let U_Version = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%
;@Ahk2Exe-SetVersion %U_Version%
;@Ahk2Exe-SetProductName Move Window Between Desktops
;@Ahk2Exe-SetDescription Move Window Between Desktops
;@Ahk2Exe-SetCompanyName FAI-Solutions
;@Ahk2Exe-SetCopyright Copyright (c) 2026 Johannes Faber - MIT License
;@Ahk2Exe-SetMainIcon ..\assets\app_icon.ico
global ScriptName       := "Move Window Between Desktops"
global ScriptURL        := "https://github.com/FAI-Solutions/move-window-between-desktops"
global SettingsDir      := A_AppData "\MoveWindowBetweenDesktops"
global SettingsFile     := SettingsDir "\settings.ini"
global LogFile          := SettingsDir "\debug.log"
global IsAlphaBuild     := InStr(ScriptVersion, "alpha") > 0
global IsWin10          := VerCompare(A_OSVersion, "10.0.22000") < 0
global StartTick        := A_TickCount
global MyPID            := DllCall("GetCurrentProcessId", "UInt")
global SWITCH_SETTLE_MS := 120          ; max wait for Explorer to activate

; --- Desktop name OSD appearance
global OSD_MONITOR      := "P"
global OSD_SIDE         := "right"     ; "right" | "left" | "center"
global OSD_EDGE         := "bottom"    ; "bottom" | "top" | "center"
global OSD_MARGIN_X     := 40
global OSD_MARGIN_Y     := 34
global OSD_DURATION     := 1100        ; ms on screen
global OSD_NUMBER_MODE  := "never"     ; "never" | "smart" (prefix only named desktops) | "always"
global OSD_FONT_SIZE    := 22
global OSD_FONT         := "Segoe UI"
global OSD_PAD_X        := 26
global OSD_PAD_Y        := 4
global OSD_BG           := "1F1F1F"
global OSD_FG           := "FFFFFF"
global OSD_OPACITY      := 235
global OSD_CLICKTHROUGH := true
global OSD_POLL_MS      := 100
global VD_ROOT          := "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops"

; --- Runtime state
global CyclingEnabled   := false
global OsdEnabled       := false
global DebugEnabled     := IniRead(SettingsFile, "Debug", "Enabled", "0") = "1"
global IsReady          := false
global VdaFuncs         := Map()
global Osd := "", OsdText := ""
global OsdLastKey       := ""
global OsdLastText      := ""
global OsdExpectKey     := ""
global OsdExpectUntil   := 0
global RecoveryReason   := ""

; --- Start mode
global IsRestart        := RegExMatch(DllCall("GetCommandLine", "Str"), " /restart(?!\S)") > 0
global IsWatchdogStart  := HasArg("--watchdog") && !IsRestart
global IsAutostart      := HasArg("--autostart")

; 1) Watchdog respects an "Exit" (until next logon or manual start)
if IsWatchdogStart && IniRead(SettingsFile, "State", "UserExited", "0") = "1"
    ExitApp
if !IsWatchdogStart
    SaveSetting("State", "UserExited", "0")

; 2) Request admin rights (to move elevated windows). Never prompt for watchdog / autostart starts.
if !A_IsAdmin && !IsRestart && !IsWatchdogStart && !IsAutostart {
    try {
        if A_IsCompiled
            Run('*RunAs "' A_ScriptFullPath '" /restart' ForwardArgs())
        else
            Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"' ForwardArgs())
        ExitApp
    }
    ; if UAC declined then continue in user mode
}

; 3) Watchdog quits silently if already running, every other start replaces the old instance
EnsureSingleInstance()
DebugLog("==== start v" ScriptVersion " | admin=" A_IsAdmin " | restart=" IsRestart " | watchdog=" IsWatchdogStart " | autostart=" IsAutostart " | settle=" SWITCH_SETTLE_MS "ms | OS " A_OSVersion)

; 4) Tray (hidden until now because of #NoTrayIcon)
A_IconTip := ScriptName " v" ScriptVersion (A_IsAdmin ? " (Admin Mode)" : " (User Mode)`nElevated windows cannot be moved")
if FileExist(A_ScriptDir "\app_icon.ico")
    TraySetIcon(A_ScriptDir "\app_icon.ico")
CyclingEnabled := IniRead(SettingsFile, "Settings", "Cycling", "0") = "1"
osdSetting     := IniRead(SettingsFile, "Settings", "ShowDesktopName", "")
OsdEnabled     := (osdSetting = "") ? IsWin10 : (osdSetting = "1")   ; default: on for Win10, off for Win11 (natively displays desktop names)
SetupTrayMenu()
A_IconHidden := false

SendMode "Input"
SetWinDelay 0

; 5) DLL + wait for shell / virtual desktop service
LoadVirtualDesktopAccessor()
WinWait("ahk_class Shell_TrayWnd",, 60)
if !WaitForVirtualDesktopService(60)
    ShowTip("Virtual desktop service not reachable yet.`nIf hotkeys do not work, use 'Reload Script' from the tray menu.")

; 6) "Self-healing": Explorer restart, resume from sleep / hibernation, unlock / user switch
OnMessage(DllCall("RegisterWindowMessage", "Str", "TaskbarCreated", "UInt"), OnTaskbarCreated)
OnMessage(0x0218, OnPowerBroadcast)
OnMessage(0x02B1, OnSessionChange)
DllCall("wtsapi32\WTSRegisterSessionNotification", "Ptr", A_ScriptHwnd, "UInt", 0)

; 7) Desktop name OSD
CreateOsd()
if OsdEnabled
    StartOsd()

IsReady := true
DebugLog("ready")

; --- Startup helper
HasArg(name) {
    for arg in A_Args
        if (arg = name)
            return true
    return false
}

ForwardArgs() {
    s := ""
    for arg in A_Args
        s .= ' "' arg '"'
    return s
}

SaveSetting(section, key, value) {
    try {
        DirCreate(SettingsDir)
        IniWrite(value, SettingsFile, section, key)
    }
}

EnsureSingleInstance() {
    prevDHW := DetectHiddenWindows(true)
    for hwnd in WinGetList("ahk_class AutoHotkey") {
        try {
            pid   := WinGetPID(hwnd)
            title := WinGetTitle(hwnd)
        } catch {
            continue
        }
        if (pid = MyPID || InStr(title, A_ScriptFullPath) != 1)
            continue
        if IsWatchdogStart
            ExitApp
        try PostMessage(0x0111, 65307, 0,, hwnd)
        if !WinWaitClose(hwnd,, 2)
            try ProcessClose(pid)
    }
    DetectHiddenWindows(prevDHW)
}

GetVdaDllPath() {
    override := A_ScriptDir "\VirtualDesktopAccessor.dll"
    if FileExist(override)
        return override
    parts := StrSplit(A_OSVersion, ".")
    build := (parts.Length >= 3 && IsInteger(parts[3])) ? Integer(parts[3]) : 0
    if (build < 22000)
        variant := "Win10"
    else if (build < 22631)
        variant := "Win11_Legacy"
    else if (build < 26100)
        variant := "Win11_23H2"
    else
        variant := "Win11_24H2"          ; at release newest DLL
    return A_ScriptDir "\vda\VirtualDesktopAccessor_" variant ".dll"
}

LoadVirtualDesktopAccessor() {
    global VdaFuncs
    dllPath := GetVdaDllPath()
    hDll := DllCall("LoadLibraryExW", "Str", dllPath, "Ptr", 0, "UInt", 0x8, "Ptr")
    if !hDll {
        code := A_LastError
        if !FileExist(dllPath)
            hint := "The DLL file is missing. Reinstall the app, or place VirtualDesktopAccessor.dll in the script folder."
        else if (code = 126)
            hint := "Windows could not load a component the DLL depends on.`nMost likely the 'Microsoft Visual C++ Redistributable (x64)' is not installed."
        else if (code = 193)
            hint := "The DLL does not match the AutoHotkey bitness (" (A_PtrSize * 8) "-bit)."
        else
            hint := "Make sure the DLL matches your Windows build."
        MsgBox "Failed to load VirtualDesktopAccessor.dll! (Windows error " code ")`n`n" dllPath "`n`n" hint, "Error", 16
        ExitApp
    }
    DebugLog("VDA loaded: " dllPath " (OS " A_OSVersion ")")
    for name in ["GetCurrentDesktopNumber", "GetDesktopCount", "MoveWindowToDesktopNumber", "GoToDesktopNumber", "IsWindowOnDesktopNumber"] {
        proc := DllCall("GetProcAddress", "Ptr", hDll, "AStr", name, "Ptr")
        if !proc {
            MsgBox "VirtualDesktopAccessor.dll does not export '" name "'.`n`nPlease download the DLL version matching your Windows build.", "Error", 16
            ExitApp
        }
        VdaFuncs[name] := proc
    }
}

; Every DLL call goes through here: DDL errors are written to logs (except for alpha versions).
Vda(name, args*) {
    static lastTip := 0
    if !VdaFuncs.Has(name) {
        DebugLog("VDA " name ": DLL not loaded -> LoadVirtualDesktopAccessor() missing in section 5")
        MsgBox "Internal error: VirtualDesktopAccessor.dll was never loaded.`n`n"
             . "LoadVirtualDesktopAccessor() is missing in section 5 of the script.", "Error", 16
        ExitApp
    }
    try {
        return DllCall(VdaFuncs[name], args*)
    } catch as e {
        detail := "VDA " name " threw: " e.Message " [" e.Extra "]"
        DebugLog(detail)
        if (IsAlphaBuild && A_TickCount - lastTip > 10000) {
            lastTip := A_TickCount
            ShowTip(detail)
        }
        return -1
    }
}

WaitForVirtualDesktopService(timeoutSec) {
    loop timeoutSec * 2 {
        if Vda("GetDesktopCount", "Int") > 0
            return true
        Sleep 500
    }
    return false
}

; --- Self-Healing
OnTaskbarCreated(*) {
    if (A_TickCount - StartTick < 20000)
        return
    DebugLog("TaskbarCreated (Explorer restarted) -> reload in 3 s")
    SetTimer(ReloadScript, -3000)
}

OnPowerBroadcast(wParam, *) {
    if (wParam = 0x7 || wParam = 0x12)
        ScheduleRecovery("resume")
}

OnSessionChange(wParam, *) {
    if (wParam = 0x8)
        ScheduleRecovery("unlock")
    else if (wParam = 0x1)
        ScheduleRecovery("console-connect")
}

ScheduleRecovery(reason) {
    global RecoveryReason := reason
    SetTimer(Recover, -3000)
}

Recover() {
    DebugLog("recover (" RecoveryReason ")")
    try InstallKeybdHook(true, true)
    if !WaitForVirtualDesktopService(30) {
        DebugLog("recover: virtual desktop service not reachable -> reload")
        ReloadScript()
    }
}

; --- Tray Menu
SetupTrayMenu() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Open Repository", OpenWebsite)
    A_TrayMenu.Add("View Shortcuts", ShowShortcuts)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Enable Cycling", ToggleCycling)
    A_TrayMenu.Add("Show Desktop Name", ToggleOsd)
    if CyclingEnabled
        A_TrayMenu.Check("Enable Cycling")
    if OsdEnabled
        A_TrayMenu.Check("Show Desktop Name")
    A_TrayMenu.Add()
    A_TrayMenu.Add("Reload Script", ReloadScript)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Debug Logging", ToggleDebug)
    if DebugEnabled
        A_TrayMenu.Check("Debug Logging")
    A_TrayMenu.Add("Open Debug Log", OpenDebugLog)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", ExitScript)
    A_TrayMenu.Default := "View Shortcuts"
}

ToggleCycling(ItemName, *) {
    global CyclingEnabled
    CyclingEnabled := !CyclingEnabled
    A_TrayMenu.ToggleCheck(ItemName)
    SaveSetting("Settings", "Cycling", CyclingEnabled ? "1" : "0")
    ShowTip(CyclingEnabled ? "Cycling enabled: last and first desktop are connected." : "Cycling disabled.")
}

ToggleOsd(ItemName, *) {
    global OsdEnabled
    OsdEnabled := !OsdEnabled
    A_TrayMenu.ToggleCheck(ItemName)
    SaveSetting("Settings", "ShowDesktopName", OsdEnabled ? "1" : "0")
    if OsdEnabled {
        StartOsd()
        ShowOsd(DesktopLabel(CurrentDesktopGuid()))   ; preview
    } else {
        StopOsd()
    }
}

ToggleDebug(ItemName, *) {
    global DebugEnabled
    DebugEnabled := !DebugEnabled
    A_TrayMenu.ToggleCheck(ItemName)
    SaveSetting("Debug", "Enabled", DebugEnabled ? "1" : "0")
    DebugLog("debug logging enabled | v" ScriptVersion " | admin=" A_IsAdmin " | OS " A_OSVersion)
}

OpenDebugLog(*) {
    if FileExist(LogFile)
        Run('notepad.exe "' LogFile '"')
    else
        ShowTip("No debug log yet. Enable 'Debug Logging' first.")
}

OpenWebsite(*) {
    Run ScriptURL
}

ShowShortcuts(*) {
    shortcutsText := ""
    . "• Move Window across virtual Desktops:`n"
    . "    Ctrl + Shift + Win + Right`n"
    . "    Ctrl + Shift + Win + Left`n`n"
    . "• Move Window across virtual Desktops (alternative):`n"
    . "    Ctrl + Shift + Alt + Right`n"
    . "    Ctrl + Shift + Alt + Left`n`n"
    . "• Switch virtual Desktops:`n"
    . "    Ctrl + Win + Right`n"
    . "    Ctrl + Win + Left`n`n"
    . "• Switch virtual Desktops (alternative):`n"
    . "    Ctrl + Alt + Right`n"
    . "    Ctrl + Alt + Left`n`n"
    . "• Cycling (last ↩ ↪ first desktop): " (CyclingEnabled ? "ON" : "OFF") "`n"
    . "• Show Desktop Name: " (OsdEnabled ? "ON" : "OFF") "`n  (both toggle in the tray menu)`n`n"
    . "Note: Elevated windows (such as Task Manager) can only be moved, when running as Administrator."
    MsgBox shortcutsText, ScriptName " v" ScriptVersion " - Keyboard Shortcuts", 64
}

ReloadScript(*) {
    Reload
}

ExitScript(*) {
    SaveSetting("State", "UserExited", "1")   ; watchdog will not restart until next logon/manual start
    ExitApp
}

ShowTip(msg) {
    TrayTip(msg, ScriptName, "Iconi Mute")
}

; --- Debug log
DebugLog(msg) {
    if !DebugEnabled
        return
    try {
        DirCreate(SettingsDir)
        if (FileExist(LogFile) && FileGetSize(LogFile) > 1048576)
            FileMove(LogFile, LogFile ".old", true)
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") "." A_MSec "  " msg "`n", LogFile, "UTF-8")
    }
}

FgInfo() {
    hwnd := WinExist("A")
    if !hwnd
        return "none"
    try {
        return WinGetClass(hwnd) " / " WinGetProcessName(hwnd)
    } catch {
        return "hwnd " hwnd " (no access)"
    }
}

; --- Core execution
; Runs the action once, then ignores keyboard auto-repeat until the arrow key is released
HotkeyAction(action, direction, key) {
    if !IsReady
        return
    if DebugEnabled
        DebugLog("hotkey " A_ThisHotkey " | fg=" FgInfo())
    Critical "On"
    try {
        action(direction)
    } catch as err {
        detail := err.Message (err.Extra != "" ? " [" err.Extra "]" : "") " | " err.What " line " err.Line
        DebugLog("ERROR " detail "`n" err.Stack)
        ShowTip("Error: " detail)
    }
    Critical "Off"
    WaitForKeyRelease(key)
}

; Holding a key produces auto-repeat input at least every ~400 ms (after max 1000 ms initial delay)
WaitForKeyRelease(key) {
    while GetKeyState(key, "P") {
        if (A_TimeIdleKeyboard > 1200) {
            DebugLog("key release fallback for " key)
            break
        }
        Sleep 20
    }
}

; Returns target desktop index (0-based) or -1 (true when cycling wrapped around)
GetTargetDesktop(direction, &wrapped) {
    wrapped := false
    count   := Vda("GetDesktopCount", "Int")
    current := Vda("GetCurrentDesktopNumber", "Int")
    if (count < 0 || current < 0) {
        DebugLog("VDA error: count=" count " current=" current)
        ShowTip("Virtual desktop API not reachable (Explorer restarted or DLL does not match your Windows build).`nTry 'Reload Script' from the tray menu.")
        return -1
    }
    if (count < 2)
        return -1
    target := current + (direction = "right" ? 1 : -1)
    if (target < 0 || target >= count) {
        if !CyclingEnabled
            return -1
        target := Mod(target + count, count)
        wrapped := true
    }
    return target
}

MoveWindowToDesktop(direction) {
    hwnd := WinExist("A")
    if (!hwnd || IsShellWindow(hwnd)) {
        DebugLog("move: no movable window -> switch only")
        SwitchDesktop(direction)
        return
    }
    target := GetTargetDesktop(direction, &wrapped)
    if (target < 0)
        return
    if (Vda("MoveWindowToDesktopNumber", "Ptr", hwnd, "Int", target, "Int") = -1) {
        DebugLog("move: MoveWindowToDesktopNumber failed")
        ShowTip("This window could not be moved." (A_IsAdmin ? "" : "`nElevated windows require Admin Mode."))
        return
    }
    Vda("GoToDesktopNumber", "Int", target, "Int")
    try WinActivate(hwnd)
    DebugLog("move: -> desktop " (target + 1) (wrapped ? " (wrapped)" : ""))
    ShowOsdForDesktop(target)
}

; Path selection only depends on "who owns the foreground"
SwitchDesktop(direction) {
    target := GetTargetDesktop(direction, &wrapped)
    if (target < 0)
        return
    flyout := IsShellFlyout(WinExist("A"))
    if (flyout && !wrapped) {
        DebugLog("switch: native keys (flyout open) -> desktop " (target + 1))
        Send(direction = "right" ? "^#{Right}" : "^#{Left}")
        RequestOsdCheck()
    } else {
        if flyout
            CloseShellFlyout()
        DebugLog("switch: API + taskbar trick -> desktop " (target + 1) (wrapped ? " (wrapped)" : ""))
        GoToDesktopWithoutFlashing(target)
    }
}

; Foreground to the taskbar before switching, then the Explorer activates the target window on the next desktop (with fallbacks)
GoToDesktopWithoutFlashing(target) {
    taskbar := WinExist("ahk_class Shell_TrayWnd")
    if taskbar {
        try WinActivate(taskbar)
        WinWaitActive(taskbar,, 0.25)
    }
    Vda("GoToDesktopNumber", "Int", target, "Int")
    ShowOsdForDesktop(target)
    WaitForSwitchSettled(target, taskbar)
}

; Wait for max SWITCH_SETTLE_MS so fast presses are queued until this switch has finished (Explorer own activation)
WaitForSwitchSettled(target, taskbar) {
    start := A_TickCount
    while (A_TickCount - start < SWITCH_SETTLE_MS) {
        fg := WinExist("A")
        if (fg && fg != taskbar && !IsShellWindow(fg)
            && Vda("IsWindowOnDesktopNumber", "Ptr", fg, "Int", target, "Int") = 1) {
            DebugLog("settle: Explorer activated " FgInfo() " after " (A_TickCount - start) " ms")
            return
        }
        Sleep 15
    }
    if (Vda("GetCurrentDesktopNumber", "Int") != target) {
        DebugLog("settle: desktop is not " (target + 1) " anymore -> no activation")
        return
    }
    hwnd := GetForemostWindowOnDesktop(target)
    if !hwnd {
        DebugLog("settle: target desktop empty -> taskbar keeps focus")
        return
    }
    loop 10 {
        if !IsCloaked(hwnd)
            break
        Sleep 15
    }
    if IsCloaked(hwnd) {
        DebugLog("settle: window still cloaked -> no activation (avoids flash)")
        return
    }
    try WinActivate(hwnd)
    DebugLog("settle: fallback activated " FgInfo())
}

IsCloaked(hwnd) {
    cloaked := 0
    DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 14, "UInt*", &cloaked, "UInt", 4)
    return cloaked != 0
}

CloseShellFlyout() {
    DebugLog("flyout open (" FgInfo() ") -> Esc")
    Send "{Esc}"
    loop 25 {
        Sleep 20
        if !IsShellFlyout(WinExist("A"))
            return true
    }
    DebugLog("flyout still open after Esc")
    return false
}

IsShellFlyout(hwnd) {
    if !hwnd
        return false
    try {
        cls := WinGetClass(hwnd)
    } catch {
        return false
    }
    return (cls = "Windows.UI.Core.CoreWindow"
         || cls = "NotifyIconOverflowWindow"
         || cls = "TopLevelWindowForOverflowXamlIsland"
         || cls = "Xaml_WindowedPopupClass")
}

IsShellWindow(hwnd) {
    try {
        cls := WinGetClass(hwnd)
    } catch {
        return true
    }
    return (cls = "Shell_TrayWnd" || cls = "Shell_SecondaryTrayWnd" || cls = "Progman" || cls = "WorkerW"
         || cls = "MultitaskingViewFrame" || cls = "XamlExplorerHostIslandWindow"
         || IsShellFlyout(hwnd))
}

GetForemostWindowOnDesktop(desktopNum) {
    for hwnd in WinGetList() {
        try {
            if (WinGetPID(hwnd) = MyPID)
                continue
            if IsShellWindow(hwnd)
                continue
            if (WinGetMinMax(hwnd) = -1)
                continue
            exStyle := WinGetExStyle(hwnd)
            if (exStyle & 0x80) || (exStyle & 0x08000000)
                continue
            if (WinGetTitle(hwnd) = "")
                continue
            cloaked := 0
            DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 14, "UInt*", &cloaked, "UInt", 4)
            if (cloaked & 0x1)
                continue
        } catch {
            continue
        }
        if (Vda("IsWindowOnDesktopNumber", "Ptr", hwnd, "Int", desktopNum, "Int") = 1)
            return hwnd
    }
    return 0
}

; --- Desktop name OSD
CreateOsd() {
    global Osd, OsdText
    Osd := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale")
    Osd.BackColor := OSD_BG
    Osd.MarginX := 0, Osd.MarginY := 0
    Osd.SetFont("s" OSD_FONT_SIZE " c" OSD_FG " Bold", OSD_FONT)
    OsdText := Osd.Add("Text", "x0 y0 Center +0x80", "")
    WinSetExStyle(OSD_CLICKTHROUGH ? "+0x08000020" : "+0x08000000", Osd.Hwnd)
    WinSetTransparent(OSD_OPACITY, Osd.Hwnd)
}

StartOsd() {
    global OsdLastKey := CurrentDesktopKey()
    SetTimer(OsdPoll, OSD_POLL_MS)
}

StopOsd() {
    SetTimer(OsdPoll, 0)
    HideOsd()
}

RequestOsdCheck() {
    if OsdEnabled
        SetTimer(OsdCheckSoon, -120)
}
OsdCheckSoon() {
    OsdPoll()
}

OsdPoll() {
    global OsdLastKey, OsdExpectKey
    guid := CurrentDesktopGuid()
    key  := (guid != "") ? guid : "#" Vda("GetCurrentDesktopNumber", "Int")
    if (key = "#-1")
        return
    if (OsdExpectKey != "") {
        if (key = OsdExpectKey || A_TickCount > OsdExpectUntil)
            OsdExpectKey := ""
        else
            return
    }
    if (key = OsdLastKey)
        return
    OsdLastKey := key
    ShowOsd(DesktopLabel(guid))
}

ShowOsdForDesktop(target) {
    global OsdLastKey, OsdExpectKey, OsdExpectUntil
    if !OsdEnabled
        return
    ids  := DesktopIdList()
    guid := (target >= 0 && target < ids.Length) ? ids[target + 1] : ""
    key  := (guid != "") ? guid : "#" target
    OsdLastKey     := key
    OsdExpectKey   := key
    OsdExpectUntil := A_TickCount + 1500
    ShowOsd(DesktopLabel(guid, target + 1))
}

CurrentDesktopKey() {
    guid := CurrentDesktopGuid()
    return (guid != "") ? guid : "#" Vda("GetCurrentDesktopNumber", "Int")
}

DesktopLabel(guid, knownNum := 0) {
    num := knownNum
    if (!num && guid != "") {
        for i, id in DesktopIdList() {
            if (id = guid) {
                num := i
                break
            }
        }
    }
    if !num
        num := Vda("GetCurrentDesktopNumber", "Int") + 1
    names   := RegistryNameMap()
    rawName := (guid != "" && names.Has(guid)) ? names[guid] : ""
    name    := (rawName != "") ? rawName : (num > 0 ? "Desktop " num : "Desktop")
    if (num > 0 && (OSD_NUMBER_MODE = "always" || (OSD_NUMBER_MODE = "smart" && rawName != "")))
        return num "  " Chr(0xB7) "  " name
    return name
}

ShowOsd(text) {
    if !IsObject(Osd)
        return
    Osd.Destroy()
    CreateOsd()
    OsdText.Value := text
    m := MeasureOsdText(text)
    w := m.W + OSD_PAD_X * 2
    h := m.H + OSD_PAD_Y * 2
    MonitorGetWorkArea(ResolveOsdMonitor(), &L, &T, &R, &B)

    if (OSD_SIDE = "right")
        x := R - w - OSD_MARGIN_X
    else if (OSD_SIDE = "left")
        x := L + OSD_MARGIN_X
    else
        x := (L + R) // 2 - w // 2

    if (OSD_EDGE = "top")
        y := T + OSD_MARGIN_Y
    else if (OSD_EDGE = "center")
        y := (T + B) // 2 - h // 2
    else
        y := B - h - OSD_MARGIN_Y

    OsdText.Move(0, 0, w, h)
    
    Osd.Show("x" x " y" y " w" w " h" h " NoActivate")

    DllCall("SetWindowPos", "Ptr", Osd.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x13)
    global OsdLastText := text
    SetTimer(OsdVerify, -150)
    SetTimer(HideOsd, -OSD_DURATION)
    DebugLog("osd: show '" text "' | fg=" FgInfo())
}

OsdVerify() {
    if !IsObject(Osd) || !DllCall("IsWindowVisible", "Ptr", Osd.Hwnd)
        return
    if !IsCloaked(Osd.Hwnd)
        return
    DebugLog("osd: window cloaked (wrong desktop) -> recreate")
    Osd.Destroy()
    CreateOsd()
    OsdText.Value := OsdLastText
    m := MeasureOsdText(OsdLastText)
    w := m.W + OSD_PAD_X * 2, h := m.H + OSD_PAD_Y * 2
    MonitorGetWorkArea(ResolveOsdMonitor(), &L, &T, &R, &B)
    x := (OSD_SIDE = "right") ? R - w - OSD_MARGIN_X : (OSD_SIDE = "left") ? L + OSD_MARGIN_X : (L + R) // 2 - w // 2
    y := (OSD_EDGE = "top") ? T + OSD_MARGIN_Y : (OSD_EDGE = "center") ? (T + B) // 2 - h // 2 : B - h - OSD_MARGIN_Y
    OsdText.Move(0, 0, w, h)
    Osd.Show("x" x " y" y " w" w " h" h " NoActivate")
    DllCall("SetWindowPos", "Ptr", Osd.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x13)
}

HideOsd() {
    if IsObject(Osd)
        Osd.Hide()
}

; Measures with the label's own font, so that the result are identical to what is drawn
MeasureOsdText(text) {
    hFont := DllCall("SendMessage", "Ptr", OsdText.Hwnd, "UInt", 0x31, "Ptr", 0, "Ptr", 0, "Ptr")
    hDC   := DllCall("GetDC", "Ptr", 0, "Ptr")
    old   := DllCall("SelectObject", "Ptr", hDC, "Ptr", hFont, "Ptr")
    rect  := Buffer(16, 0)
    DllCall("DrawTextW", "Ptr", hDC, "WStr", text, "Int", -1, "Ptr", rect, "UInt", 0xC00)
    DllCall("SelectObject", "Ptr", hDC, "Ptr", old, "Ptr")
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)
    return {W: NumGet(rect, 8, "Int"), H: NumGet(rect, 12, "Int")}
}

ResolveOsdMonitor() {
    if IsInteger(OSD_MONITOR)
        return (OSD_MONITOR >= 1 && OSD_MONITOR <= MonitorGetCount()) ? OSD_MONITOR : MonitorGetPrimary()
    if (OSD_MONITOR = "M") {
        CoordMode "Mouse", "Screen"
        MouseGetPos(&mx, &my)
        return MonitorFromPoint(mx, my)
    }
    if (OSD_MONITOR = "A") {
        try {
            WinGetPos(&wx, &wy, &ww, &wh, "A")
            return MonitorFromPoint(wx + ww // 2, wy + wh // 2)
        }
    }
    return MonitorGetPrimary()
}

MonitorFromPoint(px, py) {
    loop MonitorGetCount() {
        MonitorGet(A_Index, &L, &T, &R, &B)
        if (px >= L && px < R && py >= T && py < B)
            return A_Index
    }
    return MonitorGetPrimary()
}

; Registry (names + change detection, DLL-independent)
BinToHex(v) {
    if IsObject(v) {
        s := ""
        loop v.Size
            s .= Format("{:02X}", NumGet(v, A_Index - 1, "UChar"))
        return s
    }
    return StrReplace(StrReplace(StrUpper(Trim(v)), "0X"), " ")
}

RawGuidToStandard(hex) {
    return SubStr(hex, 7, 2) SubStr(hex, 5, 2) SubStr(hex, 3, 2) SubStr(hex, 1, 2)
         . SubStr(hex, 11, 2) SubStr(hex, 9, 2)
         . SubStr(hex, 15, 2) SubStr(hex, 13, 2)
         . SubStr(hex, 17, 16)
}

CurrentDesktopGuid() {
    sid := 1
    DllCall("ProcessIdToSessionId", "UInt", MyPID, "UInt*", &sid)
    sessionPath := "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\" sid "\VirtualDesktops"
    paths := IsWin10 ? [sessionPath, VD_ROOT] : [VD_ROOT, sessionPath]
    for p in paths {
        try {
            hex := BinToHex(RegRead(p, "CurrentVirtualDesktop"))
            if (StrLen(hex) = 32)
                return RawGuidToStandard(hex)
        }
    }
    return ""
}

DesktopIdList() {
    ids := []
    try {
        raw := BinToHex(RegRead(VD_ROOT, "VirtualDesktopIDs"))
        loop (StrLen(raw) // 32)
            ids.Push(RawGuidToStandard(SubStr(raw, (A_Index - 1) * 32 + 1, 32)))
    }
    return ids
}

RegistryNameMap() {
    m := Map()
    desktops := VD_ROOT "\Desktops"
    loop reg, desktops, "K" {
        try {
            n := RegRead(desktops "\" A_LoopRegName, "Name")
        } catch {
            continue
        }
        if (n != "")
            m[StrUpper(StrReplace(StrReplace(StrReplace(A_LoopRegName, "{"), "}"), "-"))] := n
    }
    return m
}

; --- Hotkeys
; Ctrl + Shift + Win + Right/Left  (move window)
+^#Right:: HotkeyAction(MoveWindowToDesktop, "right", "Right")
+^#Left::  HotkeyAction(MoveWindowToDesktop, "left",  "Left")

; Ctrl + Shift + Alt + Right/Left  (move window, alternative)
+^!Right:: HotkeyAction(MoveWindowToDesktop, "right", "Right")
+^!Left::  HotkeyAction(MoveWindowToDesktop, "left",  "Left")

; Ctrl + Alt + Right/Left  (switch desktop, alternative)
^!Right::  HotkeyAction(SwitchDesktop, "right", "Right")
^!Left::   HotkeyAction(SwitchDesktop, "left",  "Left")

; Ctrl + Win + Right/Left (native only if cycling is disabled)
#HotIf CyclingEnabled
^#Right::  HotkeyAction(SwitchDesktop, "right", "Right")
^#Left::   HotkeyAction(SwitchDesktop, "left",  "Left")
#HotIf
