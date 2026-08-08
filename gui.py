"""
Qt-Benutzeroberfläche für EDP-Gesundheitskarte-Proxy.
Zeigt Kartenlese-Gerätestatus und Log der Kartenlese-Events an.
"""

from PyQt5.QtWidgets import QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QLabel, QTextEdit,  QSystemTrayIcon, QMenu, QAction
from PyQt5.QtCore import Qt, QSize, pyqtSignal, QObject
from PyQt5.QtGui import QFont, QIcon
from threading import Thread
from card_reader_worker import CardReaderWorker
from http.server import BaseHTTPRequestHandler, HTTPServer, ThreadingHTTPServer
from datetime import datetime
import json
import egk
from smartcard.Exceptions import NoCardException, CardConnectionException

class GuiLogBridge(QObject):
    message = pyqtSignal(str)
class HealthCardHTTPServer(ThreadingHTTPServer):
    def __init__(self, server_address, handler_class, log_bridge):
        super().__init__(server_address, handler_class)
        self.log_bridge = log_bridge

        self.log_bridge.message.emit('HTTPServer started')

class HealthCardRequestHandler(BaseHTTPRequestHandler):

    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
    def do_HEAD(self):
        self._set_headers()
        
    # GET sends back a Hello world message
    def do_GET(self):
        self._set_headers()
        try:
          json_str = json.dumps(egk.read_egk())
          self.wfile.write(bytes(json_str.encode(encoding='utf-8')))
          self.server.log_bridge.message.emit("Lesen erfolgreich")
        except NoCardException:
            self.server.log_bridge.message.emit("Lesen fehlgeschlagen - keine Karte gesteckt")
        except CardConnectionException:
            self.server.log_bridge.message.emit("Lesen fehlgeschlagen - Karte steckt nicht richtig")
        except Exception as e:
            self.server.log_bridge.message.emit(f"Lesen fehlgeschlagen - {str(e)}")

