#!/usr/bin/env bash
set -Eeuo pipefail

# Installer für EDP-Gesundheitskarte-Proxy unter Debian/Cinnamon.
# Das Script wird aus dem Projektverzeichnis heraus ausgeführt.
# Erwartete Dateien: main.py oder gui.py sowie optional
# icons/edp-icon-red.png.

APP_NAME="edp-healthcard-proxy"
APP_TITLE="EDP Gesundheitskarte Proxy"
INSTALL_DIR="/opt/${APP_NAME}"
LAUNCHER="/usr/local/bin/${APP_NAME}"
DESKTOP_FILE="/usr/share/applications/${APP_NAME}.desktop"
ICON_FILENAME="Icon.png"
ICON_DIR="${INSTALL_DIR}/icons"
ICON_FILE="${ICON_DIR}/${ICON_FILENAME}"

APT_PACKAGES=(
    python3
    python3-pyqt5
    python3-pyscard
    python3-xmltodict
    pcscd
    pcsc-tools
)

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

log() {
    printf '\n==> %s\n' "$*"
}

fail() {
    printf 'FEHLER: %s\n' "$*" >&2
    exit 1
}

run_as_root() {
    if [[ ${EUID} -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        fail "Root-Rechte erforderlich. Bitte als root oder mit installiertem sudo ausführen."
    fi
}

find_entrypoint() {
    if [[ -f "${SOURCE_DIR}/main_gui.py" ]]; then
        ENTRYPOINT="main_gui.py"
    else
        fail "Kein Einstiegspunkt gefunden. Erwartet wird main_gui.py"
    fi
}

install_system_packages() {
    log "Installiere Debian-Abhängigkeiten"
    run_as_root apt-get update
    run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_PACKAGES[@]}"
}

install_project() {
    log "Installiere Projekt nach ${INSTALL_DIR}"

    run_as_root install -d -m 0755 "${INSTALL_DIR}"
    run_as_root cp -a "${SOURCE_DIR}/." "${INSTALL_DIR}/"

    # Entwicklungs- und lokale Laufzeitreste aus der Installation entfernen.
    run_as_root rm -rf \
        "${INSTALL_DIR}/.git" \
        "${INSTALL_DIR}/__pycache__"
    run_as_root find "${INSTALL_DIR}" -type d -name '__pycache__' -prune -exec rm -rf {} +
    run_as_root find "${INSTALL_DIR}" -type f -name '*.pyc' -delete

    if [[ -f "${SOURCE_DIR}/icons/${ICON_FILENAME}" ]]; then
        run_as_root install -d -m 0755 "${ICON_DIR}"
        run_as_root install -m 0644 \
            "${SOURCE_DIR}/icons/${ICON_FILENAME}" \
            "${ICON_FILE}"
    else
        printf 'WARNUNG: icons/${ICON_FILENAME} nicht gefunden; Standard-Icon wird verwendet.\n' >&2
    fi
}

create_launcher() {
    log "Erzeuge Kommando ${LAUNCHER}"

    run_as_root tee "${LAUNCHER}" >/dev/null <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
cd "${INSTALL_DIR}"
exec /usr/bin/python3 "${INSTALL_DIR}/${ENTRYPOINT}" "\$@"
EOF
    run_as_root chmod 0755 "${LAUNCHER}"
}

create_desktop_file() {
    log "Erzeuge Desktop-Datei"

    local icon_value="applications-system"
    if [[ -f "${SOURCE_DIR}/icons/${ICON_FILENAME}" ]]; then
        icon_value="${ICON_FILE}"
    fi

    run_as_root tee "${DESKTOP_FILE}" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=${APP_TITLE}
Comment=Überwachung des Gesundheitskartenlesers
Exec=${LAUNCHER}
Icon=${icon_value}
Terminal=false
Categories=Utility;System;
StartupNotify=true
EOF
    run_as_root chmod 0644 "${DESKTOP_FILE}"
}

configure_pcscd() {
    log "Aktiviere PC/SC-Dienst"
    run_as_root systemctl enable pcscd.service >/dev/null 2>&1 || true
    run_as_root systemctl restart pcscd.service >/dev/null 2>&1 || true
}

validate_installation() {
    log "Prüfe Installation"

    [[ -x "${LAUNCHER}" ]] || fail "Launcher wurde nicht angelegt."
    [[ -f "${DESKTOP_FILE}" ]] || fail "Desktop-Datei wurde nicht angelegt."

    /usr/bin/python3 - <<'PY'
import importlib

for module in ("PyQt5", "smartcard", "xmltodict"):
    importlib.import_module(module)

print("Python-Abhängigkeiten: OK")
PY

    if systemctl is-active --quiet pcscd.service; then
        printf 'pcscd: aktiv\n'
    else
        printf 'WARNUNG: pcscd ist nicht aktiv. Prüfe später mit: systemctl status pcscd\n' >&2
    fi
}

print_summary() {
    cat <<EOF

Installation abgeschlossen.

Starten:
  ${LAUNCHER}

Installationsverzeichnis:
  ${INSTALL_DIR}

Desktop-Datei:
  ${DESKTOP_FILE}

Tray-/Anwendungs-Icon:
  ${ICON_FILE}

Smartcard-Test:
  pcsc_scan

Hinweis:
  Die Anwendung verwendet direkt /usr/bin/python3 und kein virtuelles Environment.
  Der Autostart kann in Cinnamon unter "Startprogramme" mit folgendem Befehl
  eingerichtet werden:

  ${LAUNCHER}
EOF
}

main() {
    find_entrypoint
    install_system_packages
    install_project
    create_launcher
    create_desktop_file
    configure_pcscd
    validate_installation
    print_summary
}

main "$@"