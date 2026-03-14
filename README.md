# [move-window-between-desktops](https://fai-solutions.codeberg.page/move-window-between-desktops/)

Windows 10 and 11 let you switch between virtual desktops using Ctrl+Win+Arrow, but they lack a built-in shortcut to move the currently active window to another desktop. This script fills that gap by allowing you to move your active window to the next or previous virtual desktop on Windows 10 / 11 with a single keyboard shortcut  - a feature Microsoft should have included long ago.

Built with [AutoHotkey v2](https://www.autohotkey.com/) and [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor).

---

## Keyboard Shortcuts

| Shortcut                 | Action                                               |
| --------------------------| ------------------------------------------------------|
| `Ctrl + Shift + Win + →` | Move active window **right** to the next desktop     |
| `Ctrl + Shift + Win + ←` | Move active window **left**  to the previous desktop |



## Requirements

- Windows 10 or 11
- [AutoHotkey v2.0](https://www.autohotkey.com/)
- [VirtualDesktopAccessor.dll](https://github.com/Ciantic/VirtualDesktopAccessor/releases) — pick the version matching your Windows build

> **Tip**: To find your Windows build: *Settings → System → About* → look for "*OS build*"



## Installation

1. Download and install [AutoHotkey v2.0](https://www.autohotkey.com/download/ahk-v2.exe)
2. Download both [move-window-between-desktops.ahk & setup-autostart.ahk](https://codeberg.org/FAI_Solutions/move-window-between-desktops/releases/latest)
3. Download the correct [VirtualDesktopAccessor.dll](https://github.com/Ciantic/VirtualDesktopAccessor/releases) for your Windows build (see requirements)
4. Place **all three** files `move-window-between-desktops.ahk`, `setup-autostart.ahk` and `VirtualDesktopAccessor.dll` in the **same folder**, thus your folder structure should look like that:
```
   📁 MoveWindowBetweenDesktops/
   ├── move-window-between-desktops.ahk
   ├── setup-autostart.ahk
   └── VirtualDesktopAccessor.dll
```
5. Double-click the `setup-autostart.ahk` script (it will ask for elevated privilege) and automatically configure a scheduled task so that with every Windows start the `move-window-between-desktops.ahk` will be loaded. Furthermore it will offer to start `move-window-between-desktops.ahk`.



## Troubleshooting

### Windows Defender SmartScreen blocks the script

When you download `.ahk` files from the internet, Windows may flag them as
untrusted. You will see a SmartScreen popup saying "Windows protected your PC."

**Fix:** Right-click each downloaded `.ahk` file → select **Properties** →
at the bottom of the General tab, check the **Unblock** checkbox → click
**Apply**. Do this for both `move-window-between-desktops.ahk` and
`setup-autostart.ahk` before running them.


### The script stops working after a major Windows update

1. Check if the AHK icon still appears in the system tray — the `.ahk` file
   might have been blocked by Windows Defender after the update.
2. A Windows update can break the DLL. Check for a newer
   **VirtualDesktopAccessor.dll** at the
   [releases page](https://github.com/Ciantic/VirtualDesktopAccessor/releases)
   that matches your new Windows build number.
3. Check this repository for an updated version of the script.
4. [Open an issue](https://codeberg.org/FAI_Solutions/move-window-between-desktops/issues)
   and describe your problem (include your Windows build number).


### Nothing happens when I press the keyboard shortcut

1. Make sure AutoHotkey **v2** is installed (not v1 — they are incompatible).
2. Confirm all three files are in the **same folder** (see Installation).
3. Verify that your `VirtualDesktopAccessor.dll` matches your Windows build
   number. To find your build: *Settings → System → About* → look for
   *"OS build"*.
4. Try running `move-window-between-desktops.ahk` directly by double-clicking
   it. If it shows an error, the message will tell you what is wrong.


### The script cannot move certain windows (example: Task Manager)

Some windows run with elevated (administrator) privileges. The script needs
matching privileges to move them. Run `setup-autostart.ahk` and grant the
administrator permission when prompted. See the
[v1.2 release notes](https://codeberg.org/FAI_Solutions/move-window-between-desktops/releases/tag/v1.2)
for details — if you decline admin rights, the script will still work for
non-elevated windows.

---

## License

[MIT](LICENSE)



## Contact

Developers:

- [Johannes Faber](https://codeberg.org/FAI_Solutions) &nbsp; — &nbsp; [fais.udder466@passinbox.com](mailto:fais.udder466@passinbox.com)



## Acknowledgements

- [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor) by Jari Pennanen (MIT License)
