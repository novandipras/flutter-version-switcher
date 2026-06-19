# 🦋 Flutter Version Switcher for macOS

Script bash interaktif untuk **mengelola dan mengganti versi Flutter SDK di macOS** tanpa perlu FVM.  
Cocok buat developer yang ingin beberapa versi Flutter di satu mesin tanpa download berulang kali.

## ✨ Fitur Utama

✅ Pilih Flutter SDK aktif melalui menu interaktif<br>
✅ Unduh Flutter SDK langsung dari server resmi<br>
✅ Pilih chip Mac (Intel / Apple Silicon)  
✅ Tambah Flutter versi lokal ke koleksi  
✅ Cek versi Flutter stable terbaru<br>
✅ Hapus Flutter SDK yang tidak sedang aktif<br>
✅ Tampilan terminal bersih dengan status versi aktif<br>
✅ Auto-update `$PATH` di `.zshrc` atau `.bashrc`  
✅ 100% tanpa FVM  

---

## ⚙️ Instalasi

1. Clone atau download script:
```bash
  https://github.com/novandipras/flutter-switcher.git
```
2. Beri izin eksekusi:
```bash
  chmod +x flutter-switcher.sh run.command
```
3. Jalankan dari Terminal:
```bash
  ./flutter-switcher.sh
```

Double-click **run.command** di Finder untuk menjalankan Flutter Switcher.
Saat memilih **Keluar**, jendela Terminal launcher akan ditutup otomatis.

💡 Script ini otomatis menambahkan export PATH="$HOME/flutter_active/bin:$PATH" ke file konfigurasi shell (.zshrc / .bashrc).

## 📦 Struktur Folder

Setelah script dijalankan, struktur folder default di dalam $HOME akan seperti ini:

```bash
~/flutter_switcher.sh
~/flutter_versions/
```
```bash
│
├── flutter_3.19.6/
├── flutter_3.22.0/
└── flutter_3.24.3/
│
└── flutter_active -> ~/flutter_versions/flutter_3.24.3  (shortcut aktif)
```

Folder `~/flutter_active` adalah symlink/shortcut ke versi Flutter yang sedang aktif.
Command flutter di terminal akan membaca dari sini.

Shortcut kompatibilitas `~/flutter` juga dibuat menuju `~/flutter_active`
agar konfigurasi Android Studio atau terminal lama tetap berfungsi.

## 🧭 Menu Utama
```bash
================== Flutter Switcher ==================
1) Kelola Flutter SDK
2) Impor Flutter SDK dari Folder
3) Unduh Flutter SDK
4) Lihat Informasi SDK Aktif
5) Jalankan 'flutter doctor'
6) Cek Versi Stable Terbaru
7) Keluar
======================================================
Pilih opsi [1-7]:
```

Penjelasan Menu
Opsi	Fungsi
1)	Kelola SDK dengan ↑/↓: jadikan aktif, upgrade & sesuaikan nama folder, atau hapus
2)	Impor Flutter SDK dari folder lokal
3)	Unduh Flutter SDK dari server resmi sesuai chip Mac
4)	Lihat informasi Flutter SDK yang sedang aktif
5)	Jalankan flutter doctor
6)	Cek versi Flutter stable terbaru dari server resmi
7)	Keluar dari script

## 💻 Contoh Penggunaan
🌀 Mengganti versi Flutter aktif

Jalankan:
```bash
./flutter_switcher.sh
```

Pilih opsi 1, pilih SDK dengan **↑/↓**, lalu tekan **Enter**. Tersedia aksi:
**Jadikan SDK Aktif**, **Upgrade SDK dan Sesuaikan Nama Folder**, atau
**Hapus SDK Ini**. Tekan **Esc** untuk kembali satu tingkat.

Pada layar informasi SDK aktif (opsi 4), tekan **Enter** atau **Esc** untuk
kembali ke menu utama.

Pada menu unduh SDK (opsi 3), tekan **Esc** saat memilih chip, memasukkan
versi, atau mengonfirmasi download ulang untuk membatalkan dan kembali.

Pada menu impor SDK dan konfirmasi hapus, tekan **Esc** untuk kembali tanpa
menjalankan perubahan. Layar hasil aksi menerima **Enter** atau **Esc**, dan
**Esc** pada menu utama akan menutup Flutter Switcher.

Tunggu beberapa detik, lalu jalankan:
```bash
flutter --version
```

Hasilnya akan menunjukkan versi yang baru diaktifkan.

## 🧰 Uninstall (opsional)

Untuk menghapus semua versi Flutter dan symlink:
```bash
rm -rf ~/flutter_versions ~/flutter_active ~/flutter
```

Untuk menghapus baris PATH dari .zshrc:
```bash
sed -i '' '/flutter\/bin/d' ~/.zshrc
```
