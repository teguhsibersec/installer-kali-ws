<#
.SYNOPSIS
  teguhsibersec | Kali Linux WSL2 Auto Installer

.PARAMETER Tools
  none (default) | default | headless | large  -> paket tool Kali
.PARAMETER Gui
  Pasang Win-KeX (desktop Kali di Windows)
.PARAMETER MemoryGB
  Batas RAM WSL (default: 50% RAM fisik)
.PARAMETER Processors
  Batas CPU WSL (default: 50% core logis)
.PARAMETER Resume
  Dipakai otomatis setelah restart. Jangan diisi manual.
#>
param(
    [ValidateSet('none','default','headless','large')]
    [string]$Tools = 'none',
    [switch]$Gui,
    [int]$MemoryGB = 0,
    [int]$Processors = 0,
    [switch]$SkipWindowsTerminal,
    [switch]$Resume
)

$ErrorActionPreference = 'Stop'
$Distro      = 'kali-linux'
$Brand       = 'teguhsibersec'
$Script:RebootNeeded = $false
$Script:StepNo       = 0
$Script:TotalSteps   = 10
$Script:LogFile      = Join-Path $env:TEMP 'teguhsibersec-kali-install.log'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$Host.UI.RawUI.WindowTitle = "$Brand | Kali Linux WSL2 Installer"

# ======================= UI HELPERS =======================
$BLK = [string][char]0x2588
$LGT = [string][char]0x2591

