#!/usr/bin/env bash
# ====================================================
# Flutter Version Switcher for macOS (No FVM Needed)
# by ChatGPT — v2.1
# ====================================================
set -euo pipefail

FLUTTER_BASE="$HOME/flutter_versions"
FLUTTER_LINK="$HOME/flutter"
LISTED_VERSIONS=()

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
RELEASES_JSON_URL="$BASE_URL/releases_macos.json"

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
  local path_line='export PATH="$HOME/flutter/bin:$PATH"'
  local added=false

  # For zsh, also ensure .zprofile (login shells) and .zshrc (interactive)
  if [[ $SHELL == *"zsh"* ]]; then
    for rc in "$HOME/.zshrc" "$HOME/.zprofile"; do
      touch "$rc" 2>/dev/null || true
      if ! grep -q 'flutter/bin' "$rc" 2>/dev/null; then
        echo "" >> "$rc"
        echo "# Flutter SDK (auto-added by flutter_switcher)" >> "$rc"
        echo "$path_line" >> "$rc"
        success "✅ Menambahkan PATH ke $rc"
        added=true
      fi
    done
  else
    if ! grep -q 'flutter/bin' "$SHELL_RC" 2>/dev/null; then
      echo "" >> "$SHELL_RC"
      echo "# Flutter SDK (auto-added by flutter_switcher)" >> "$SHELL_RC"
      echo "$path_line" >> "$SHELL_RC"
      success "✅ Menambahkan PATH ke $SHELL_RC"
      added=true
    else
      info "PATH Flutter sudah ada di $SHELL_RC"
    fi
  fi

  # Export into current session so the script (and immediate commands) can use flutter
  export PATH="$HOME/flutter/bin:$PATH"

  # Reload shell config supaya langsung aktif (best-effort)
  info "🔄 Memuat ulang konfigurasi shell..."
  # shellcheck disable=SC1090
  if ! source "$SHELL_RC" 2>/dev/null; then
    if [[ $SHELL == *"zsh"* ]]; then
      # try zsh files explicitly
      # shellcheck disable=SC1091
      source "$HOME/.zshrc" 2>/dev/null || source "$HOME/.zprofile" 2>/dev/null || warn "Tidak bisa source otomatis, buka terminal baru."
    else
      warn "Tidak bisa source otomatis, buka terminal baru."
    fi
  fi

  if command -v flutter >/dev/null 2>&1; then
    success "Flutter tersedia di PATH"
  else
    warn "Flutter masih belum terdeteksi dalam sesi ini. Coba buka terminal baru atau jalankan 'source' pada file RC Anda."
  fi
}

