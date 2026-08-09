#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="edp-healthcard-proxy"
APP_TITLE="EDP Gesundheitskarte Proxy"
REPO_OWNER="ThomasKra"
REPO_NAME="edp_healthcard_proxy"
DEFAULT_BRANCH="master"
REPO_BRANCH="$DEFAULT_BRANCH"

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN="${HOME}/.local/bin"
APP_BASE="${HOME}/.local/opt"
APP_DIR="${APP_BASE}/${APP_NAME}"

DESKTOP_DIR="${XDG_DATA_HOME}/applications"
AUTOSTART_DIR="${XDG_CONFIG_HOME}/autostart"
DESKTOP_FILE="${DESKTOP_DIR}/${APP_NAME}.desktop"
AUTOSTART_FILE="${AUTOSTART_DIR}/${APP_NAME}.desktop"
BIN_LAUNCHER="${LOCAL_BIN}/${APP_NAME}"

WORK_DIR="$(mktemp -d)"
DOWNLOAD_FILE="${WORK_DIR}/source.tar.gz"
EXTRACT_DIR="${WORK_DIR}/extract"

ARCHIVE_URL=""
SOURCE_DIR=""

ENTRYPOINT="main_gui.py"

ICON_FILE="Icon.png"
ICON_DIR="icons"

APT_PACKAGES=(
  python3
  python3-pyqt5
  python3-pyscard
  python3-xmltodict
  pcscd
  pcsc-tools
  tar
  ca-certificates
  curl
)

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

die() {
  echo "Fehler: $*" >&2
  exit 1
}

info() {
  echo "[INFO] $*"
}

usage() {
  cat <<EOF2
Verwendung:
  $0 [--branch BRANCH]
  $0 [-b BRANCH]

Optionen:
  -b, --branch BRANCH   GitHub-Branch für den Download (Standard: ${DEFAULT_BRANCH})
  -h, --help            Diese Hilfe anzeigen

Beispiele:
  $0
  $0 --branch master
  $0 -b feature/qt-gui
EOF2
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -b|--branch)
        [[ $# -ge 2 ]] || die "Option $1 erwartet einen Branchnamen."
        [[ -n "$2" ]] || die "Der Branchname darf nicht leer sein."
        REPO_BRANCH="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unbekannter Parameter: $1. Nutze --help für die Verwendung."
        ;;
    esac
  done

  [[ -n "$REPO_BRANCH" ]] || die "Der Branchname darf nicht leer sein."
  ARCHIVE_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${REPO_BRANCH}.tar.gz"
}

check_prerequisites() {
  command -v dpkg >/dev/null 2>&1 \
    || die "dpkg wurde nicht gefunden. Dieses Script ist für Debian gedacht."
}

check_apt_packages() {
  local missing=()
  local package

  for package in "${APT_PACKAGES[@]}"; do
    if ! dpkg -s "$package" >/dev/null 2>&1; then
      missing+=("$package")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    echo "Die Installation wurde nicht gestartet, weil erforderliche apt-Pakete fehlen:" >&2
    printf '  %s\n' "${missing[@]}" >&2
    echo >&2
    echo "Bitte installiere sie zuerst mit:" >&2
    echo "  sudo apt update && sudo apt install -y ${missing[*]}" >&2
    exit 1
  fi
}

download_source() {
  info "Lade Quellcode von GitHub herunter (Branch: ${REPO_BRANCH}, ${ARCHIVE_URL})..."

  mkdir -p "$EXTRACT_DIR"
  curl -fL --retry 3 --connect-timeout 15 \
    -o "$DOWNLOAD_FILE" \
    "$ARCHIVE_URL" \
    || die "Download des Quellcodes fehlgeschlagen."

  tar -xzf "$DOWNLOAD_FILE" -C "$EXTRACT_DIR" \
    || die "Entpacken des Quellcodes fehlgeschlagen."

  SOURCE_DIR="$(find "$EXTRACT_DIR" -mindepth 1 -maxdepth 1 -type d -print -quit)"
  [[ -n "$SOURCE_DIR" ]] \
    || die "Konnte das entpackte Quellverzeichnis nicht ermitteln."

  [[ -f "${SOURCE_DIR}/gui.py" ]] \
    || die "gui.py wurde im heruntergeladenen Branch nicht gefunden."
}

install_files() {
  info "Installiere den aktuellen Quellcode nach ${APP_DIR}..."

  mkdir -p "$APP_BASE" "$LOCAL_BIN" "$DESKTOP_DIR" "$AUTOSTART_DIR"
  rm -rf "$APP_DIR"
  mkdir -p "$APP_DIR"

  cp -a "${SOURCE_DIR}/." "$APP_DIR/"

  rm -rf \
    "$APP_DIR/.git" \
    "$APP_DIR/.venv" \
    "$APP_DIR/output"

  find "$APP_DIR" -type d -name '__pycache__' -prune -exec rm -rf {} +
  find "$APP_DIR" -type f -name '*.pyc' -delete
}

create_launcher() {
  cat > "$BIN_LAUNCHER" <<EOF2
#!/usr/bin/env bash
set -euo pipefail

cd "$APP_DIR"
python3 "$APP_DIR/$ENTRYPOINT" "\$@"
EOF2

  chmod 0755 "$BIN_LAUNCHER"
}

create_desktop_file() {
  local icon_path="$APP_DIR/$ICON_DIR/$ICON_FILE"
  local icon_value="$icon_path"

  if [[ ! -f "$icon_path" ]]; then
    icon_value="applications-system"
  fi

  cat > "$DESKTOP_FILE" <<EOF2
[Desktop Entry]
Type=Application
Version=1.0
Name=${APP_TITLE}
Comment=Überwachung und Auslesen von Gesundheitskartenlesern
Exec=${BIN_LAUNCHER}
Icon=${icon_value}
Terminal=false
Categories=Utility;Office;System;
StartupNotify=true
EOF2
}

ask_autostart() {
  read -r -p "Autostart für diesen Benutzer einrichten? [y/N] " reply || true

  case "${reply:-N}" in
    y|Y|yes|YES)
      cp "$DESKTOP_FILE" "$AUTOSTART_FILE"
      info "Autostart aktiviert: $AUTOSTART_FILE"
      ;;
    *)
      info "Autostart nicht aktiviert."
      ;;
  esac
}

print_summary() {
  cat <<EOF2

Installation abgeschlossen.

Quelle:
  ${ARCHIVE_URL}

Branch:
  ${REPO_BRANCH}

Anwendungspfad:
  ${APP_DIR}

Starter:
  ${BIN_LAUNCHER}

Desktop-Datei:
  ${DESKTOP_FILE}

Starten:
  ${BIN_LAUNCHER}
EOF2
}

main() {
  parse_args "$@"
  check_prerequisites
  check_apt_packages
  download_source
  install_files
  create_launcher
  create_desktop_file
  ask_autostart
  print_summary
}

main "$@"