function Info($m){ Write-Host "  [*] $m" -ForegroundColor Cyan }
function Ok($m)  { Write-Host "  [+] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "  [!] $m" -ForegroundColor Yellow }
function Fail($m){ Write-Host "  [x] $m" -ForegroundColor Red }

function Type-Line([string]$Text, [string]$Color = 'Gray', [int]$Delay = 6) {
    foreach ($c in $Text.ToCharArray()) {
        Write-Host $c -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $Delay
    }
    Write-Host ""
}

function Show-Banner {
    try {
        if ($Host.UI.RawUI.WindowSize.Width -lt 84) {
            $b = $Host.UI.RawUI.BufferSize; $b.Width = 100
            $Host.UI.RawUI.BufferSize = $b
            $w = $Host.UI.RawUI.WindowSize; $w.Width = 90
            $Host.UI.RawUI.WindowSize = $w
        }
    } catch {}
    Clear-Host

    $glyph = @{
        'T'=@('#####','..#..','..#..','..#..','..#..')
        'E'=@('#####','#....','####.','#....','#####')
        'G'=@('.####','#....','#..##','#...#','.####')
        'U'=@('#...#','#...#','#...#','#...#','.###.')
        'H'=@('#...#','#...#','#####','#...#','#...#')
        'S'=@('.####','#....','.###.','....#','####.')
        'I'=@('#####','..#..','..#..','..#..','#####')
        'B'=@('####.','#...#','####.','#...#','####.')
        'R'=@('####.','#...#','####.','#..#.','#...#')
        'C'=@('.####','#....','#....','#....','.####')
    }
    $word = 'TEGUHSIBERSEC'
    Write-Host ""
    Write-Host ("  " + ("=" * 78)) -ForegroundColor DarkCyan
    Write-Host ""
    for ($row = 0; $row -lt 5; $row++) {
        Write-Host "  " -NoNewline
        for ($i = 0; $i -lt $word.Length; $i++) {
            $ch  = $word[$i].ToString()
            $col = if ($i -lt 5) { 'Cyan' } else { 'Green' }
            $line = ($glyph[$ch][$row]).Replace('#', $BLK).Replace('.', ' ')
            Write-Host ($line + " ") -NoNewline -ForegroundColor $col
        }
        Write-Host ""
        Start-Sleep -Milliseconds 60
    }
    Write-Host ""
    Write-Host ("  " + ("=" * 78)) -ForegroundColor DarkCyan
    Write-Host "   >> KALI LINUX WSL2 AUTO INSTALLER  //  by " -NoNewline -ForegroundColor DarkGray
    Write-Host $Brand -NoNewline -ForegroundColor Red
    Write-Host "  //  stay curious, stay ethical" -ForegroundColor DarkGray
    Write-Host ("  " + ("=" * 78)) -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-Boot {
    $lines = @(
        'Initializing installer engine',
        'Loading WSL2 module',
        'Preparing Kali Linux payload',
        'Checking privileges'
    )
    foreach ($l in $lines) {
        Write-Host "  [ " -NoNewline -ForegroundColor DarkGray
        Write-Host " OK " -NoNewline -ForegroundColor Green
        Write-Host " ] " -NoNewline -ForegroundColor DarkGray
        Type-Line $l 'Gray' 8
        Start-Sleep -Milliseconds 120
    }
    Write-Host ""
}

function Get-Bar([int]$Pct, [int]$Width = 40) {
    $filled = [int][math]::Floor($Width * $Pct / 100)
    return (($BLK * $filled) + ($LGT * ($Width - $filled)))
}

function Step([string]$Title) {
    $Script:StepNo++
    $pct = [int][math]::Floor((($Script:StepNo - 1) / $Script:TotalSteps) * 100)
    $head = ("STEP {0:00}/{1:00}  {2}" -f $Script:StepNo, $Script:TotalSteps, $Title)
    if ($head.Length -gt 72) { $head = $head.Substring(0,72) }
    Write-Host ""
    Write-Host ("  +" + ("-" * 74) + "+") -ForegroundColor DarkCyan
    Write-Host "  | " -NoNewline -ForegroundColor DarkCyan
    Write-Host $head.PadRight(72) -NoNewline -ForegroundColor White
    Write-Host " |" -ForegroundColor DarkCyan
    Write-Host "  | " -NoNewline -ForegroundColor DarkCyan
    Write-Host (Get-Bar $pct) -NoNewline -ForegroundColor Cyan
    Write-Host ("  {0,3}%" -f $pct).PadRight(30) -NoNewline -ForegroundColor Green
    Write-Host " |" -ForegroundColor DarkCyan
    Write-Host ("  +" + ("-" * 74) + "+") -ForegroundColor DarkCyan
    Write-Progress -Activity "$Brand | Kali WSL2 Installer" -Status $Title -PercentComplete $pct
}

function Prompt-Input([string]$Text) {
    Write-Host "  [?] " -NoNewline -ForegroundColor Magenta
    return (Read-Host $Text)
}

# Jalankan perintah wsl panjang dengan spinner + log
function Invoke-Spin([string]$Label, [string]$ArgString) {
    $out = [IO.Path]::GetTempFileName()
    $err = "$out.err"
    $p = Start-Process wsl.exe -ArgumentList $ArgString -NoNewWindow -PassThru `
         -RedirectStandardOutput $out -RedirectStandardError $err
    $null = $p.Handle
    $frames = @('|','/','-','\')
    $i = 0
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try { [Console]::CursorVisible = $false } catch {}
    while (-not $p.HasExited) {
        Write-Host ("`r  [{0}] {1}  [{2:mm\:ss}]   " -f $frames[$i % 4], $Label, $sw.Elapsed) -NoNewline -ForegroundColor Cyan
        $i++
        Start-Sleep -Milliseconds 120
    }
    $p.WaitForExit()
    try { [Console]::CursorVisible = $true } catch {}
    Add-Content -Path $Script:LogFile -Value "=== $Label ($ArgString) ==="
    if (Test-Path $out) { Get-Content $out -ErrorAction SilentlyContinue | Add-Content $Script:LogFile }
    if (Test-Path $err) { Get-Content $err -ErrorAction SilentlyContinue | Add-Content $Script:LogFile }
    Remove-Item $out, $err -ErrorAction SilentlyContinue
    if ($p.ExitCode -eq 0) {
        Write-Host ("`r  [+] {0}  [{1:mm\:ss}] selesai                    " -f $Label, $sw.Elapsed) -ForegroundColor Green
    } else {
        Write-Host ("`r  [x] {0} gagal (kode {1}). Lihat log: {2}" -f $Label, $p.ExitCode, $Script:LogFile) -ForegroundColor Red
    }
}

# Helper: baca output wsl.exe (UTF-16)
function Get-WslDistros {
    $old = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
        $out = & wsl.exe -l -q 2>$null
        return ($out | ForEach-Object { ($_ -replace "`0",'').Trim() } | Where-Object { $_ })
    } catch { return @() }
    finally { [Console]::OutputEncoding = $old }
}

# ======================= SELF-ELEVATE =======================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "  [!] Membutuhkan hak Administrator, meminta elevasi..." -ForegroundColor Yellow
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Tools $Tools"
    if ($Gui) { $argList += ' -Gui' }
    if ($MemoryGB)   { $argList += " -MemoryGB $MemoryGB" }
    if ($Processors) { $argList += " -Processors $Processors" }
    if ($SkipWindowsTerminal) { $argList += ' -SkipWindowsTerminal' }
    if ($Resume) { $argList += ' -Resume' }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
    exit
}

Show-Banner
Show-Boot

