# HyperCard AI

**Apps aus Sprache, ohne Code.** Eine Idee als Satz (oder Skizze) wird lokal auf dem Gerät in eine lauffähige, native App übersetzt — ohne Cloud, ohne Abo, ohne Konfigurationsbaum.

Das vollständige Produkt-Konzept (Vision, Architektur, Export-Pfade, Roadmap, KPIs) steht in [KONZEPT.md](KONZEPT.md).

## Status: M0 (Kern-Loop lauffähig)

Der Kern des Systems ist gebaut und getestet:

| Modul | Funktion |
|---|---|
| `CardSpec` | Maschinelle Zwischenrepräsentation (IR) einer App: Komponenten, Felder, Regeln, Entity |
| `IntentAnalyzer` | Parst deutsche Alltagssprache zu Absichten (Kategorien, Schwellwerte, Regeln) |
| `HyperCardGenerator` | Absicht → fertige `CardSpec` (Beleg-/Spesen, Aufgaben, Notiz) |
| `ReceiptParser` | Vision-Agent: Quittungs-Text → Händler, Datum, Brutto, Netto, MwSt, Kategorie |
| `RuleEngine` | Deklarative Regeln (z. B. „Betrag > 250 € → rot + Genehmigung“) |
| `HyperCardRefiner` | Iterative Verfeinerung per Satz (Diagramm hinzufügen/entfernen, Regel ändern, Umbenennen) |
| `SketchHintExtractor` | Handskizze → Layout-Hinweise (Bild oben, Zeilen, Button unten) |
| `CodeExporter` | `CardSpec` → kompilierbarer SwiftUI-Code (Xcode / Swift Playgrounds) |

## Struktur

```
hypercardAI/
├── KONZEPT.md                 Gesamt-Konzept (Vision bis M4)
└── HyperCard/                 SPM-Paket
    ├── Package.swift
    ├── Sources/HyperCardCore/ Engine (pure Swift, portabel)
    ├── Sources/HyperCardApp/  Studio-Executable (CLI)
    └── Tests/HyperCardCoreTests/
```

## Laufen (macOS, Swift 5.9+)

```bash
cd HyperCard

# Alles kompilieren
swift build

# Studio: Satz -> Karte
swift run HyperCardApp "Baue mir einen Beleg- und Spesen-Tracker mit Kamera. Über 250 Euro rot und Genehmigung. Monatsliste."

# Studio: Satz -> fertiger Swift-App-Code
swift run HyperCardApp "Aufgaben-Liste mit Fälligkeitsdatum" --export BelegTracker.swift

# Vision-Agent: Quittung parsen
swift run HyperCardApp --ocr quittung.txt
```

## Tests

```bash
swift test
```

Hinweis: `swift test` benötigt das vollständige Xcode (XCTest-Framework). Mit reinen Command Line Tools gelingt `swift build`, nicht `swift test`.

## Roadmap (Kurz)

- **M0 (hier):** Kern-Loop + Export-Pfad ① (SwiftUI-Code)
- **M1:** iPad-Port (PencilKit, Voice), lokales VLM als Interpret
- **M2:** MCP / App Intents (Reminders, Maps, Dateien)
- **M3:** Swift Playgrounds → App Store (TestFlight)
- **M4:** Player-App, Widgets, AirDrop-Stacks, optionales Sync
