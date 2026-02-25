# MoveWindowVDesk

Move your active window to the next or previous virtual desktop on **Windows 10/11** — with a single keyboard shortcut. A feature Microsoft should have built in ages ago.

Built with [AutoHotkey v2](https://www.autohotkey.com/) and [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor).

---

## Keyboard Shortcuts

| Shortcut                 | Action                                               |
| --------------------------| ------------------------------------------------------|
| `Ctrl + Shift + Win + →` | Move active window **right** to the next desktop     |
| `Ctrl + Shift + Win + ←` | Move active window **left**  to the previous desktop |



## Requirements

- Windows 10 or 11
- [AutoHotkey v2.0](https://www.autohotkey.com/download/ahk-v2.exe)
- [VirtualDesktopAccessor.dll](https://github.com/Ciantic/VirtualDesktopAccessor/releases) — pick the version matching your Windows build

> **Tip**: To find your Windows build: *Settings → System → About* → look for "*OS build*"



## Installation

1. Install **AutoHotkey v2**
2. Download the correct **VirtualDesktopAccessor.dll** for your Windows build
3. Place **both** `MoveWindowVDesk.ahk` and `VirtualDesktopAccessor.dll` in the **same folder**
4. Double-click the `.ahk` script - you should see an AHK icon appear in the tray, indicating the script is running.


6. To have the **script launch automatically on Windows start**, press `Win + R`, paste the following search querry and press Enter:
   ```
   %AppData%\Microsoft\Windows\Start Menu\Programs\Startup
   ```
6. In the Autostart folder right-click an empty spot → **New → Shortcut**
7. Paste the full path to the script, (this is an example, replace it with your real path):
   ```
   C:\path\to\your\MoveWindowVDesk.ahk
   ```
8. Click **Finish** — the script will now start with Windows



## Troubleshooting

If the script stop working after a major Windows update:

1. Check if AHK icon still appears in the tray (the `.ahk` file might be blocked by Windows Defender)
2. Check for a newer **VirtualDesktopAccessor.dll** at the [releases page](https://github.com/Ciantic/VirtualDesktopAccessor/releases) — Windows updates can break the DLL
3. Check this repository for an updated script version
4. [Open an issue](../../issues) and describe your problem (include your Windows build number)

---

## License

[MIT](LICENSE)



## Credits & Thanks

- [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor) by Jari Pennanen (MIT License)
