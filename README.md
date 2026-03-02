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

**• latest version**
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
6. Double-click the `setup-autostart.ahk` script (it will ask for elevated privilege) and automatically configure a scheduled task so that with every Windows start the `move-window-between-desktops.ahk` will be loaded. Furthermore it will offer to start `move-window-between-desktops.ahk`, after it is started an AHK icon will appear in the tray.

**• v1.0 (use this version only if you have no administrator rights)**
1. Download and install [AutoHotkey v2.0](https://www.autohotkey.com/download/ahk-v2.exe)
2. Download [move-window-between-desktops.ahk v1.0](https://codeberg.org/FAI_Solutions/move-window-between-desktops/releases/tag/v1.0)
3. Download the correct [VirtualDesktopAccessor.dll](https://github.com/Ciantic/VirtualDesktopAccessor/releases) for your Windows build (see requirements)
4. Place **both** `move-window-between-desktops.ahk` and `VirtualDesktopAccessor.dll` in the **same folder**
5. Double-click the `move-window-between-desktops.ahk` script - you should see an AHK icon appear in the tray, indicating the script is running.
8. To have the **script launch automatically on Windows start**, press `Win + R`, paste the following search query and press Enter:
   ```
   %AppData%\Microsoft\Windows\Start Menu\Programs\Startup
   ```
9. In the Autostart folder right-click an empty spot `→ New → Shortcut`
10. Paste the full path to the script. **Tip**: hold `Shift` while `right-clicking` the `move-window-between-desktops.ahk` script `→ Copy as path`
11. Click **Finish** — the script will now start with Windows



## Troubleshooting

If the script stops working after a major Windows update:

1. Check if AHK icon still appears in the tray (the `.ahk` file might be blocked by Windows Defender)
2. Check for a newer **VirtualDesktopAccessor.dll** at the [releases page](https://github.com/Ciantic/VirtualDesktopAccessor/releases) — Windows updates can break the DLL
3. Check this repository for an updated version
4. [Open an issue](/FAI_Solutions/move-window-between-desktops/issues) and describe your problem (include your Windows build number)

---

## License

[MIT](LICENSE)



## Contact

Developers:

- [Johannes Faber](https://codeberg.org/FAI_Solutions) &nbsp; — &nbsp; [fais.udder466@passinbox.com](mailto:fais.udder466@passinbox.com)



## Acknowledgements

- [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor) by Jari Pennanen (MIT License)


