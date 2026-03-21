# [Move Window Between Desktops](https://fai-solutions.codeberg.page/move-window-between-desktops/)

Windows 10 and 11 let you switch between virtual desktops using `Ctrl + Win + Arrow`, but they lack a built-in shortcut to move the currently active window to another desktop. This lightweight utility fills that gap by allowing you to move your active window to the next or previous virtual desktop with a single keyboard shortcut — a feature Microsoft should have included long ago.

---

## Keyboard Shortcuts

### Move Window Across Virtual Desktops

| Shortcut | Action |
|----------|--------|
| `Ctrl + Shift + Win + →` | Move window to next desktop (Windows style) |
| `Ctrl + Shift + Win + ←` | Move window to previous desktop (Windows style) |
| `Ctrl + Shift + Alt + →` | Move window to next desktop (alternative style) |
| `Ctrl + Shift + Alt + ←` | Move window to previous desktop (alternative style) |


### Switch Virtual Desktops

| Shortcut | Action |
|----------|--------|
| `Ctrl + Win + →` | Switch to next desktop (native Windows) |
| `Ctrl + Win + ←` | Switch to previous desktop (native Windows) |
| `Ctrl + Alt + →` | Switch to next desktop (alternative style) |
| `Ctrl + Alt + ←` | Switch to previous desktop (alternative style) |



## Installation Options

### Ⅰ) Setup-Installer (Recommended)

Download the `move-window-between-desktops-setup.exe` from the [releases page](https://codeberg.org/FAI-Solutions/move-window-between-desktops/releases/latest), double-click the setup installer and follow the on-screen instructions.
- Automatically configures Task Scheduler to launch the utility at every user login
- Supports automatic updates via winget — **coming soon**


### Ⅱ) Portable EXE

Download `move-window-between-desktops.exe` and `setup-autostart.exe` (a helper utility that configures Task Scheduler) from the [releases page](https://codeberg.org/FAI-Solutions/move-window-between-desktops/releases/latest):
- No installation required
- Run directly from any folder
- Requires `VirtualDesktopAccessor.dll` in same folder — download the correct version from  [Ciantic's release page](https://github.com/Ciantic/VirtualDesktopAccessor/releases) for your Windows build (*Settings → System → About → look for "OS build"*)


### Ⅲ) AutoHotkey Scripts

#### Manual Install

1. Download and install [AutoHotkey v2](https://www.autohotkey.com/download/ahk-v2.exe) (if not already installed)
2. Download (*right-click → "Save link as"*) the following files: [move-window-between-desktops.ahk](https://codeberg.org/FAI-Solutions/move-window-between-desktops/releases/download/v1.3/move-window-between-desktops.ahk) , [setup-autostart.ahk](https://codeberg.org/FAI-Solutions/move-window-between-desktops/releases/download/v1.3/setup-autostart.ahk)
3. Find and download the matching `VirtualDesktopAccessor.dll` for your Windows build (*Settings → System → About → check "OS build"*) from [VirtualDesktopAccessor's release page](https://github.com/Ciantic/VirtualDesktopAccessor/releases)
4. Place all three files together, as shown below:
```
📁 MoveWindowBetweenDesktops/
├── move-window-between-desktops.ahk  (main script)
├── setup-autostart.ahk               (autostart configuration)
└── VirtualDesktopAccessor.dll        (Windows API bridge)
```
4. **Run setup-autostart.ahk as Administrator** — this sets up autostart and launches the script
5. (Optional) add a custom icon named `app_icon.ico` to the same folder — the script will automatically update the tray icon

#### Command line install via Scoop

Open pwsh.exe with admin rights, add the bucket and install by typing:
```
scoop bucket add fai-solutions https://codeberg.org/FAI-Solutions/scoop-bucket
scoop install move-window-between-desktops
```


## Troubleshooting

### Windows Defender SmartScreen Warning

If you see a SmartScreen warning (this is normal for new software):
1. Click **More info**
2. Click **Run anyway**


### Windows Defender SmartScreen blocks the script

When you download `.ahk` files from the internet, Windows may flag them as
untrusted. You might see a SmartScreen popup stating “Windows protected your PC”.

1.  Right-click each downloaded `.ahk` file → select **Properties** →
at the bottom of the General tab, check the **Unblock** checkbox → click
**Apply**
2. Do this for both `move-window-between-desktops.ahk` and
`setup-autostart.ahk` before running them


### The application stops working after a major Windows update

1. Check if the icon still appears in the system tray
2. A Windows update may require a new DLL version — check [releases](https://codeberg.org/FAI-Solutions/move-window-between-desktops/releases) for updates
3. [Open an issue](https://codeberg.org/FAI-Solutions/move-window-between-desktops/issues) with your Windows build number


### Cannot move elevated windows (example: Task Manager)

Run the application as Administrator. The installer can configure this automatically via scheduled task.

---

## License

[MIT](LICENSE)



## Contact

- **Developer**: Johannes Faber — [fais.udder466@passinbox.com](mailto:fais.udder466@passinbox.com)
- **Homepage**: https://fai-solutions.codeberg.page/move-window-between-desktops/
- **Issues**: https://codeberg.org/FAI-Solutions/move-window-between-desktops/issues
- **Mirror**: https://github.com/FAI-Solutions/move-window-between-desktops



## Acknowledgements

- [AutoHotkey v2](https://www.autohotkey.com/) — The scripting language that powers this utility. AutoHotkey is a free, open-source scripting language for Windows that allows users to easily create scripts for automating tasks and customizing hotkeys.

- [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor) by Jari Pennanen — The DLL that provides access to Windows' virtual desktop API (MIT License).

- [Code Signing Policy](CODE_SIGNING_POLICY.md) — Code signed by [SignPath.io](https://about.signpath.io), certificate by [SignPath Foundation](https://signpath.org)

---

**Enjoy a feature Microsoft should have included long ago!**
