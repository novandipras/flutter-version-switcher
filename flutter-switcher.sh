#!/usr/bin/env bash
# ====================================================
# Flutter Version Switcher for macOS (No FVM Needed)
# by ChatGPT — v2.1
# ====================================================
set -euo pipefail

FLUTTER_BASE="$HOME/flutter_versions"
FLUTTER_LINK="$HOME/flutter_active"
LEGACY_FLUTTER_LINK="$HOME/flutter"
LISTED_VERSIONS=()
SELECTED_VERSION=""
ACTION_CANCELLED=false

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

# 🖼️ Terminal UI helpers
clear_screen() {
  printf '\033[2J\033[H'
}

draw_header() {
  local title="$1"
  echo "╔══════════════════════════════════════════════╗"
  printf "║ %-44s ║\n" "$title"
  echo "╚══════════════════════════════════════════════╝"
}

pause_for_menu() {
  local key sequence
  echo
  echo "Tekan Enter atau Esc untuk kembali ke menu utama..."
  while true; do
    IFS= read -rsn1 key || return
    case "$key" in
      '')
        return
        ;;
      $'\x1b')
        sequence=""
        IFS= read -rsn2 -t 1 sequence || true
        return
        ;;
    esac
  done
}

pause_for_versions() {
  echo
  read -rp "Tekan Enter untuk kembali ke daftar versi..." _
}

read_input_or_escape() {
  local prompt="$1"
  local key
  INPUT_VALUE=""
  printf "%s" "$prompt"

  while IFS= read -rsn1 key; do
    case "$key" in
      '')
        echo
        return 0
        ;;
      $'\x1b')
        echo
        ACTION_CANCELLED=true
        return 1
        ;;
      $'\x7f'|$'\b')
        if [ -n "$INPUT_VALUE" ]; then
          INPUT_VALUE="${INPUT_VALUE%?}"
          printf '\b \b'
        fi
        ;;
      *)
        INPUT_VALUE+="$key"
        printf "%s" "$key"
        ;;
    esac
  done
}

get_active_version() {
  if [ -e "$FLUTTER_LINK" ]; then
    basename "$(cd "$FLUTTER_LINK" 2>/dev/null && pwd -P)"
  else
    echo "belum ada"
  fi
}

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
  echo "Esc) Batalkan dan kembali ke menu utama"
  if ! read_input_or_escape "Masukkan pilihan [1-2, default autodetect]: "; then
    return 1
  fi
  chip_choice="$INPUT_VALUE"

  case "$chip_choice" in
    1) CHIP="arm64" ;;
    2) CHIP="intel" ;;
    *) CHIP=$(detect_arch) ;;
  esac

  info "Menggunakan chip: $CHIP"
}

# 🔀 Migrate the old shortcut and keep a compatibility alias
migrate_active_link() {
  if [ -L "$LEGACY_FLUTTER_LINK" ] && [ ! -e "$FLUTTER_LINK" ]; then
    mv "$LEGACY_FLUTTER_LINK" "$FLUTTER_LINK"
    success "✅ Shortcut aktif dipindahkan ke $FLUTTER_LINK"
  fi

  if [ -e "$FLUTTER_LINK" ]; then
    if [ -L "$LEGACY_FLUTTER_LINK" ]; then
      rm -f "$LEGACY_FLUTTER_LINK"
    elif [ -e "$LEGACY_FLUTTER_LINK" ]; then
      warn "$LEGACY_FLUTTER_LINK bukan symlink; alias kompatibilitas tidak dibuat."
      return
    fi
    ln -s "$FLUTTER_LINK" "$LEGACY_FLUTTER_LINK"
  fi
}

