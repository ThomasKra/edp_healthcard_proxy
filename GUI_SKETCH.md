# Qt-GUI Skizze für EDP-Gesundheitskarte-Proxy

## Layout-Übersicht

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                                       ┃
┃  Kartenlese-Geräteüberwachung                          🟢 Verbunden ┃
┃                                                                       ┃
┃ ─────────────────────────────────────────────────────────────────────┃
┃                                                                       ┃
┃  Ereignisprotokoll:                                                   ┃
┃  ┌──────────────────────────────────────────────────────────────────┐┃
┃  │ [11:23:45] Kartenlese-Worker gestartet                           ││
┃  │ [11:23:46] ✓ Kartenlesegerät verbunden                         ││
┃  │ [11:23:52] ✓ Karte erfolgreich gelesen - Max Mustermann        ││
┃  │ [11:24:15] ✓ Karte erfolgreich gelesen - Erika Musterfrau      ││
┃  │ [11:24:31] ✗ Kartenlesen fehlgeschlagen - Ungültiger Status    ││
┃  │ [11:25:10] ✓ Karte erfolgreich gelesen - Hans Schmidt           ││
┃  │ [11:26:05] ✗ Kartenlesen fehlgeschlagen - Lesegerät nicht found ││
┃  │ [11:26:30] ✓ Kartenlesegerät verbunden                         ││
┃  │ [11:26:45] ✓ Karte erfolgreich gelesen - Anna Beispiel          ││
┃  │                                                                  ││
┃  │                                                                  ││
┃  │                                                                  ││
┃  └──────────────────────────────────────────────────────────────────┘┃
┃                                                                       ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Komponenten-Zusammenfassung

### 1. TITELLEISTE
- Fenstertitel: "EDP-Gesundheitskarte-Proxy - Kartenlese-Geräteüberwachung"
- Standard-Fenstersteuerungen (minimieren, maximieren, schließen)

### 2. KOPFZEILENBEREICH
- Text: "Kartenlese-Geräteüberwachung" (Groß, Fett)
- Raumfüller
- Status-Indikator
  - Kreis-Emoji: 🟢 (grün) / 🔴 (rot) / ⚫ (grau)
  - Status-Text: "Verbunden" / "Getrennt" / "Wird initialisiert..."

### 3. LOG-BEREICH
- Beschriftung: "Ereignisprotokoll:" (Fett)
- Text-Anzeigebereich (Schreibgeschützt)
  - Monospace-Schrift (Courier, Größe 9)
  - Automatisches Scrollen
  - Zeigt zeitgestempelte Meldungen an:
    - [HH:MM:SS] ✓ Erfolgsmeldungen (grün)
    - [HH:MM:SS] ✗ Fehlermeldungen (rot)
    - [HH:MM:SS] Infomeldungen (grau)

## VISUELLE ZUSTÄNDE

### ZUSTAND 1: WIRD INITIALISIERT (Bei Start)
```
┌──────────────────────────────────────────────────────────┐
│ Kartenlese-Geräteüberwachung              ⚫ Init         │
│                                                            │
│ Ereignisprotokoll:                                        │
│ ┌────────────────────────────────────────────────────────┐│
│ │ [11:23:45] Starte Überwachung...                       ││
│ └────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────┘
```

### ZUSTAND 2: VERBUNDEN (Lesegerät verfügbar)
```
┌──────────────────────────────────────────────────────────┐
│ Kartenlese-Geräteüberwachung        🟢 Verbunden         │
│                                                            │
│ Ereignisprotokoll:                                        │
│ ┌────────────────────────────────────────────────────────┐│
│ │ [11:23:45] Starte Überwachung...                       ││
│ │ [11:23:46] ✓ Kartenlesegerät verbunden                ││
│ │ [11:23:52] ✓ Karte gelesen - Max Mustermann           ││
│ └────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────┘
```

### ZUSTAND 3: GETRENNT (Lesegerät nicht verfügbar)
```
┌──────────────────────────────────────────────────────────┐
│ Kartenlese-Geräteüberwachung         🔴 Getrennt         │
│                                                            │
│ Ereignisprotokoll:                                        │
│ ┌────────────────────────────────────────────────────────┐│
│ │ [11:23:46] ✓ Kartenlesegerät verbunden                ││
│ │ [11:25:10] ✗ Kartenlesegerät getrennt                 ││
│ └────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────┘
```

## LOG-NACHRICHTENTYPEN

### ✓ ERFOLG
```
[HH:MM:SS] ✓ Karte erfolgreich gelesen - <Vorname> <Nachname>
Beispiel: [11:23:52] ✓ Karte erfolgreich gelesen - Max Mustermann
```

### ✗ FEHLER
```
[HH:MM:SS] ✗ Kartenlesen fehlgeschlagen - <Fehlermeldung>
Beispiel: [11:24:31] ✗ Kartenlesen fehlgeschlagen - Ungültiger Status
```

### ℹ INFO
```
[HH:MM:SS] ✓ <Infomeldung>
Beispiel: [11:23:46] ✓ Kartenlesegerät verbunden
```

## VERHALTEN

- Fenster startet automatisch mit aktiver Überwachung
- Keine Benutzerinteraktion erforderlich
- Protokolle scrollen automatisch, um neueste Ereignisse anzuzeigen
- Status-Indikator wird in Echtzeit aktualisiert
- Fenster schließt ordnungsgemäß mit entsprechender Bereinigung
- Automatische Wiederverbindungserkennung, wenn das Lesegerät angeschlossen/getrennt wird

## VERWENDUNG

```bash
pip install -r requirements.txt
python main_gui.py
```