# ======================= STEP 1: CEK SISTEM =======================
Step 'Memeriksa sistem'
$build = [Environment]::OSVersion.Version.Build
if ($build -lt 19041) {
    Fail "Windows build $build tidak mendukung WSL2. Butuh Windows 10 2004 (build 19041) atau lebih baru."
    Read-Host "Tekan Enter untuk keluar"; exit 1
}
Ok "Windows build $build didukung."

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
if ($cpu.VirtualizationFirmwareEnabled -eq $false -and -not (Get-CimInstance Win32_ComputerSystem).HypervisorPresent) {
    Warn "Virtualisasi (Intel VT-x / AMD-V / SVM) tampaknya MATI di BIOS/UEFI."
    Warn "Aktifkan dulu di BIOS, kalau tidak WSL2 tidak akan bisa jalan."
    $a = Prompt-Input "Lanjutkan juga? (y/N)"
    if ($a -notmatch '^[yY]') { exit 1 }
} else { Ok "Virtualisasi aktif." }

# ======================= STEP 2: FITUR WINDOWS =======================
Step 'Mengaktifkan fitur Windows'
$features = @('Microsoft-Windows-Subsystem-Linux','VirtualMachinePlatform')
foreach ($f in $features) {
    $st = Get-WindowsOptionalFeature -Online -FeatureName $f
    if ($st.State -ne 'Enabled') {
        Info "Mengaktifkan $f ..."
        $r = Enable-WindowsOptionalFeature -Online -FeatureName $f -NoRestart -All
        if ($r.RestartNeeded) { $Script:RebootNeeded = $true }
        Ok "$f aktif."
    } else { Ok "$f sudah aktif." }
}

if ($Script:RebootNeeded -and -not $Resume) {
    Warn "Perlu restart agar fitur aktif. Skrip lanjut otomatis setelah login."
    $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Resume -Tools $Tools"
    if ($Gui) { $cmd += ' -Gui' }
    if ($MemoryGB)   { $cmd += " -MemoryGB $MemoryGB" }
    if ($Processors) { $cmd += " -Processors $Processors" }
    if ($SkipWindowsTerminal) { $cmd += ' -SkipWindowsTerminal' }
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' `
        -Name 'KaliWSLInstaller' -Value $cmd -PropertyType String -Force | Out-Null
    $a = Prompt-Input "Restart sekarang? (Y/n)"
    if ($a -notmatch '^[nN]') { Restart-Computer -Force }
    else { Warn "Restart manual dulu, lalu skrip jalan otomatis saat login." }
    exit
}

# ======================= STEP 3: WSL =======================
Step 'Memasang / memperbarui WSL'
try {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { throw "wsl.exe tidak ada" }
    & wsl.exe --update | Out-Host
} catch {
    Warn "wsl --update gagal, mencoba wsl --install --no-distribution ..."
    & wsl.exe --install --no-distribution | Out-Host
}
& wsl.exe --set-default-version 2 | Out-Host
Ok "WSL siap, versi default = 2."

# ======================= STEP 4: .WSLCONFIG =======================
Step 'Menulis konfigurasi .wslconfig'
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$cores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
if ($MemoryGB -le 0)   { $MemoryGB   = [math]::Max(2, [math]::Floor($ramGB / 2)) }
if ($Processors -le 0) { $Processors = [math]::Max(2, [math]::Floor($cores / 2)) }
$swap = [math]::Max(2, [math]::Floor($MemoryGB / 2))

$wslConfig = Join-Path $env:USERPROFILE '.wslconfig'
if (Test-Path $wslConfig) {
    $bak = "$wslConfig.bak-$(Get-Date -Format yyyyMMddHHmmss)"
    Copy-Item $wslConfig $bak
    Warn ".wslconfig lama dicadangkan ke $bak"
}
$cfg = @"
[wsl2]
memory=${MemoryGB}GB
processors=$Processors
swap=${swap}GB
localhostForwarding=true

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
"@
Set-Content -Path $wslConfig -Value $cfg -Encoding ASCII
Ok ".wslconfig dibuat: RAM ${MemoryGB}GB | CPU $Processors | swap ${swap}GB"

# ======================= STEP 5: WINDOWS TERMINAL =======================
Step 'Windows Terminal'
if (-not $SkipWindowsTerminal) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $wt = winget list --id Microsoft.WindowsTerminal 2>$null | Select-String 'Microsoft.WindowsTerminal'
        if (-not $wt) {
            Info "Memasang Windows Terminal..."
            winget install --id Microsoft.WindowsTerminal -e --accept-source-agreements --accept-package-agreements | Out-Host
        } else { Ok "Windows Terminal sudah terpasang." }
    } else { Warn "winget tidak ditemukan, lewati Windows Terminal." }
} else { Info "Dilewati (-SkipWindowsTerminal)." }