# 🧭 Ensure PATH is added to shell configuration
ensure_path() {
  local path_line='export PATH="$HOME/flutter_active/bin:$PATH"'
  local rc

  # For zsh, also ensure .zprofile (login shells) and .zshrc (interactive)
  if [[ $SHELL == *"zsh"* ]]; then
    for rc in "$HOME/.zshrc" "$HOME/.zprofile"; do
      touch "$rc" 2>/dev/null || true
      if grep -q 'flutter/bin' "$rc" 2>/dev/null; then
        sed -i.bak 's#\$HOME/flutter/bin#\$HOME/flutter_active/bin#g' "$rc"
        rm -f "$rc.bak"
        success "✅ PATH lama diperbarui di $rc"
      elif ! grep -q 'flutter_active/bin' "$rc" 2>/dev/null; then
        echo "" >> "$rc"
        echo "# Flutter SDK (auto-added by flutter_switcher)" >> "$rc"
        echo "$path_line" >> "$rc"
        success "✅ Menambahkan PATH ke $rc"
      fi
    done
  else
    if grep -q 'flutter/bin' "$SHELL_RC" 2>/dev/null; then
      sed -i.bak 's#\$HOME/flutter/bin#\$HOME/flutter_active/bin#g' "$SHELL_RC"
      rm -f "$SHELL_RC.bak"
      success "✅ PATH lama diperbarui di $SHELL_RC"
    elif ! grep -q 'flutter_active/bin' "$SHELL_RC" 2>/dev/null; then
      echo "" >> "$SHELL_RC"
      echo "# Flutter SDK (auto-added by flutter_switcher)" >> "$SHELL_RC"
      echo "$path_line" >> "$SHELL_RC"
      success "✅ Menambahkan PATH ke $SHELL_RC"
    else
      info "PATH Flutter sudah ada di $SHELL_RC"
    fi
  fi

  # Export into current session so the script (and immediate commands) can use flutter
  export PATH="$HOME/flutter_active/bin:$PATH"

  if command -v flutter >/dev/null 2>&1; then
    success "Flutter tersedia di PATH"
  else
    warn "Belum ada Flutter SDK aktif. Tambahkan atau download versi melalui menu."
  fi
}

