# Vendored VirtualDesktopAccessor DLLs

Third-party VirtualDesktopAccessor (VDA) DLLs used by Move Window Between Desktops.
Upstream: https://github.com/Ciantic/VirtualDesktopAccessor (MIT License, Jari Pennanen)

All four DLLs are shipped (installer and portable zip, folder `vda\`). The app selects the matching 
one **at startup** from the Windows build number, so a Windows feature update picks the new DLL 
(if available) automatically. A `VirtualDesktopAccessor.dll` placed next to the exe overrides this selection.

| File | Selected for | Upstream release | Notes |
|------|--------------|------------------|-------|
| `VirtualDesktopAccessor_Win10.dll` | build < 22000 (Windows 10, incl. LTSC/IoT LTSC) | [`2019-windows10`](https://github.com/Ciantic/VirtualDesktopAccessor/releases/tag/2019-windows10) | final Win10 release |
| `VirtualDesktopAccessor_Win11_Legacy.dll` | 22000 ≤ build < 22631 | [`2023-11-10-windows11`](https://github.com/Ciantic/VirtualDesktopAccessor/releases/tag/2023-11-10-windows11) | upstream: requires ≥ 22621.2215; Win11 21H2 (22000) not supported |
| `VirtualDesktopAccessor_Win11_23H2.dll` | 22631 ≤ build < 26100 | [`2024-01-25-windows11`](https://github.com/Ciantic/VirtualDesktopAccessor/releases/tag/2024-01-25-windows11) | 23H2 |
| `VirtualDesktopAccessor_Win11_24H2.dll` | build ≥ 26100 | [`2024-12-16-windows11`](https://github.com/Ciantic/VirtualDesktopAccessor/releases/tag/2024-12-16-windows11) | upstream: requires ≥ 26100.2605; fallback for all newer builds |

Each file is the upstream `VirtualDesktopAccessor.dll` of that release, renamed (renaming does not change the hash).


## Requirements

The DLLs need the **Microsoft Visual C++ Redistributable (x64)**. Without it, loading fails withWindows error 126. 
The installer checks for it; the WinGet manifest declares it as a dependency.


## Checksums

`SHA256SUMS` is checked by `build.ps1` and aborts if any DLL does not match.

```bash
Get-FileHash .\vendor\VirtualDesktopAccessor_Win11_24H2.dll -Algorithm SHA256
```


## Adding a DLL for a new Windows version

1. Download `VirtualDesktopAccessor.dll` from the new upstream release, rename it
   (`VirtualDesktopAccessor_Win11_<version>.dll`), and place it here.
2. Add its line to `SHA256SUMS`.
3. Add a branch to `GetVdaDllPath()` (new build range; newest DLL stays the `else` fallback).
4. Add a row to the table above.
5. Test on that Windows version, then add a CHANGELOG entry ("Added: support for Windows 11 <version>").

License notices: see `THIRD-PARTY-NOTICES.txt` in the repository root.