# ======================= STEP 6: KALI LINUX =======================
Step 'Mengunduh & memasang Kali Linux'
$installed = Get-WslDistros
if ($installed -contains $Distro) {
    Ok "Kali Linux sudah terpasang."
} else {
    Info "Mengunduh Kali Linux (bisa beberapa menit)..."
    & wsl.exe --install -d $Distro --no-launch | Out-Host
    Start-Sleep -Seconds 3
    & wsl.exe -d $Distro -u root -- true | Out-Null
    if ((Get-WslDistros) -notcontains $Distro) {
        Fail "Kali Linux gagal terpasang. Coba manual: wsl --install -d kali-linux"
        Read-Host "Tekan Enter untuk keluar"; exit 1
    }
    Ok "Kali Linux terpasang."
}
& wsl.exe --set-default $Distro | Out-Null
& wsl.exe --set-version $Distro 2 2>$null | Out-Null

# ======================= STEP 7: USER =======================
Step 'Membuat user Linux'
$hasUser = (& wsl.exe -d $Distro -u root -- bash -c "getent passwd 1000 | cut -d: -f1") 2>$null
if (-not $hasUser) {
    do {
        $user = (Prompt-Input "Username Linux (huruf kecil, tanpa spasi)").Trim()
    } until ($user -match '^[a-z_][a-z0-9_-]{0,30}$')
    & wsl.exe -d $Distro -u root -- bash -c "useradd -m -s /bin/bash -G sudo $user"
    Info "Atur password untuk '$user':"
    & wsl.exe -d $Distro -u root -- passwd $user
    $hasUser = $user
    Ok "User '$user' dibuat."
} else { Ok "User Linux sudah ada: $hasUser" }

# ======================= STEP 8: WSL.CONF =======================
Step 'Konfigurasi /etc/wsl.conf (systemd)'
& wsl.exe -d $Distro -u root -- bash -c "printf '[boot]\nsystemd=true\n\n[user]\ndefault=$hasUser\n\n[interop]\nenabled=true\nappendWindowsPath=true\n' > /etc/wsl.conf"
& wsl.exe --terminate $Distro | Out-Null
Ok "wsl.conf dikonfigurasi."

# ======================= STEP 9: UPDATE =======================
Step 'Update paket Kali'
Invoke-Spin 'apt update && full-upgrade' "-d $Distro -u root -- bash -c `"export DEBIAN_FRONTEND=noninteractive; apt-get update && apt-get -y full-upgrade`""

# ======================= STEP 10: PAKET TAMBAHAN =======================
Step 'Paket tambahan'
if ($Tools -ne 'none') {
    Invoke-Spin "Memasang kali-linux-$Tools" "-d $Distro -u root -- bash -c `"export DEBIAN_FRONTEND=noninteractive; apt-get install -y kali-linux-$Tools`""
} else { Info "Paket tool tidak dipilih (-Tools none)." }
if ($Gui) {
    Invoke-Spin 'Memasang Win-KeX (GUI)' "-d $Distro -u root -- bash -c `"export DEBIAN_FRONTEND=noninteractive; apt-get install -y kali-win-kex`""
    Ok "Win-KeX terpasang. Jalankan di Kali: kex --win -s"
}

# ======================= SELESAI =======================
Write-Progress -Activity "$Brand | Kali WSL2 Installer" -Completed
Write-Host ""
Write-Host "  +$("=" * 74)+" -ForegroundColor Green
Write-Host "  | " -NoNewline -ForegroundColor Green
Write-Host (Get-Bar 100).PadRight(46) -NoNewline -ForegroundColor Green
Write-Host "  100%  COMPLETE".PadRight(26) -NoNewline -ForegroundColor Green
Write-Host " |" -ForegroundColor Green
Write-Host "  +$("=" * 74)+" -ForegroundColor Green
Write-Host ""
Write-Host "   Kali Linux WSL2 siap dipakai!" -ForegroundColor White
Write-Host ""
Write-Host "   Buka Kali     : " -NoNewline -ForegroundColor DarkGray; Write-Host "wsl   (atau menu Start / Windows Terminal)" -ForegroundColor Cyan
Write-Host "   Config WSL    : " -NoNewline -ForegroundColor DarkGray; Write-Host "$wslConfig" -ForegroundColor Cyan
Write-Host "   Config Kali   : " -NoNewline -ForegroundColor DarkGray; Write-Host "/etc/wsl.conf" -ForegroundColor Cyan
Write-Host "   Log instalasi : " -NoNewline -ForegroundColor DarkGray; Write-Host "$Script:LogFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "   -----------------------------------------------" -ForegroundColor DarkCyan
Write-Host "   Installer by " -NoNewline -ForegroundColor DarkGray
Write-Host $Brand -NoNewline -ForegroundColor Red
Write-Host "  |  Hack ethically. Learn endlessly." -ForegroundColor DarkGray
Write-Host "   -----------------------------------------------" -ForegroundColor DarkCyan
Write-Host ""
$a = Prompt-Input "Buka Kali sekarang? (Y/n)"
if ($a -notmatch '^[nN]') { Start-Process wsl.exe -ArgumentList "-d $Distro" }
