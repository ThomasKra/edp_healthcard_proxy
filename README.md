# Installationsanleitung
Diese Installationsanleitung bezieht sich auf Debian Systeme.

# Benötigte Packages:
- python3
- python3-pyqt5
- python3-pyscard
- python3-xmltodict
- pcscd
- pcsc-tools
- tar
- ca-certificates
- curl

vorher als Root über `apt install python3 python3-pyqt5 python3-pyscard python3-xmltodict pcscd pcsc-tools tar ca-certificates curl` installieren.

Dann kann das Programm für den aktuellen Nutzer installiert werden:
`bash <(curl -fsSL https://raw.githubusercontent.com/ThomasKra/edp_healthcard_proxy/master/install_user.sh)`
Falls ein spezieller Branch installiert werden soll, dann kann dieser als Paramter mit angegeben werden:
`bash <(curl -fsSL https://raw.githubusercontent.com/ThomasKra/edp_healthcard_proxy/master/install_user.sh) --branch THE_BRANCHNAME`

  Bei der Installation wird geprüft, ob die benötigten Pakete installiert sind.
  Es wird abgefragt, ob das Programm beim Login gestartet werden soll.