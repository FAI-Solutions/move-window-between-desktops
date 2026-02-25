#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"

; !!! Setup Instructions !!!
; Download AutoHotkey v2.0 from: https://www.autohotkey.com/download/ahk-v2.exe
; Download VirtualDesktopAccessor.dll according to your Windows build (check it in Settings>System>About)
; from: https://github.com/Ciantic/VirtualDesktopAccessor/releases
; Place it together with this script in a folder! Double click the script to start it.
; Automate the script starting by adding it to Startup folder by pressing Win+R then enter
; %AppData%\Microsoft\Windows\Start Menu\Programs\Startup
; Press Enter and right click on an empty spot in the folder > New > Shortcut
; Paste the path of the script (for example C:\path\to\your\MoveWindowVDesk_v2.5.ahk )
; With that MoveWindowVDesk_v2.5.ahk will automatically launched on boot.
; Enjoy a feature that should have been added by Microsoft ages ago.

hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", A_ScriptDir "\VirtualDesktopAccessor.dll")

MoveWindowToDesktop(direction) {
    activeWindow := WinGetID("A")
    currentDesktop := DllCall(A_ScriptDir "\VirtualDesktopAccessor.dll\GetCurrentDesktopNumber")
    
    if (direction = "right") {
        targetDesktop := currentDesktop + 1
    } else if (direction = "left") {
        targetDesktop := currentDesktop - 1
    }
    
    DllCall(A_ScriptDir "\VirtualDesktopAccessor.dll\MoveWindowToDesktopNumber", "UInt", activeWindow, "UInt", targetDesktop)
    
    DllCall(A_ScriptDir "\VirtualDesktopAccessor.dll\GoToDesktopNumber", "UInt", targetDesktop)
}

; Executes the move and follow command to right / left virtual desktop
+^#Right:: MoveWindowToDesktop("right")
+^#Left:: MoveWindowToDesktop("left")


; !!! If this script should stop working !!!
; 1) Check if a new VirtualDesktopAccessor.dll is available from https://github.com/Ciantic/VirtualDesktopAccessor/releases
; 2) Check out my repository https://codeberg.org/FAI_Solutions/MoveWindowVDesk for updates
; 3) Report your problem