# 🧰 Load installed versions
load_versions() {
  LISTED_VERSIONS=()
  local d
  for d in "$FLUTTER_BASE"/*/; do
    [ -d "$d" ] || continue
    LISTED_VERSIONS+=("$(basename "$d")")
  done
}

# 🧰 Show installed versions
list_versions() {
  local i
  load_versions
  clear_screen
  draw_header "FLUTTER SDK TERPASANG"
  echo
  info "📦 Versi Flutter yang tersedia di $FLUTTER_BASE:"
  for ((i=0; i<${#LISTED_VERSIONS[@]}; i++)); do
    echo "  $((i+1))) ${LISTED_VERSIONS[i]}"
  done
  if [ "${#LISTED_VERSIONS[@]}" -eq 0 ]; then
    warn "  (Belum ada versi Flutter terpasang)"
  fi
  echo
}

# 🎛️ Select a version using arrow keys
select_version_interactive() {
  local title="${1:-PILIH FLUTTER SDK AKTIF}"
  local hint="${2:-↑/↓ pilih • Enter aktifkan • Esc kembali}"
  local selected=0 key sequence i active_path="" version_path marker
  load_versions
  SELECTED_VERSION=""
  ACTION_CANCELLED=false

  if [ "${#LISTED_VERSIONS[@]}" -eq 0 ]; then
    list_versions
    ACTION_CANCELLED=true
    return 1
  fi

  if [ -e "$FLUTTER_LINK" ]; then
    active_path=$(cd "$FLUTTER_LINK" 2>/dev/null && pwd -P) || true
  fi

  while true; do
    clear_screen
    draw_header "$title"
    echo

    for ((i=0; i<${#LISTED_VERSIONS[@]}; i++)); do
      marker=""
      version_path=$(cd "$FLUTTER_BASE/${LISTED_VERSIONS[i]}" && pwd -P)
      if [ -n "$active_path" ] && [ "$version_path" = "$active_path" ]; then
        marker=" (aktif)"
      fi

      if [ "$i" -eq "$selected" ]; then
        printf '\033[7m  > %s%s  \033[0m\n' "${LISTED_VERSIONS[i]}" "$marker"
      else
        printf '    %s%s\n' "${LISTED_VERSIONS[i]}" "$marker"
      fi
    done

    echo
    echo "$hint"

    IFS= read -rsn1 key || return 1
    case "$key" in
      $'\x1b')
        sequence=""
        # Bash 3.2 bawaan macOS hanya mendukung timeout bilangan bulat.
        IFS= read -rsn2 -t 1 sequence || true
        case "$sequence" in
          '[A')
            if [ "$selected" -gt 0 ]; then
              ((selected-=1))
            else
              selected=$((${#LISTED_VERSIONS[@]}-1))
            fi
            ;;
          '[B')
            selected=$(((selected+1) % ${#LISTED_VERSIONS[@]}))
            ;;
          '')
            ACTION_CANCELLED=true
            return 1
            ;;
        esac
        ;;
      '')
        SELECTED_VERSION="${LISTED_VERSIONS[selected]}"
        clear_screen
        return 0
        ;;
    esac
  done
}

# 🎛️ Select an action using arrow keys
select_version_action() {
  local version="$1"
  local actions=("Jadikan SDK Aktif" "Upgrade SDK dan Sesuaikan Nama Folder" "Hapus SDK Ini")
  local selected=0 key sequence i
  SELECTED_VERSION=""
  ACTION_CANCELLED=false

  while true; do
    clear_screen
    draw_header "AKSI UNTUK $version"
    echo
    for ((i=0; i<${#actions[@]}; i++)); do
      if [ "$i" -eq "$selected" ]; then
        printf '\033[7m  > %s  \033[0m\n' "${actions[i]}"
      else
        printf '    %s\n' "${actions[i]}"
      fi
    done
    echo
    echo "↑/↓ pilih • Enter jalankan • Esc daftar versi"

    IFS= read -rsn1 key || return 1
    case "$key" in
      $'\x1b')
        sequence=""
        IFS= read -rsn2 -t 1 sequence || true
        case "$sequence" in
          '[A') selected=$(((selected-1+${#actions[@]}) % ${#actions[@]})) ;;
          '[B') selected=$(((selected+1) % ${#actions[@]})) ;;
          '') ACTION_CANCELLED=true; return 1 ;;
        esac
        ;;
      '')
        SELECTED_VERSION="$selected"
        return 0
        ;;
    esac
  done
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

# ✅ Activate an installed Flutter SDK
activate_version() {
  local selected_ver="$1"
  rm -rf "$FLUTTER_LINK"
  ln -s "$FLUTTER_BASE/$selected_ver" "$FLUTTER_LINK"
  migrate_active_link
  success "✅ Berhasil ganti ke: $selected_ver"
  ensure_path
  "$FLUTTER_LINK/bin/flutter" --version || warn "Flutter belum terdeteksi. Coba buka terminal baru."
}

# 🔢 Read the actual Flutter version from an SDK
get_sdk_version() {
  local sdk_path="$1"
  "$sdk_path/bin/flutter" --version 2>/dev/null | awk 'NR == 1 && $1 == "Flutter" { print $2; exit }'
}

# ⬆️ Update SDK and rename its folder to the actual version
update_version() {
  local selected_ver="$1"
  local target="$FLUTTER_BASE/$selected_ver"
  local target_path active_path="" actual_version destination

  info "⬆️ Mengupdate Flutter $selected_ver ..."
  if ! "$target/bin/flutter" upgrade; then
    error "Update Flutter gagal."
    return
  fi

  actual_version=$(get_sdk_version "$target")
  if [ -z "$actual_version" ]; then
    error "Versi Flutter setelah update tidak dapat dideteksi."
    return
  fi

  destination="$FLUTTER_BASE/$actual_version"
  target_path=$(cd "$target" && pwd -P)
  if [ -e "$FLUTTER_LINK" ]; then
    active_path=$(cd "$FLUTTER_LINK" 2>/dev/null && pwd -P) || true
  fi

  if [ "$target" = "$destination" ]; then
    success "✅ Flutter $actual_version sudah versi terbaru."
    return
  fi

  if [ -e "$destination" ]; then
    error "Folder tujuan sudah ada: $destination"
    warn "SDK sudah ter-update, tetapi folder belum diubah namanya."
    return
  fi

  mv "$target" "$destination"
  if [ -n "$active_path" ] && [ "$target_path" = "$active_path" ]; then
    rm -f "$FLUTTER_LINK"
    ln -s "$destination" "$FLUTTER_LINK"
    migrate_active_link
  fi
  success "✅ Flutter diperbarui dan folder diubah: $selected_ver → $actual_version"
}

# 🗑️ Delete a selected SDK
delete_selected_version() {
  local selected_ver="$1"
  local target="$FLUTTER_BASE/$selected_ver"
  local target_path active_path="" CONFIRM

  target_path=$(cd "$target" && pwd -P)
  if [ -e "$FLUTTER_LINK" ]; then
    active_path=$(cd "$FLUTTER_LINK" 2>/dev/null && pwd -P) || true
  fi

  if [ -n "$active_path" ] && [ "$target_path" = "$active_path" ]; then
    error "Tidak dapat menghapus versi yang sedang aktif: $selected_ver"
    warn "Jadikan SDK lain sebagai SDK aktif terlebih dahulu."
    return
  fi

  read -rp "Yakin ingin menghapus $selected_ver? [y/N]: " CONFIRM
  case "$CONFIRM" in
    y|Y)
      rm -rf -- "$target"
      success "✅ Versi berhasil dihapus: $selected_ver"
      ;;
    *)
      info "Penghapusan dibatalkan."
      ;;
  esac
}

# 📦 Browse installed SDKs and choose an action
manage_versions() {
  local selected_ver action_index

  while true; do
    if ! select_version_interactive \
      "KELOLA VERSI FLUTTER" \
      "↑/↓ pilih • Enter buka aksi • Esc menu utama"; then
      return
    fi
    selected_ver="$SELECTED_VERSION"

    if ! select_version_action "$selected_ver"; then
      continue
    fi
    action_index="$SELECTED_VERSION"

    clear_screen
    draw_header "AKSI VERSI $selected_ver"
    echo
    case "$action_index" in
      0) activate_version "$selected_ver" ;;
      1) update_version "$selected_ver" ;;
      2) delete_selected_version "$selected_ver" ;;
    esac
    pause_for_versions
  done
}

# 🧱 Add local version manually
add_local() {
  local SRC DEF_NAME NAME DEST
  read -rp "Masukkan path ke folder Flutter lokal: " SRC
  [ -d "$SRC" ] || { error "Folder tidak ditemukan"; return; }
  DEF_NAME=$(basename "$SRC")
  read -rp "Nama folder di flutter_versions (default: $DEF_NAME): " NAME
  NAME="${NAME:-$DEF_NAME}"
  DEST="$FLUTTER_BASE/$NAME"
  if [ -e "$DEST" ]; then
    error "Versi sudah ada: $DEST"
    return
  fi
  cp -a "$SRC" "$DEST"
  success "✅ Ditambahkan versi lokal: $DEST"
}

# 🌍 Download Flutter version
download_version() {
  local latest_stable="" raw_ver="" VER ARCHIVE URL DEST TMP_ZIP REDOWNLOAD
  ACTION_CANCELLED=false
  if ! choose_chip; then
    return
  fi
  echo

  latest_stable=$(get_latest_stable_version) || true
  if [ -n "$latest_stable" ]; then
    info "Versi stable terbaru saat ini adalah: $latest_stable"
  else
    warn "Tidak bisa mengecek versi stable terbaru sekarang. Lanjut input manual."
  fi

  if ! read_input_or_escape "Masukkan versi Flutter (kosongkan untuk stable, Esc untuk batal): "; then
    return
  fi
  raw_ver="$INPUT_VALUE"
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
    if ! read_input_or_escape "Tetap download ulang? [y/N, Esc untuk batal]: "; then
      return
    fi
    REDOWNLOAD="$INPUT_VALUE"
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
  migrate_active_link
  ensure_path
  while true; do
    local active_version installed_count
    load_versions
    active_version=$(get_active_version)
    installed_count=${#LISTED_VERSIONS[@]}

    clear_screen
    draw_header "FLUTTER VERSION SWITCHER"
    printf "  Aktif     : %s\n" "$active_version"
    printf "  Terpasang : %s versi\n" "$installed_count"
    echo
    echo "  1) Kelola Flutter SDK"
    echo "  2) Impor Flutter SDK dari Folder"
    echo "  3) Unduh Flutter SDK"
    echo "  4) Lihat Informasi SDK Aktif"
    echo "  5) Jalankan Flutter doctor"
    echo "  6) Cek Versi Stable Terbaru"
    echo "  7) Keluar"
    echo
    read -rp "Pilih menu [1-7]: " CHOICE
    ACTION_CANCELLED=false
    case "$CHOICE" in
      1)
        manage_versions
        ;;
      2)
        clear_screen
        draw_header "IMPOR FLUTTER SDK DARI FOLDER"
        echo
        add_local
        pause_for_menu
        ;;
      3)
        clear_screen
        draw_header "UNDUH FLUTTER SDK"
        download_version
        if [ "$ACTION_CANCELLED" = false ]; then
          pause_for_menu
        fi
        ;;
      4)
        clear_screen
        draw_header "INFORMASI SDK AKTIF"
        echo
        "$FLUTTER_LINK/bin/flutter" --version 2>/dev/null || warn "Belum ada versi aktif"
        pause_for_menu
        ;;
      5)
        clear_screen
        draw_header "FLUTTER DOCTOR"
        echo
        "$FLUTTER_LINK/bin/flutter" doctor 2>/dev/null || warn "Belum ada versi aktif"
        pause_for_menu
        ;;
      6)
        clear_screen
        draw_header "CEK VERSI STABLE TERBARU"
        echo
        check_newest_version
        pause_for_menu
        ;;
      7)
        clear_screen
        success "Flutter Switcher ditutup."
        return 0
        ;;
      *)
        warn "Pilihan tidak valid."
        sleep 1
        ;;
    esac
  done
}

main_menu
