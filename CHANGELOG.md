# Changelog

All notable changes to this project are documented in this file. Version 1.0, 1.1, 1.2 were distributed on Codeberg before this repository existed.


## [Unreleased]


## [1.4] - 2026-10-26

### Added
- Desktop cycling (switching between last ↩ ↪ first desktop), toggle in tray menu (off by default).
- Desktop name display when switching desktops (on by default on Windows 10, off on Windows 11).
- Watchdog task: restarts the utility after unlock, user switch or resume from sleep/hibernation if it is not running.
- Better persistence: a keyboard hook after resume/unlock; automatic reload after an Explorer restart.
- Debug logging, toggle in tray menu (easy to activate and copy if there are problems).

### Changed
- Issues can be handled on both repositories (Codeberg and GitHub).
- Holding a hotkey now performs one action per key press instead of auto-repeating (v1.3 behavior).
- Autostart tasks reworked (default Windows limitation removed).
- Settings are stored in `%AppData%\MoveWindowBetweenDesktops\settings.ini`.
- Fully automated build and release process via GitHub Actions.
- Improved error messages.
- Using changelog.md in addition to release notes.

### Fixed
- Taskbar buttons flashing / windows appearing on the wrong desktop in the taskbar when switching with `Ctrl + Alt + Arrow`.
- Switching desktops while the Start menu or Action Center is open.
- Error when a hotkey was pressed while no window was active.

### Removed
- Separate portable `*.exe` files (replaced by a proper portable ZIP).
- Option to install via Scoop.


## [1.3] - 2026-03-20

### Added
- One-click offline setup installer with improved silent installation support (winget)
- Additional alternative hotkeys
- System tray menu (includes hotkey information)
- Custom icon

### Changed
- Improved documentation


## 1.2 - 2026-03-13

### Added
- Added a one click installation `move-window-between-desktops_setup.exe` option.
- Added the option to install via Scoop:
    ```
    # Add the repository (admin rights)
    scoop bucket add fai-solutions https://codeberg.org/FAI-Solutions/scoop-bucket
    # Install
    scoop install move-window-between-desktops
    ```

### Fixed
- Minor improvements


## 1.1 - 2026-03-02

### Added
- Active Windows with elevated privileges can be moved across virtual Desktops (if script is running with admin rights).
- One-Click Autostart Setup Helper that handles everything including proper privilege elevation.

### Fixed
- In v1.0 Windows with elevated privileges would just snap to the side.


## 1.0 - 2026-02-26

### Added
- Initial public release of move-window-between-desktops.


[Unreleased]: https://github.com/FAI-Solutions/move-window-between-desktops/compare/v1.4...HEAD
[1.4]: https://github.com/FAI-Solutions/move-window-between-desktops/compare/v1.3...v1.4
[1.3]: https://github.com/FAI-Solutions/move-window-between-desktops/releases/tag/v1.3