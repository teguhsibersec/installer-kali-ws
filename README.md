# 🐉 Kali Linux WSL2 Auto Installer

> **by [teguhsibersec](https://github.com/teguhsibersec)** — stay curious, stay ethical.

Installer otomatis satu klik untuk memasang **WSL2** dan **Kali Linux** di Windows, lengkap dengan pengaturan Windows yang dibutuhkan, konfigurasi performa, dan tampilan terminal yang keren selama proses instalasi.

![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE)
![Kali](https://img.shields.io/badge/Kali%20Linux-WSL2-557C94)

---

## ✨ Fitur

- 🔑 **Auto-elevate** — otomatis meminta hak Administrator.
- 🔍 **Cek sistem** — memeriksa versi Windows dan status virtualisasi (VT-x / AMD-V).
- 🪟 **Aktivasi fitur Windows** — `Windows Subsystem for Linux` dan `Virtual Machine Platform`.
- 🔄 **Auto-resume setelah restart** — kalau Windows perlu restart, skrip lanjut sendiri saat Anda login.
- ⚙️ **Instal & update WSL**, dengan WSL2 sebagai versi default.
- 🧠 **Konfigurasi `.wslconfig` otomatis** — RAM, CPU, swap, dan memory reclaim disesuaikan dengan spesifikasi PC (file lama dicadangkan).
- 💻 **Windows Terminal** dipasang lewat `winget` (opsional).
- 🐉 **Pasang Kali Linux** dan jadikan distro default.
- 👤 **Buat user Linux** dan atur password.
- 🧩 **Aktifkan systemd** dan set default user lewat `/etc/wsl.conf`.
- 📦 **Update penuh Kali** (`apt update && apt full-upgrade`).
- 🛠️ **Paket tool Kali opsional** (`default`, `headless`, atau `large`) dan **Win-KeX** (desktop GUI).
- 🎨 **Tampilan keren** — banner ASCII, boot sequence, progress bar per langkah, spinner, dan log instalasi.

---

## 📋 Persyaratan

| Kebutuhan | Keterangan |
|---|---|
| Windows | Windows 10 versi 2004 (build 19041) ke atas, atau Windows 11 |
| Virtualisasi | Harus aktif di BIOS/UEFI (Intel VT-x / AMD-V / SVM) |
| Internet | Dibutuhkan untuk mengunduh WSL dan Kali Linux |
| Hak akses | Akun Administrator |
| Disk | Disarankan minimal 10 GB kosong (lebih besar bila memakai `-Tools large`) |

---

## 🚀 Cara Pakai

### Cara cepat

1. Download repo ini (**Code → Download ZIP**) lalu ekstrak.
2. Pastikan `Install-KaliWSL.bat` dan `Install-KaliWSL.ps1` berada di **folder yang sama**.
3. Klik dua kali **`Install-KaliWSL.bat`**.
4. Izinkan permintaan Administrator (UAC), lalu ikuti petunjuk di layar.

### Lewat PowerShell

Buka PowerShell sebagai Administrator, lalu:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Install-KaliWSL.ps1
```

### Dengan opsi lanjutan

```powershell
.\Install-KaliWSL.ps1 -Tools default -Gui -MemoryGB 8 -Processors 4
```

Atau lewat file `.bat`:

```bat
Install-KaliWSL.bat -Tools default -Gui
```

---

## 🎛️ Parameter

| Parameter | Nilai | Keterangan |
|---|---|---|
| `-Tools` | `none` (default), `default`, `headless`, `large` | Memasang metapackage `kali-linux-*` |
| `-Gui` | switch | Memasang **Win-KeX** (desktop Kali di Windows) |
| `-MemoryGB` | angka | Batas RAM WSL. Default: 50% RAM fisik |
| `-Processors` | angka | Batas CPU WSL. Default: 50% core logis |
| `-SkipWindowsTerminal` | switch | Lewati pemasangan Windows Terminal |
| `-Resume` | switch | Dipakai otomatis setelah restart. **Jangan diisi manual** |

---

## 🔄 Alur Instalasi

| Langkah | Proses |
|---|---|
| 1 | Memeriksa sistem (versi Windows, virtualisasi) |
| 2 | Mengaktifkan fitur Windows (restart bila diperlukan) |
| 3 | Memasang / memperbarui WSL, set WSL2 default |
| 4 | Menulis `.wslconfig` |
| 5 | Memasang Windows Terminal |
| 6 | Mengunduh & memasang Kali Linux |
| 7 | Membuat user Linux |
| 8 | Konfigurasi `/etc/wsl.conf` (systemd + default user) |
| 9 | Update paket Kali |
| 10 | Memasang paket tambahan (tools / Win-KeX) |

---

## 🧠 Konfigurasi yang Dibuat

### `%USERPROFILE%\.wslconfig`

```ini
[wsl2]
memory=<50% RAM>GB
processors=<50% core>
swap=<setengah memory>GB
localhostForwarding=true

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
```

Setelah mengubah file ini, jalankan `wsl --shutdown` agar perubahan berlaku.

### `/etc/wsl.conf` (di dalam Kali)

```ini
[boot]
systemd=true

[user]
default=<username-anda>

[interop]
enabled=true
appendWindowsPath=true
```

---

## 🖥️ Setelah Instalasi

```bash
# Masuk ke Kali
wsl

# Jalankan desktop GUI (jika memasang -Gui)
kex --win -s

# Update manual kapan saja
sudo apt update && sudo apt full-upgrade -y
```

---

## 📝 Log

Detail proses yang berjalan di latar belakang (update paket, instal tools) disimpan di:

```
%TEMP%\teguhsibersec-kali-install.log
```

Lampirkan file ini bila Anda membuat *issue*.

---

## 🛠️ Troubleshooting

| Masalah | Solusi |
|---|---|
| **Virtualisasi mati** | Aktifkan Intel VT-x / AMD SVM di BIOS/UEFI |
| **Skrip diblokir PowerShell** | Jalankan lewat `Install-KaliWSL.bat`, yang sudah memakai `ExecutionPolicy Bypass` |
| **`wsl --install` gagal** | Pastikan Windows sudah diperbarui, lalu coba lagi. Atau jalankan manual: `wsl --install -d kali-linux` |
| **Banner tampil patah** | Perlebar jendela minimal 84 kolom, atau gunakan Windows Terminal |
| **Unduhan lambat / gagal** | Periksa koneksi internet, VPN, atau proxy |
| **Memory WSL terlalu besar/kecil** | Edit `%USERPROFILE%\.wslconfig`, lalu `wsl --shutdown` |

---

## 🗑️ Uninstall

```powershell
# Hapus Kali Linux (SEMUA DATA DI DALAMNYA HILANG)
wsl --unregister kali-linux

# Matikan WSL
wsl --shutdown
```

Untuk memulihkan konfigurasi lama, gunakan file cadangan `.wslconfig.bak-*` di folder `%USERPROFILE%`.

---

## ⚠️ Disclaimer

Kali Linux berisi alat untuk **pengujian keamanan (penetration testing)**. Gunakan hanya pada sistem milik Anda sendiri atau yang Anda punya **izin tertulis** untuk mengujinya. Penulis tidak bertanggung jawab atas penyalahgunaan alat ini.

Proyek ini tidak berafiliasi dengan Offensive Security, Kali Linux, maupun Microsoft.

---

## 🤝 Kontribusi

Pull request dan *issue* sangat diterima. Silakan fork repo ini, buat branch baru, lalu ajukan PR.

---

## 📄 Lisensi

Dirilis di bawah lisensi **MIT** (tambahkan file `LICENSE` di repo Anda).

---

<p align="center">Dibuat dengan ☕ oleh <b>teguhsibersec</b></p>
