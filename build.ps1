<#  Build script for Move Window Between Desktops
    .\build.ps1                     uses installed tools (C:\Program Files\...)
    .\build.ps1 -DownloadTools      downloads pinned tools into .tools\ (CI, forks)
    Output: dist\  (setup exe, portable zip, SHA256SUMS.txt)            #>
param([switch]$DownloadTools)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-Location $PSScriptRoot

# ---- pinned tools --------------------------------------------------------
$Tools = @{
  AutoHotkey = @{ Url='https://github.com/AutoHotkey/AutoHotkey/releases/download/v2.0.28/AutoHotkey_2.0.28.zip'; Sha256='b63be7548792b4ad0dfe424d91cc69376694ed2f758245b7a75a0c77d693b478' }
  Ahk2Exe    = @{ Url='https://github.com/AutoHotkey/Ahk2Exe/releases/download/Ahk2Exe1.1.37.02a2/Ahk2Exe1.1.37.02a2.zip'; Sha256='c29b8c3a5124850d79fc9e66e2ca79677c377d7f31631ad3022ba159c5d9e3be' }
  InnoSetup  = @{ Url='https://github.com/jrsoftware/issrc/releases/download/is-6_7_3/innosetup-6.7.3.exe'; Sha256='9c73c3bae7ed48d44112a0f48e66742c00090bdb5bef71d9d3c056c66e97b732' }
}

function Get-Tool($name, $file) {
  $t = $Tools[$name]; $dest = ".tools\$file"
  for ($try = 1; $try -le 2; $try++) {
    if (-not (Test-Path $dest)) { Invoke-WebRequest $t.Url -OutFile $dest }
    $h = (Get-FileHash $dest -Algorithm SHA256).Hash.ToLower()
    if ($h -eq $t.Sha256.ToLower()) { return $dest }
    Remove-Item $dest -Force
  }
  throw "$name hash mismatch. Got $h - verify the download, then pin it in build.ps1."
}

