# 🦋 Flutter Version Switcher for macOS

Script bash interaktif untuk **mengelola dan mengganti versi Flutter SDK di macOS** tanpa perlu FVM.  
Cocok buat developer yang ingin beberapa versi Flutter di satu mesin tanpa download berulang kali.

## ✨ Fitur Utama

✅ Ganti versi Flutter aktif hanya dengan satu menu  
✅ Download versi Flutter langsung dari server resmi  
✅ Pilih chip Mac (Intel / Apple Silicon)  
✅ Tambah Flutter versi lokal ke koleksi  
✅ Auto-update `$PATH` di `.zshrc` atau `.bashrc`  
✅ Auto reload shell agar `flutter` langsung bisa digunakan  
✅ 100% tanpa FVM  

---

## ⚙️ Instalasi

1. Clone atau download script:
```bash
  https://github.com/novandipras/flutter-switcher.git
```
2. Beri izin eksekusi:
```bash
  chmod +x flutter_switcher.sh
```
3.  Jalankan:
```bash
  ./flutter_switcher.sh
```

💡 Script ini otomatis menambahkan export PATH="$HOME/flutter/bin:$PATH" ke file konfigurasi shell (.zshrc / .bashrc) dan langsung me-reload PATH-nya.

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
└── flutter -> ~/flutter_versions/flutter_3.24.3  (symlink aktif)
```

Folder ~/flutter adalah symlink ke versi Flutter yang sedang aktif.
Command flutter di terminal akan membaca dari sini.

## 🧭 Menu Utama
```bash
================== Flutter Switcher ==================
1) Lihat versi Flutter terpasang
2) Ganti versi Flutter aktif
3) Tambah versi Flutter dari folder lokal
4) Download versi Flutter baru
5) Lihat versi Flutter aktif
6) Jalankan 'flutter doctor'
7) Keluar
======================================================
Pilih opsi [1-7]:
```

Penjelasan Menu
Opsi	Fungsi
1)	Menampilkan semua versi Flutter di ~/flutter_versions/
2)	Mengganti versi Flutter aktif (update symlink ~/flutter)
3)	Tambahkan versi Flutter dari folder lokal
4)	Unduh versi baru dari server Flutter sesuai chip Mac
5)	Tampilkan versi Flutter aktif
6)	Jalankan flutter doctor
7)	Keluar dari script

## 💻 Contoh Penggunaan
🌀 Mengganti versi Flutter aktif

Jalankan:
```bash
./flutter_switcher.sh
```

Pilih opsi 2

Masukkan nama versi, contoh:
```bash
flutter_3.22.0
```

Tunggu beberapa detik, lalu jalankan:
```bash
flutter --version
```

Hasilnya akan menunjukkan versi yang baru diaktifkan.

## 🧰 Uninstall (opsional)

Untuk menghapus semua versi Flutter dan symlink:
```bash
rm -rf ~/flutter_versions ~/flutter
```

Untuk menghapus baris PATH dari .zshrc:
```bash
sed -i '' '/flutter\/bin/d' ~/.zshrc
```
