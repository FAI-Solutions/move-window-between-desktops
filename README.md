# move-window-between-desktops

Move your active window to the next or previous virtual desktop on **Windows 10 / 11** with a single keyboard shortcut - a feature Microsoft should have included long ago.

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
2. Download [move-window-between-desktops.ahk](https://codeberg.org/FAI_Solutions/MoveWindowVDesk/releases/latest) 
3. Download the correct [VirtualDesktopAccessor.dll](https://github.com/Ciantic/VirtualDesktopAccessor/releases) for your Windows build (see requirements)
4. Place **both** `move-window-between-desktops.ahk` and `VirtualDesktopAccessor.dll` in the **same folder**
5. Double-click the `move-window-between-desktops.ahk` script - you should see an AHK icon appear in the tray, indicating the script is running.
6. To have the **script launch automatically on Windows start**, press `Win + R`, paste the following search querry and press Enter:
   ```
   %AppData%\Microsoft\Windows\Start Menu\Programs\Startup
   ```
7. In the Autostart folder right-click an empty spot `→ New → Shortcut`
8. Paste the full path to the script. **Tip**: hold `Shift` while `right-clicking` the `MoveWindowVDesk.ahk` script `→ Copy as path`
9. Click **Finish** — the script will now start with Windows



## Troubleshooting

If the script stop working after a major Windows update:

1. Check if AHK icon still appears in the tray (the `.ahk` file might be blocked by Windows Defender)
2. Check for a newer **VirtualDesktopAccessor.dll** at the [releases page](https://github.com/Ciantic/VirtualDesktopAccessor/releases) — Windows updates can break the DLL
3. Check this repository for an updated version
4. [Open an issue](/FAI_Solutions/move-window-between-desktops/issues) and describe your problem (include your Windows build number)

---

## License

[MIT](LICENSE)



## Contact

[Johannes Faber](https://codeberg.org/FAI_Solutions) &nbsp; — &nbsp; fais.udder466@passinbox.com



## Acknowledments

- [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor) by Jari Pennanen (MIT License)