if ($DownloadTools) {
  New-Item -ItemType Directory .tools -Force | Out-Null
  Expand-Archive (Get-Tool AutoHotkey 'ahk.zip') .tools\ahk -Force
  Expand-Archive (Get-Tool Ahk2Exe 'ahk2exe.zip') .tools\ahk2exe -Force
  if ((Get-Content .tools\inno\pinned.txt -ErrorAction SilentlyContinue) -ne $Tools.InnoSetup.Sha256) {
    Remove-Item .tools\inno -Recurse -Force -ErrorAction SilentlyContinue
    Start-Process (Get-Tool InnoSetup 'inno.exe') -ArgumentList '/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART','/PORTABLE=1',"/DIR=`"$PWD\.tools\inno`"" -Wait
    Set-Content .tools\inno\pinned.txt $Tools.InnoSetup.Sha256
  }

  $AHK = '.tools\ahk\AutoHotkey64.exe'; $A2E = '.tools\ahk2exe\Ahk2Exe.exe'; $ISCC = '.tools\inno\ISCC.exe'
} else {
  $AHK  = "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
  $A2E  = "$env:ProgramFiles\AutoHotkey\Compiler\Ahk2Exe.exe"
  $ISCC = @("${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
            'D:\Program Files (x86)\Inno Setup 6\ISCC.exe') |
          Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $ISCC) { throw 'ISCC.exe not found' }
}
foreach ($p in $AHK,$A2E,$ISCC) { if (-not (Test-Path $p)) { throw "Tool not found: $p" } }
Write-Host ("Tools ({0}):" -f $(if ($DownloadTools) { 'pinned, downloaded' } else { 'installed on this machine' }))
Write-Host "AHK : $AHK"
Write-Host "A2E : $A2E"
Write-Host "ISCC: $ISCC"

# ---- version (source of truth: ScriptVersion in the main script) --------
$m = Select-String -Path src\move-window-between-desktops.ahk -Pattern 'ScriptVersion\s*:=\s*"([^"]+)"' | Select-Object -First 1
if (-not $m) { throw 'ScriptVersion not found' }
$Version = $m.Matches[0].Groups[1].Value                     # example 1.4 or 1.4-rc1
$Num = ($Version -split '-')[0].Split('.'); while ($Num.Count -lt 4) { $Num += '0' }
$VersionNum = $Num[0..3] -join '.'                           # 1.4.0.0
$s2 = Select-String -Path src\setup-autostart.ahk -Pattern 'ScriptVersion\s*:=\s*"([^"]+)"'
if ($s2.Matches[0].Groups[1].Value -ne $Version) { throw 'setup-autostart.ahk version differs from main script' }
if ($env:GITHUB_REF_TYPE -eq 'tag' -and $env:GITHUB_REF_NAME -ne "v$Version") { throw "Tag $env:GITHUB_REF_NAME does not match v$Version" }
Write-Host "Building $Version ($VersionNum)"

# ---- 1. validate (catches name clashes like IsAlpha / Vda) ---------------
foreach ($f in 'src\move-window-between-desktops.ahk','src\setup-autostart.ahk') {
  $p = Start-Process $AHK -ArgumentList '/ErrorStdOut','/validate',"`"$f`"" -Wait -PassThru -NoNewWindow
  if ($p.ExitCode -ne 0) { throw "Validation failed: $f" }
}

# ---- 2. verify vendor DLLs -------------------------------------------------
Get-Content vendor\SHA256SUMS | Where-Object { $_ -match '^\s*([0-9a-fA-F]{64})\s+\*?(.+?)\s*$' } | ForEach-Object {
  $null = $_ -match '^\s*([0-9a-fA-F]{64})\s+\*?(.+?)\s*$'
  $h = (Get-FileHash "vendor\$($Matches[2])" -Algorithm SHA256).Hash
  if ($h -ne $Matches[1].ToUpper()) { throw "Hash mismatch: vendor\$($Matches[2])" }
}
$listed = (Get-Content vendor\SHA256SUMS) -replace '^\s*[0-9a-fA-F]{64}\s+\*?', '' | ForEach-Object { $_.Trim() }
Get-ChildItem vendor\*.dll | Where-Object { $listed -notcontains $_.Name } |
  ForEach-Object { throw "Not listed in vendor\SHA256SUMS: $($_.Name)" }

# ---- 3. compile ------------------------------------------------------------
Remove-Item build,dist -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory build\app\vda,dist -Force | Out-Null
foreach ($n in 'move-window-between-desktops','setup-autostart') {
  $p = Start-Process $A2E -ArgumentList '/in',"`"src\$n.ahk`"",'/out',"`"build\app\$n.exe`"",'/base',"`"$((Resolve-Path $AHK).Path)`"",'/silent','verbose' -Wait -PassThru -NoNewWindow
  if ($p.ExitCode -ne 0 -or -not (Test-Path "build\app\$n.exe")) { throw "Compile failed: $n" }
}
Copy-Item vendor\*.dll build\app\vda\
Copy-Item assets\app_icon.ico,LICENSE,THIRD-PARTY-NOTICES.txt build\app\

# ---- 4. installer + portable zip ---------------------------------------------
& $ISCC "/DAppVersion=$Version" "/DAppVersionNum=$VersionNum" "/Odist" installer\setup.iss
if ($LASTEXITCODE -ne 0) { throw 'ISCC failed' }
Compress-Archive build\app\* "dist\move-window-between-desktops-$Version-portable.zip"
Copy-Item src\*.ahk dist\

$files = Get-ChildItem dist -File | Where-Object Name -ne 'SHA256SUMS.txt'
$files | ForEach-Object { "{0}  {1}" -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower(), $_.Name } |
  Set-Content dist\SHA256SUMS.txt
Write-Host "Done:"; Get-Content dist\SHA256SUMS.txt
