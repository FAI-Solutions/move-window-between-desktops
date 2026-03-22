#Requires AutoHotkey v2.0
#SingleInstance Force

; Move Window Between Desktops (homepage and repository)
; https://fai-solutions.codeberg.page/move-window-between-desktops/
; https://codeberg.org/FAI-Solutions/move-window-between-desktops
; ---------------------------------------------------------------
; This helper script configures autostart for the main script.
; Run as Administrator for scheduled task (can move elevated windows)
; Run as User for startup folder shortcut (cannot move elevated windows)

; Version Info
global ScriptVersion := "1.3"
global ScriptName := "Move Window Between Desktops - Setup"

; Check for main script
taskName := "MoveWindowBetweenDesktops"
mainScriptName := "move-window-between-desktops.ahk"
mainScriptPath := A_ScriptDir "\" mainScriptName
startupFolder := A_Startup "\" taskName ".lnk"

if !FileExist(mainScriptPath) {
    MsgBox "Could not find '" mainScriptName "' in the same folder as this setup script.`n`nPlease place both scripts in the same folder.", "Error", 16
    ExitApp
}

; Find AutoHotkey executable
ahkExe := ""
if FileExist(A_ProgramFiles "\AutoHotkey\v2\AutoHotkey64.exe") {
    ahkExe := A_ProgramFiles "\AutoHotkey\v2\AutoHotkey64.exe"
} else if FileExist(A_ProgramFiles "\AutoHotkey\v2\AutoHotkey32.exe") {
    ahkExe := A_ProgramFiles "\AutoHotkey\v2\AutoHotkey32.exe"
} else if FileExist(A_ProgramFiles "\AutoHotkey\AutoHotkey64.exe") {
    ahkExe := A_ProgramFiles "\AutoHotkey\AutoHotkey64.exe"
} else if FileExist(A_ProgramFiles "\AutoHotkey\AutoHotkey32.exe") {
    ahkExe := A_ProgramFiles "\AutoHotkey\AutoHotkey32.exe"
}

if (ahkExe = "") {
    MsgBox "Could not find AutoHotkey installation.`n`nPlease install AutoHotkey v2.0 first.", "Error", 16
    ExitApp
}

; Admin check and routing
if A_IsAdmin {
    A_IconTip := ScriptName " v" ScriptVersion " (Admin Mode)"
    SetupScheduledTask()
} else {
    A_IconTip := ScriptName " v" ScriptVersion " (User Mode)"
    try {
        Run '*RunAs "' A_ScriptFullPath '"'
        ExitApp
    } catch {
        SetupStartupFolder()
    }
}

ExitApp

; path I - Admin: scheduled task (runs script elevated)
SetupScheduledTask() {
    global taskName, mainScriptPath, ahkExe, startupFolder

    checkCmd := 'schtasks /Query /TN "' taskName '" 2>nul'
    result := RunWaitOutput(checkCmd)

    if InStr(result, taskName) {
        choice := MsgBox("A scheduled task '" taskName "' already exists.`n`nWould you like to remove it?`n`nYes = Remove task (disable autostart)`nNo = Recreate task`nCancel = Exit", "Task Exists", 3 + 32)

        if (choice = "Yes") {
            RunWait('schtasks /Delete /TN "' taskName '" /F',, "Hide")
            MsgBox "Scheduled task removed successfully!`n`nThe script will no longer start automatically.", "Success", 64
            ExitApp
        } else if (choice = "Cancel") {
            ExitApp
        } else {
            RunWait('schtasks /Delete /TN "' taskName '" /F',, "Hide")
        }
    }

    ; syntax ↓
    ; /SC ONLOGON - Run at logon
    ; /RL HIGHEST - Run with highest privileges (admin)
    ; /F          - Force create (overwrite if exists)
    createCmd := 'schtasks /Create /TN "' taskName '" /TR "\"' ahkExe '\" \"' mainScriptPath '\"" /SC ONLOGON /RL HIGHEST /F'

    try {
        RunWait(createCmd,, "Hide")

        verifyResult := RunWaitOutput('schtasks /Query /TN "' taskName '" 2>nul')

        if InStr(verifyResult, taskName) {
            choice := MsgBox("Scheduled task created successfully!`n`nThe script will now start automatically with administrator privileges when you log in.`n`nWould you like to start the main script now?", "Success", 4 + 64)

            if (choice = "Yes") {
                Run '*RunAs "' ahkExe '" "' mainScriptPath '"'
            }
        } else {
            throw Error("Task verification failed")
        }
    } catch as e {
        MsgBox "Failed to create scheduled task.`n`nError: " e.Message, "Error", 16
    }
}

; path II - not Admin: Startup folder shortcut
SetupStartupFolder() {
    global mainScriptPath, ahkExe, startupFolder, taskName

    if FileExist(startupFolder) {
        choice := MsgBox("A startup shortcut '" taskName "' already exists.`n`nWould you like to remove it?`n`nYes = Remove shortcut (disable autostart)`nNo = Recreate shortcut`nCancel = Exit", "Shortcut Exists", 3 + 32)

        if (choice = "Yes") {
            FileDelete(startupFolder)
            MsgBox "Startup shortcut removed successfully!`n`nThe script will no longer start automatically.", "Success", 64
            ExitApp
        } else if (choice = "Cancel") {
            ExitApp
        } else {
            FileDelete(startupFolder)
        }
    }

    try {
        oShell := ComObject("WScript.Shell")
        oShortcut := oShell.CreateShortcut(startupFolder)
        oShortcut.TargetPath := ahkExe
        oShortcut.Arguments := '"' mainScriptPath '"'
        oShortcut.WorkingDirectory := A_ScriptDir
        oShortcut.Save()

        if FileExist(startupFolder) {
            choice := MsgBox("Startup shortcut created successfully!`n`nNote: Running without administrator rights — elevated windows (example: Task Manager) cannot be moved between desktops.`n`nWould you like to start the main script now?", "Success", 4 + 64)

            if (choice = "Yes") {
                Run '"' ahkExe '" "' mainScriptPath '"'
            }
        } else {
            throw Error("Shortcut verification failed")
        }
    } catch as e {
        MsgBox "Failed to create startup shortcut.`n`nError: " e.Message, "Error", 16
    }
}

; Helper to run commands
RunWaitOutput(cmd) {
    shell := ComObject("WScript.Shell")
    exec := shell.Exec(A_ComSpec ' /C "' cmd '"')
    return exec.StdOut.ReadAll()
}
