#!/usr/bin/env bash
# ====================================================
# Flutter Version Switcher for macOS (No FVM Needed)
# by ChatGPT — v2.1
# ====================================================
set -euo pipefail

FLUTTER_BASE="$HOME/flutter_versions"
FLUTTER_LINK="$HOME/flutter"

# Deteksi shell dan RC file
if [[ $SHELL == *"zsh"* ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ $SHELL == *"bash"* ]]; then
  SHELL_RC="$HOME/.bashrc"
else
  SHELL_RC="$HOME/.profile"
fi

mkdir -p "$FLUTTER_BASE"

# 🖥️ Color helpers
info() { echo -e "\033[1;34m$1\033[0m"; }
success() { echo -e "\033[1;32m$1\033[0m"; }
warn() { echo -e "\033[1;33m$1\033[0m"; }
error() { echo -e "\033[1;31m$1\033[0m"; }

# 🌐 Flutter releases base URL
BASE_URL="https://storage.googleapis.com/flutter_infra_release/releases"

# 💻 Detect architecture
detect_arch() {
  local arch
  arch=$(uname -m)
  if [[ "$arch" == "arm64" ]]; then
    echo "arm64"
  else
    echo "intel"
  fi
}

# ⚙️ Choose chip manually or autodetect
choose_chip() {
  echo
  echo "Pilih chip Mac kamu:"
  echo "1) Apple Silicon (M1/M2/M3)"
  echo "2) Intel"
  read -rp "Masukkan pilihan [1-2, default autodetect]: " chip_choice

  case "$chip_choice" in
    1) CHIP="arm64" ;;
    2) CHIP="intel" ;;
    *) CHIP=$(detect_arch) ;;
  esac

  info "Menggunakan chip: $CHIP"
}

# 🧭 Ensure PATH added to shell RC and reload it
ensure_path() {
  if ! grep -q 'flutter/bin' "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# Flutter SDK (auto-added by flutter_switcher)" >> "$SHELL_RC"
    echo "export PATH=\"\$HOME/flutter/bin:\$PATH\"" >> "$SHELL_RC"
    success "✅ Menambahkan PATH ke $SHELL_RC"
  else
    info "PATH Flutter sudah ada di $SHELL_RC"
  fi

  # Reload shell config supaya langsung aktif
  info "🔄 Memuat ulang konfigurasi shell..."
  # shellcheck disable=SC1090
  source "$SHELL_RC" || warn "Tidak bisa source otomatis, buka terminal baru."
}

# 🧰 Show installed versions
list_versions() {
  echo
  info "📦 Versi Flutter yang tersedia di $FLUTTER_BASE:"
  local i=0
  for d in "$FLUTTER_BASE"/*/; do
    [ -d "$d" ] || continue
    ((i++))
    echo "  $i) $(basename "$d")"
  done
  if [ "$i" -eq 0 ]; then
    warn "  (Belum ada versi Flutter terpasang)"
  fi
  echo
}

# 🌀 Switch version
switch_version() {
  list_versions
  read -rp "Masukkan nama versi (mis: flutter_3.24.3): " VER
  if [ ! -d "$FLUTTER_BASE/$VER" ]; then
    error "Versi tidak ditemukan: $FLUTTER_BASE/$VER"
    return
  fi
  rm -rf "$FLUTTER_LINK"
  ln -s "$FLUTTER_BASE/$VER" "$FLUTTER_LINK"
  success "✅ Berhasil ganti ke: $VER"
  ensure_path
  "$FLUTTER_LINK/bin/flutter" --version || warn "Flutter belum terdeteksi. Coba buka terminal baru."
}

# 🧱 Add local version manually
add_local() {
  read -rp "Masukkan path ke folder Flutter lokal: " SRC
  [ -d "$SRC" ] || { error "Folder tidak ditemukan"; return; }
  DEF_NAME=$(basename "$SRC")
  read -rp "Nama folder di flutter_versions (default: $DEF_NAME): " NAME
  NAME="${NAME:-$DEF_NAME}"
  DEST="$FLUTTER_BASE/$NAME"
  cp -a "$SRC" "$DEST"
  success "✅ Ditambahkan versi lokal: $DEST"
}

# 🌍 Download Flutter version
download_version() {
  choose_chip
  echo
  read -rp "Masukkan versi Flutter (contoh: 3.24.3, atau kosongkan untuk stable): " VER
  [ -z "$VER" ] && VER="stable"

  case "$CHIP" in
    arm64)
      ARCHIVE="flutter_macos_arm64_$VER-stable.zip"
      ;;
    intel)
      ARCHIVE="flutter_macos_$VER-stable.zip"
      ;;
  esac

  URL="$BASE_URL/stable/macos/$ARCHIVE"
  DEST="$FLUTTER_BASE/flutter_$VER"
  TMP_ZIP="/tmp/flutter_$VER.zip"

  echo
  info "🔽 Mengunduh Flutter $VER ($CHIP)..."
  echo "📡 URL: $URL"
  echo

  curl -L -o "$TMP_ZIP" "$URL" || { error "❌ Gagal mengunduh versi $VER"; return; }

  info "📦 Mengekstrak ke $DEST ..."
  unzip -q "$TMP_ZIP" -d "$FLUTTER_BASE"
  mv "$FLUTTER_BASE/flutter" "$DEST"
  rm "$TMP_ZIP"
  success "✅ Flutter $VER terpasang di $DEST"
}

# 🧩 Main menu
main_menu() {
  ensure_path
  while true; do
    echo
    echo "================== Flutter Switcher =================="
    echo "1) Lihat versi Flutter terpasang"
    echo "2) Ganti versi Flutter aktif"
    echo "3) Tambah versi Flutter dari folder lokal"
    echo "4) Download versi Flutter baru"
    echo "5) Lihat versi Flutter aktif"
    echo "6) Jalankan 'flutter doctor'"
    echo "7) Keluar"
    echo "======================================================"
    read -rp "Pilih opsi [1-7]: " CHOICE
    case "$CHOICE" in
      1) list_versions ;;
      2) switch_version ;;
      3) add_local ;;
      4) download_version ;;
      5) "$FLUTTER_LINK/bin/flutter" --version 2>/dev/null || warn "Belum ada versi aktif" ;;
      6) "$FLUTTER_LINK/bin/flutter" doctor 2>/dev/null || warn "Belum ada versi aktif" ;;
      7) exit 0 ;;
      *) warn "Pilihan tidak valid." ;;
    esac
  done
}

main_menu