class CardReaderGUI(QMainWindow):
    """Hauptfenster für die Kartenlese-Geräteüberwachung."""
    
    def __init__(self):
        super().__init__()
        self.worker = None
        self.log_bridge = GuiLogBridge()
        self.log_bridge.message.connect(self.add_log)

        self.init_ui()
        self.start_monitoring()
        self._allow_close = False
        self.init_tray()
        self.start_http_server()

        
    def init_ui(self):
        """Initialisiere die Benutzeroberfläche."""
        self.setWindowTitle("EDP-GK-Proxy - Kartenleser-Überwachung")
        min_height = 200
        min_width = 500
        self.setGeometry(100, 100, min_width, min_height)
        self.setMinimumSize(QSize(min_width, min_height))
        self.setStyleSheet(self._get_stylesheet())
        
        # Erstelle zentrales Widget und Hauptlayout
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setSpacing(10)
        main_layout.setContentsMargins(15, 15, 15, 15)
        
        # Kopfzeilenbereich
        header_layout = QHBoxLayout()
        
        # Status-Indikator
        self.status_indicator = QLabel("⚫")
        self.status_indicator.setStyleSheet("color: gray; font-size: 20px;")
        self.status_indicator.setToolTip("Kartenlese-Gerät-Status: Getrennt")
        header_layout.addWidget(self.status_indicator)
        
        self.status_text = QLabel("Wird initialisiert...")
        self.status_text.setStyleSheet("color: gray; font-weight: bold; font-size: 12px;")
        header_layout.addWidget(self.status_text)

        header_layout.addStretch()
        
        main_layout.addLayout(header_layout)
        
        # Log-Bereich Beschriftung
        log_label = QLabel("Ereignisprotokoll:")
        log_font = QFont()
        log_font.setPointSize(11)
        log_font.setBold(True)
        log_label.setFont(log_font)
        main_layout.addWidget(log_label)
        
        # Log-Anzeige
        self.log_text = QTextEdit()
        self.log_text.setReadOnly(True)
        self.log_text.setFont(QFont("Courier", 9))
        main_layout.addWidget(self.log_text)

    def start_http_server(self):
        server_port = 2080
        server_address = ('', server_port)
        self.http_server = HealthCardHTTPServer(server_address, HealthCardRequestHandler, self.log_bridge)
        self.http_thread = Thread(
            target=self.http_server.serve_forever,
            daemon=True,
        )

        self.http_thread.start()

        
    def _get_stylesheet(self):
        """Gebe benutzerdefinierten Stylesheet für die Anwendung zurück."""
        return """
            QMainWindow {
                background-color: #f5f5f5;
            }
            QLabel {
                color: #333;
            }
            QTextEdit {
                background-color: white;
                color: #333;
                border: 1px solid #ccc;
                border-radius: 4px;
                padding: 5px;
            }
            QStatusBar {
                background-color: #e0e0e0;
                color: #333;
            }
        """
    
    def add_log(self, message, *, timestamp = None):
        """Füge eine Nachricht zum Log hinzu."""
        timestamp = timestamp if timestamp is not None else datetime.now().strftime("%H:%M:%S")
        log_message = f"[{timestamp}] {message}"
        self.log_text.append(log_message)
        
        # Automatisches Scrollen nach unten
        scrollbar = self.log_text.verticalScrollBar()
        scrollbar.setValue(scrollbar.maximum())
        if hasattr(self, "tray_icon") and self.tray_icon.supportsMessages():
          self.tray_icon.showMessage(
              "EDP-Gesundheitskarte-Proxy",
              log_message,
              QSystemTrayIcon.Information,
              5000
          )
    
    def on_reader_connected(self, connected):
        """Verwalte Änderung des Kartenlese-Gerät-Verbindungsstatus."""
        if connected:
            self.status_indicator.setText("🟢")
            self.status_indicator.setStyleSheet("color: #4CAF50; font-size: 20px;")
            self.status_indicator.setToolTip("Kartenlese-Gerät-Status: Verbunden")
            self.status_text.setText("Verbunden")
            self.status_text.setStyleSheet("color: #4CAF50; font-weight: bold; font-size: 12px;")
        else:
            self.status_indicator.setText("🔴")
            self.status_indicator.setStyleSheet("color: #f44336; font-size: 20px;")
            self.status_indicator.setToolTip("Kartenlese-Gerät-Status: Getrennt")
            self.status_text.setText("Getrennt")
            self.status_text.setStyleSheet("color: #f44336; font-weight: bold; font-size: 12px;")
    
    def on_log_message(self, message):
        """Verwalte Log-Nachricht vom Worker."""
        self.add_log(message)
    
    def start_monitoring(self):
        """Starte die Kartenlese-Geräteüberwachung."""
        self.add_log("Starte Kartenlese-Geräteüberwachung...")
        
        # Erstelle und starte Worker-Thread
        self.worker = CardReaderWorker(polling_interval=1000)
        self.worker.reader_connected.connect(self.on_reader_connected)
        self.worker.log_message.connect(self.on_log_message)
        self.worker.start()

    def stop_http_server(self):
      if getattr(self, "http_server", None):
          self.http_server.shutdown()
          self.http_server.server_close()
          self.http_server = None
    
    def closeEvent(self, event):
        """Verwalte Fenster-Schließ-Event."""
        if self._allow_close:
          if self.worker:
              self.worker.stop()
          self.stop_http_server()
          event.accept()
        else:
          self.hide()
          self.tray_icon.showMessage(
              "EDP-Gesundheitskarte-Proxy",
              "Die Anwendung läuft weiter im Infobereich.",
              QSystemTrayIcon.Information,
              3000
          )
          event.ignore()

    def init_tray(self):
      self.tray_icon = QSystemTrayIcon(self)

      icon = QIcon.fromTheme("media-flash")
      if icon.isNull():
          icon = self.style().standardIcon(self.style().SP_ComputerIcon)

      self.tray_icon.setIcon(icon)
      self.setWindowIcon(icon)
      self.tray_icon.setToolTip("EDP-Gesundheitskarte-Proxy")

      tray_menu = QMenu()

      show_action = QAction("Anzeigen", self)
      hide_action = QAction("Verstecken", self)
      quit_action = QAction("Beenden", self)

      show_action.triggered.connect(self.show_window)
      hide_action.triggered.connect(self.hide)
      quit_action.triggered.connect(self.quit_application)

      tray_menu.addAction(show_action)
      tray_menu.addAction(hide_action)
      tray_menu.addSeparator()
      tray_menu.addAction(quit_action)

      self.tray_icon.setContextMenu(tray_menu)
      self.tray_icon.activated.connect(self.on_tray_activated)
      self.tray_icon.show()

    def show_window(self):
        self.show()
        self.raise_()
        self.activateWindow()

    def on_tray_activated(self, reason):
        if reason == QSystemTrayIcon.Trigger:
            if self.isVisible():
                self.hide()
            else:
                self.show_window()

    def quit_application(self):
        self._allow_close = True
        self.tray_icon.hide()
        if self.worker:
            self.worker.stop()
        self.close()