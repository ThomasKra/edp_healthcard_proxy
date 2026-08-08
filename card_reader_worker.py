"""
Hintergrund-Worker-Thread für Kartenlese-Operationen.
Sendet Signale für Statusupdates und Log-Events.
"""

from PyQt5.QtCore import QThread, pyqtSignal
from datetime import datetime
import egk


class CardReaderWorker(QThread):
    """Worker-Thread, der Kartenlese-Operationen durchführt."""
    
    # Signale
    reader_connected = pyqtSignal(bool)  # bool: True wenn Lesegerät verbunden
    log_message = pyqtSignal(str)  # str: Log-Nachricht
    
    def __init__(self, polling_interval=1000):
        """
        Initialisiere den Worker.
        
        Args:
            polling_interval (int): Zeit in ms zwischen Kartenlese-Überprüfungen
        """
        super().__init__()
        self.polling_interval = polling_interval
        self.is_running = True
        self.last_reader_state = None
        
    def run(self):
        """Hauptschleife - Kontinuierlich Lesegerät überprüfen und Karten lesen."""
        from PyQt5.QtCore import QTimer
        
        self.log_message.emit(f"[{self._get_timestamp()}] Kartenlese-Worker gestartet")
        
        # Erstelle einen Timer für Abfragen
        timer = QTimer()
        timer.timeout.connect(self._check_reader_and_read_card)
        timer.start(self.polling_interval)
        
        # Halte den Thread am Laufen
        self.exec_()
        
    def _get_timestamp(self):
        """Erhalte aktuellen Zeitstempel im HH:MM:SS Format."""
        return datetime.now().strftime("%H:%M:%S")
    
    def _check_reader_and_read_card(self):
        """Überprüfe, ob Lesegerät verbunden ist."""
        if not self.is_running:
            self.quit()
            return
        
        # Überprüfe Lesegerät-Status
        reader_available = self._is_reader_available()
        
        # Sende Signal, wenn Status sich geändert hat
        if reader_available != self.last_reader_state:
            self.reader_connected.emit(reader_available)
            self.last_reader_state = reader_available
            
            if reader_available:
                self.log_message.emit(f"[{self._get_timestamp()}] ✓ Kartenlesegerät verbunden")
            else:
                self.log_message.emit(f"[{self._get_timestamp()}] ✗ Kartenlesegerät getrennt")
    
    def _is_reader_available(self):
        """Überprüfe, ob ein Kartenlesegerät verfügbar ist."""
        try:
            from smartcard.System import readers
            available_readers = readers()
            return len(available_readers) > 0
        except Exception:
            return False
    
    def stop(self):
        """Stoppe den Worker-Thread."""
        self.is_running = False
        self.quit()
        self.wait()
