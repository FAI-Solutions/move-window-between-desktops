#Requires AutoHotkey v2.0
#SingleInstance Force

; Move Window Between Desktops (homepage and repository)
; https://fai-solutions.codeberg.page/move-window-between-desktops/
; https://codeberg.org/FAI-Solutions/move-window-between-desktops
; ---------------------------------------------------------------
; Features:
;   - Move active window to next/previous virtual desktop:
; Ctrl+Shift+Alt+Arrow-Right/Left or Ctrl+Shift+Win+Arrow-Right/Left
;   - Switch to next/previous virtual desktop:
; Ctrl+Win+Arrow-Right/Left (native) or Ctrl+Alt+Arrow-Right/Left (added) 
;   - custom Tray menu with custom icon

; Version Info
global ScriptVersion := "1.3"
global ScriptName := "Move Window Between Desktops"
global ScriptURL := "https://codeberg.org/FAI-Solutions/move-window-between-desktops"

; Use custom icon if available, otherwise use default AHK icon
if FileExist(A_ScriptDir "\app_icon.ico") {
    TraySetIcon(A_ScriptDir "\app_icon.ico")
}

; Tray Menu Setup
SetupTrayMenu()

; Request admin privileges to move windows with elevated privileges (example: Task Manager)
if not A_IsAdmin {
    try {
        Run '*RunAs "' A_ScriptFullPath '"'
        ExitApp
    } catch {
        A_IconTip := ScriptName " v" ScriptVersion " (User Mode)`nElevated windows cannot be moved"
    }
} else {
    A_IconTip := ScriptName " v" ScriptVersion " (Admin Mode)"
}

SendMode "Input"

; Load VirtualDesktopAccessor DLL
hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", A_ScriptDir "\VirtualDesktopAccessor.dll")
if (!hVirtualDesktopAccessor) {
    MsgBox "Failed to load VirtualDesktopAccessor.dll!`n`nPlease ensure the DLL is in the same folder as this script.", "Error", 16
    ExitApp
}

; FUNCTIONS
SetupTrayMenu() {
    ; Remove default menu items
    A_TrayMenu.Delete()

    ; Add custom menu items
    A_TrayMenu.Add("Open Repository", OpenWebsite)
    A_TrayMenu.Add("View Shortcuts", ShowShortcuts)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Reload Script", ReloadScript)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", ExitScript)

    ; Set default action (double-click)
    A_TrayMenu.Default := "View Shortcuts"
}

OpenWebsite(*) {
    Run ScriptURL
}

ShowShortcuts(*) {
    shortcutsText := ""
    . "Move Window across virtual Desktops:`n"
    . "  Ctrl + Shift + Win + Right`n"
    . "  Ctrl + Shift + Win + Left`n`n"
    . "alternative Move Window across virtual Desktops:`n"
    . "  Ctrl + Shift + Alt + Right`n"
    . "  Ctrl + Shift + Alt + Left`n`n"
    . "Switch virtual Desktops (native):`n"
    . "  Ctrl + Win + Right`n"
    . "  Ctrl + Win + Left`n`n"
    . "Switch virtual Desktops (alternative):`n"
    . "  Ctrl + Alt + Right`n"
    . "  Ctrl + Alt + Left`n`n"
    . "Note: Elevated windows (example: Task Manager) can only be moved, when running as Administrator."

    MsgBox shortcutsText, ScriptName " v" ScriptVersion " - Keyboard Shortcuts", 64
}

ReloadScript(*) {
    Reload
}

ExitScript(*) {
    ExitApp
}

MoveWindowToDesktop(direction) {
    activeWindow := WinGetID("A")
    if (!activeWindow) {
        return
    }

    currentDesktop := DllCall(A_ScriptDir "\VirtualDesktopAccessor.dll\GetCurrentDesktopNumber")

    if (direction = "right") {
        targetDesktop := currentDesktop + 1
    } else if (direction = "left") {
        targetDesktop := currentDesktop - 1
    } else {
        return
    }

    ; Move window to target desktop
    DllCall(A_ScriptDir "\VirtualDesktopAccessor.dll\MoveWindowToDesktopNumber", "UInt", activeWindow, "UInt", targetDesktop)

    ; Allow foreground window change to prevent flashing
    DllCall("User32\AllowSetForegroundWindow", "Int", -1)
    ; Follow to the target desktop
    DllCall(A_ScriptDir "\VirtualDesktopAccessor.dll\GoToDesktopNumber", "UInt", targetDesktop)
}

SwitchDesktop(direction) {
    currentDesktop := DllCall(A_ScriptDir "\VirtualDesktopAccessor.dll\GetCurrentDesktopNumber")

    if (direction = "right") {
        targetDesktop := currentDesktop + 1
    } else if (direction = "left") {
        targetDesktop := currentDesktop - 1
    } else {
        return
    }

    ; Allow foreground window change to prevent flashing
    DllCall("User32\AllowSetForegroundWindow", "Int", -1)
    ; Switch to target desktop (without moving window)
    DllCall(A_ScriptDir "\VirtualDesktopAccessor.dll\GoToDesktopNumber", "UInt", targetDesktop)
}

; HOTKEYS
; Ctrl + Shift + Win + Right/Left
+^#Right:: MoveWindowToDesktop("right")
+^#Left::  MoveWindowToDesktop("left")

; Ctrl + Shift + Alt + Right/Left
+^!Right:: MoveWindowToDesktop("right")
+^!Left::  MoveWindowToDesktop("left")

; Ctrl + Alt + Right/Left
^!Right:: SwitchDesktop("right")
^!Left::  SwitchDesktop("left")
