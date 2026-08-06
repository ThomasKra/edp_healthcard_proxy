#!/usr/bin/env python3
"""
Einstiegspunkt für die Qt-GUI-Anwendung.
Ausführung mit: python main_gui.py
"""

import sys
from PyQt5.QtWidgets import QApplication
from gui import CardReaderGUI


def main():
    """Starte die GUI-Anwendung."""
    app = QApplication(sys.argv)
    window = CardReaderGUI()
    window.show()
    sys.exit(app.exec_())


if __name__ == "__main__":
    main()