# 🧰 Show installed versions
list_versions() {
  echo
  info "📦 Versi Flutter yang tersedia di $FLUTTER_BASE:"
  LISTED_VERSIONS=()
  local i=0
  for d in "$FLUTTER_BASE"/*/; do
    [ -d "$d" ] || continue
    ((i++))
    LISTED_VERSIONS+=("$(basename "$d")")
    echo "  $i) ${LISTED_VERSIONS[i-1]}"
  done
  if [ "$i" -eq 0 ]; then
    warn "  (Belum ada versi Flutter terpasang)"
  fi
  echo
}

# 🌐 Fetch Flutter releases index
fetch_releases_json() {
  curl -fsSL "$RELEASES_JSON_URL"
}

# 🔎 Get latest stable version from release index
get_latest_stable_version() {
  local json stable_hash stable_record stable_version
  json=$(fetch_releases_json) || return 1

  stable_hash=$(printf '%s' "$json" | tr -d '\n' | sed -n 's/.*"current_release"[[:space:]]*:[[:space:]]*{[^}]*"stable"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  [ -n "$stable_hash" ] || return 1

  # Ambil object release dengan hash stable (toleran terhadap spasi/urutan field)
  stable_record=$(printf '%s' "$json" | tr -d '\n' | sed -n "s/.*\\({[^{}]*\"hash\"[[:space:]]*:[[:space:]]*\"$stable_hash\"[^{}]*}\\).*/\\1/p")
  [ -n "$stable_record" ] || return 1

  stable_version=$(printf '%s' "$stable_record" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  [ -n "$stable_version" ] || return 1

  printf '%s\n' "$stable_version"
}

# 🆕 Show newest stable Flutter version
check_newest_version() {
  local latest
  latest=$(get_latest_stable_version) || {
    error "❌ Gagal mengambil versi terbaru dari Flutter releases index (cek koneksi internet / format index)"
    return
  }
  success "🆕 Versi Flutter stable terbaru: $latest"
}

# 🌀 Switch version
switch_version() {
  local choice ver_count selected_ver
  list_versions
  ver_count=${#LISTED_VERSIONS[@]}
  if [ "$ver_count" -eq 0 ]; then
    return
  fi

  read -rp "Masukkan nomor urutan versi yang mau diaktifkan: " choice
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$ver_count" ]; then
    warn "Nomor tidak valid. Pilih 1 sampai $ver_count."
    return
  fi

  selected_ver="${LISTED_VERSIONS[choice-1]}"
  rm -rf "$FLUTTER_LINK"
  ln -s "$FLUTTER_BASE/$selected_ver" "$FLUTTER_LINK"
  success "✅ Berhasil ganti ke: $selected_ver"
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
  local latest_stable="" raw_ver=""
  choose_chip
  echo

  latest_stable=$(get_latest_stable_version) || true
  if [ -n "$latest_stable" ]; then
    info "Versi stable terbaru saat ini adalah: $latest_stable"
  else
    warn "Tidak bisa mengecek versi stable terbaru sekarang. Lanjut input manual."
  fi

  read -rp "Masukkan versi Flutter (contoh: 3.24.3 atau flutter_3.24.3, kosongkan untuk stable): " raw_ver
  VER="${raw_ver#flutter_}"
  VER="${VER#flutter-}"
  VER="${VER#v}"

  if [ -z "$VER" ]; then
    if [ -n "$latest_stable" ]; then
      VER="$latest_stable"
    else
      VER=$(get_latest_stable_version) || {
        error "❌ Gagal menentukan versi stable terbaru"
        return
      }
    fi
    info "Menggunakan versi stable terbaru: $VER"
  fi

  if [ -d "$FLUTTER_BASE/$VER" ]; then
    warn "Versi $VER sudah ada di $FLUTTER_BASE"
    read -rp "Tetap download ulang? [y/N]: " REDOWNLOAD
    case "$REDOWNLOAD" in
      y|Y) ;;
      *) info "Download dibatalkan."; return ;;
    esac
  fi

  case "$CHIP" in
    arm64)
      ARCHIVE="flutter_macos_arm64_$VER-stable.zip"
      ;;
    intel)
      ARCHIVE="flutter_macos_$VER-stable.zip"
      ;;
  esac

  URL="$BASE_URL/stable/macos/$ARCHIVE"
  DEST="$FLUTTER_BASE/$VER"
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
    echo "4) Download versi Flutter"
    echo "5) Lihat versi Flutter aktif"
    echo "6) Jalankan 'flutter doctor'"
    echo "7) Cek versi Flutter stable terbaru"
    echo "8) Keluar"
    echo "======================================================"
    read -rp "Pilih opsi [1-8]: " CHOICE
    clear
    case "$CHOICE" in
      1) list_versions ;;
      2) switch_version ;;
      3) add_local ;;
      4) download_version ;;
      5) "$FLUTTER_LINK/bin/flutter" --version 2>/dev/null || warn "Belum ada versi aktif" ;;
      6) "$FLUTTER_LINK/bin/flutter" doctor 2>/dev/null || warn "Belum ada versi aktif" ;;
      7) check_newest_version ;;
      8) exit 0 ;;
      *) warn "Pilihan tidak valid." ;;
    esac
  done
}

main_menu
