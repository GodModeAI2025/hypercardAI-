# HyperCard AI — Gesamt-Konzept

**One-Liner:** HyperCard für die KI-Ära. Eine App ohne Code entsteht durch fließenden Dialog zwischen **multimodaler Skizze**, **semantischer Absicht** und **sofortiger nativer Ausführung** — lokal auf iPad und iPhone, ohne Cloud, ohne Abo.

**Version:** 1.0 (Gesamt-Konzept inkl. MVP-Definition) · Stand: Oktober 2026

---

## 1. Problem & Chance

Klassische No-Code-Tools (Bubble, Glide, AppSheet) zwingen Nutzer in abstrakte Konfigurationsbäume: Komponenten-Bäume, Feldtypen, Relationen, Publish-Workflows — plus Cloud-Zwang und Abo. Die Kluft zwischen „Ich will einen Beleg-Tracker" und „Die App läuft auf meinem iPhone" bleibt groß.

Gleichzeitig sind drei Voraussetzungen 2026 erstmals gleichzeitig erfüllt:

1. **Multimodale Modelle** interpretieren Skizze + Sprache zuverlässig.
2. **On-Device-Modelle** (CoreML/MLX, Whisper, VisionKit) machen das ohne Cloud möglich — Datenschutz wird zum Feature, nicht zum Kompromiss.
3. **Apple-Ökosystem** bietet stabile System-Schnittstellen (App Intents, Shortcuts, SwiftData, Swift Playgrounds), über die selbstgebaute Apps echte System-APIs (Kamera, GPS, FaceID, Reminders) erreichen.

Seit 1987 (HyperCard), seit FileMaker Go: Die Idee „Karte statt Konfigurationsbaum" hat sich nie durchgesetzt — weil die Interpretation der Skizze fehlte. Diese Lücke schließt heute ein lokales Modell.

**Positionierung:** Kein No-Code-Tool für PMs. Ein *App-Entstehungs-Tool*: Von Absicht zur laufenden nativen App in unter 5 Minuten, auf dem Gerät, lokal.

---

## 2. Zielgruppen

| Persona | Bedarf | Typische Karte |
|---|---|---|
| **Lena, Vielreisende (32)** | Spesen & Belege ohne App-Store-Suche | Beleg- & Spesen-Tracker mit OCR, Monatsliste, Schwelle 250 € → Genehmigungs-Flag |
| **Jonas, Hobbyist (27)** | Private Tracker, die niemand sonst braucht | Kaffeeröst- / Pflanzentracker, Widgets auf Sperrbildschirm |
| **Mira, Teamleitung (38)** | Kleine Tools für ihr Team, ohne IT-Ticket | Onboarding-Checkliste, als Datei per AirDrop an das Team, dort weiteranpassbar |

Gemeinsam: Sie formulieren, was sie wollen. Sie klicken keine Menüs. Sie warten keinen App-Store-Review.

---

## 3. Produkt-Konzept: Der Vier-Schritte-Flow

### Schritt 1 — Scaffolding per Stift und Sprache (Die Absicht)

Leere Karte (*Card*) auf dem Canvas. Statt Menüs kombiniert der Nutzer:

- **Zeichnen:** Grobe Surface-Skizze mit dem Pencil (Rechteck + Kamerasymbol oben, drei Zeilen, Button unten).
- **Diktat:** „Baue mir einen Beleg- und Spesen-Tracker. Kamera → Beleg fotografieren, Händler, Datum, Kategorie, Bruttobetrag extrahieren. Button unten speichert in die Monatsliste."
- **Materialisierung:** Das lokale Modell interpretiert Skizze + Sprache; die Stiche morphen in echte SwiftUI-Komponenten.

### Schritt 2 — Visuelle Verdrahtung & Agenten-Logik (Das Verhalten)

- **Pfeil-Gesten:** Linie vom Kamerasymbol zu den Feldern → Kontextmenü „Felder mit Belegdaten befüllen?" → antippen.
- **Klartext-Regeln:** Klick aufs Betragsfeld → Sprechblase: „Wenn der Betrag über 250 € liegt, hebe das Feld rot hervor und aktiviere eine Checkbox 'Genehmigung erforderlich'."
- **Schema-Autovervollständigung:** Im Hintergrund entsteht das lokale Datenschema (`Expenses` mit `Date`, `Decimal`, `String`) — ohne Spalten-Konfiguration.

### Schritt 3 — System-Anbindung via MCP & App Intents

- **Hardware:** „Lies beim Speichern den GPS-Ort und setze die Stadt als Notiz." → FaceID-/Kamera-/LoC-Permissions werden deklarativ angefragt.
- **Konnektoren:** Verbindungslinie zum Kartenrand → „Sync mit Google-Drive-Tabelle" oder „Erstelle Aufgabe in Apple Reminders". Die KI verdrahtet die lokal hinterlegten MCP-Server / Shortcuts-Aktionen.

### Schritt 4 — Testen, Verfeinern, Deployment

Kein künstlicher Entwurfs-/Laufzeit-Modus: Die Karte ist sofort lauffähig (Split-View: Live-App links, Editor rechts).

- **Iterativ verfeinern:** Bereich mit dem Stift markieren + „Zeig hier ein Kreisdiagramm der Kategorie-Aufteilung" → UI passt sich reaktiv an, Datenbestand bleibt erhalten.
- **Export (drei Pfade, siehe §7):** Mini-App auf dem Home-Bildschirm · Sperrbildschirm-Widget · Sharing per AirDrop als kompakte lokale Datei.

---

## 4. Kernprinzipien (Design-Dekrete)

1. **Local First.** Kein Cloud-Zwang, kein Abo. Alle Daten auf dem Gerät (SwiftData/SQLite, lokal verschlüsselt). Sync ist optional (M4, CRDT/CloudKit).
2. **CardSpec als Herz.** Alles, was entsteht, ist eine maschinenlesbare Spezifikation (JSON-Intermediate Representation). Generator, Editor, Runtime und Exporter arbeiten auf derselben Spec — deshalb ist „Design = Runtime" und Verfeinerung ohne Datenverlust trivial.
3. **Design = Runtime.** Es gibt keinen „Entwurfsmodus". Die Karte ist immer lauffähig.
4. **System statt Sandkasten.** App Intents/Shortcuts/MCP machen Kamera, GPS, Reminders & Co. adressierbar — deklarativer, in Sprache formuliert.
5. **Compliance by Design.** Guideline 2.5.2 (kein dynamisch geladenes ausführbares Code): Der Player interpretiert reine Daten-Specs (kein Code), der App-Store-Export ist statisch vorkompiliert. Beides konform (Details §7.4).
6. **Erklärbar.** Jede automatische Entscheidung (Schema, Verdrahtung, Regel) ist als sichtbare Spec-Entität editierbar — kein Black-Box-„die KI hat's gemacht".

---

## 5. Architektur

```
┌──────────────────────────────────────────────────────────────────────┐
│                        CAPTURE-LAYER                                 │
│   PencilKit-Stroke    SFSpeechRecognizer    Stift-Markierung (Region)│
└──────────────────────────────┬───────────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    INTERPRETATION-LAYER                              │
│  SpecInterpreter (Protocol, austauschbar):                          │
│   · MVP:  deterministischer Template-Compiler (Keyword-Heuristik    │
│           + Layout-Heuristik aus der Skizze)                         │
│   · M1:   lokales VLM (CoreML/MLX) + Whisper für Sprache             │
│  → Intent → CardSpec (Delta-Operationen für Verfeinerung)           │
└──────────────────────────────┬───────────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────────────┐
│              CARDSPEC — Intermediate Representation (JSON)           │
│  Komponenten · Felder/Typen · Regeln (Condition → Effects) ·        │
│  Entity-Schema · Konnektoren (MCP/App-Intent-Referenzen)             │
└───────┬──────────────┬──────────────┬─────────────────┬──────────────┘
        ▼              ▼              ▼                 ▼
┌──────────────┐ ┌───────────┐ ┌────────────────┐ ┌──────────────────┐
│  RUNTIME     │ │   DATA    │ │  INTEGRATION   │ │     EXPORT       │
│  SwiftUI     │ │ SwiftData │ │ MCP-Client,    │ │ ① SwiftUI-Source │
│  (render +   │ │ (Entity-  │ │ App Intents,   │ │   (Xcode/        │
│   Aktionen)  │ │  Modelle) │ │ Shortcuts,     │ │   Playgrounds)   │
│              │ │           │ │ Permissions    │ │ ② Spec-JSON      │
│              │ │           │ │                │ │   (Player/       │
│              │ │           │ │                │ │   AirDrop)       │
│              │ │           │ │                │ │ ③ App-Store-Pipe │
└──────────────┘ └───────────┘ └────────────────┘ └──────────────────┘
```

**Entscheidungen & Rationale:**

| # | Entscheidung | Rationale |
|---|---|---|
| A1 | **CardSpec (JSON) als IR** zwischen Interpretation, Runtime und Export | Machtpunkt des Systems: Editor, Verfeinerung, Sharing (AirDrop) und Export teilen einen Format-Kern. Delta-Operationen statt Ganz-Regenerierung → keine Datenverluste bei Verfeinerung. |
| A2 | **Austauschbarer `SpecInterpreter`-Port** (MVP: Heuristik, M1: lokales VLM) | MVP bleibt testbar, deterministisch, ohne API-Key. Modellwechsel später = neue Implementierung desselben Ports. Keine Lock-in-Entscheidung. |
| A3 | **SwiftUI + SwiftData** als Runtime | Nativ, performant, exakt das, was der App-Store-Export braucht; identisches Vokabular für Nutzer und Code-Export. |
| A4 | **Entity-Library statt frei dynamischem Schema (MVP)** | SwiftData braucht statische `@Model`-Klassen. MVP: kuratiertes Set (Expense, Todo, Note) — die Spec beschreibt Spalten semantisch, der Exporter generiert daraus später echte `@Model`-Code. Frei-dynamische Schemas kommen mit Codegen in M3. |
| A5 | **Regel-Engine als deklarative Spec-Entität** (`Rule: Condition → Effects`) | „Über 250 € → rot + Genehmigungs-Checkbox" wird zur Daten-Struktur: sichtbar, editierbar, exportierbar, in Code übersetzbar. |
| A6 | **OCR via VisionKit (on-device)** | Beleg-Extraktion ohne Cloud ist das stärkste Demo-Feature und datenschutztechnisch sauber. |
| A7 | **MCP/Shortcuts-Referenzen in der Spec** (Verdrahtung erst M2) | Spec-Schicht vorbereitet, Implementierung gestaffelt — MVP beweist den Kern-Loop, nicht die Konnektoren. |

---

## 6. Datenmodell & Regel-DSL (Beispiel: Beleg-Tracker)

```
Entity: Expense
├── image        Image        (Beleg-Foto, lokal)
├── merchant     String       (OCR)
├── category     String       (OCR-Hinweis / Auswahl: Bewirtung, Fahrt, Büro, Miete, Sonstiges)
├── gross        Decimal      (OCR)
├── date         Date         (OCR)
└── needsApproval Bool        (per Regel sichtbar)

Rule R1:
  WHEN  gross  >  250.00
  THEN  highlight(gross)
        reveal(needsApproval)
```

Die Regel-Engine wertet live aus: Überschreitet der Betrag die Schwelle, wird das Feld rot hervorgehoben und die Genehmigungs-Checkbox erscheint. Im Code-Export wird dieselbe Regel zu echtem SwiftUI (Condition + View).

---

## 7. Export-Pfade & regulatorische Grenze

### 7.1 ① Swift-Playgrounds-Pfad (App Store)
Die App erzeugt valides SwiftUI + `.swiftpm`-Paket → öffnet in *Swift Playgrounds* auf dem iPad → direkt an App Store Connect → TestFlight/App Store. Für den weltweiten Vertrieb.

### 7.2 ② Player-Pfad (Homescreen, sofort)
Eine einzelne *HyperCard Player*-App (Renderer-Engine + SwiftData-Verwaltung) öffnet Spec-Dateien via URL-Schema (`hypercard://open?stack=…`). PWA-Web-Clip / Kurzbefehl legt das Icon auf dem Homescreen; Vollbild, ohne Editor — fühlt sich nativ an. Für Eigengebrauch & AirDrop-Sharing.

### 7.3 ③ Entwickler-Pfad (Xcode & Git)
Knopfdruck: kompletter generierter Code (Views, `@Model`-Klassen, Assets) in GitHub-Repo oder Dateien-App → in Xcode öffnen, erweitern, CI/CD.

### 7.4 Guideline 2.5.2 — warum zwei Modi konform sind

| Eigenschaft | Player / Live-Canvas | App-Store-Export |
|---|---|---|
| Erstellung | dynamisch zur Laufzeit | statisch eingefroren |
| Code | **nur interpretierte Daten-Spec, kein ausführbarer Code** (Sandbox) | vorkompiliert, vollständig konform |
| Prüfung | sofort nutzbar | Apple-Review (24–48 h) |
| System-APIs | über MCP/App Intents des Players | direkter nativer Swift-Zugriff |

---

## 8. Sicherheit & Privacy

- **100 % on-device** im MVP: OCR (VisionKit), Interpretation (lokale Heuristik → lokales VLM), Daten (SwiftData, App-Sandbox). Kein einziges Byte verlässt das Gerät.
- Skizzen & Audio werden nicht persistent gespeichert, außer der Nutzer speichert die Karte (dann als Teil der Spec, lokal).
- Permissions (Kamera, Standort, FaceID) werden erst beim Verdrahten deklarativer angefragt und in der Spec nachvollziehbar dokumentiert.
- AirDrop-Dateien sind lokale Spec-/Daten-Bundles — übertragbar, aber ohne Netz-Anbindung nutzbar.

---

## 9. MVP-Definition (M0 — jetzt gebaut)

**Ziel:** Den Kern-Loop *Absicht → Spec → native Karte → Verfeinerung → Export* technisch beweisen.

**Plattform-Entscheidung:** macOS (SwiftUI/SPM) als MVP-Plattform — die Dev-Maschine, auf der alles sofort compilierbar und testbar ist. Runtime-Views sind reines, portables SwiftUI (iOS 17/macOS 15+). iPad-Port inkl. PencilKit und Voice ist M1.

**Scope M0 (implementiert):**

| Feature | Status |
|---|---|
| Canvas mit mehreren Karten (Stack), hinzufügen/wechseln/löschen, lokale Persistenz (JSON) | ✅ |
| Intent-Dialog: Text-Intention → Generator → CardSpec (Entity: Expense, Todo, Note) | ✅ |
| Skizzen-Canvas (freihand) mit Layout-Heuristik (Bild oben, Zeilen, Button unten) als zweiter Intent-Kanal | ✅ |
| Natives Rendering: Capture, Text, Währung, Datum, Kategorie-Pills, Checkbox, Button, Liste | ✅ |
| **Vision-Agent (echt):** Beleg-Foto (Fotos/Datei) → VisionKit-OCR → parse Händler, Datum, Brutto, Netto, MwSt → Felder befüllen + Kategorie-Hinweis | ✅ |
| Regel-Engine: „über X € → rot + Genehmigungs-Checkbox" (Condition → Effects, live) | ✅ |
| Verfeinerungs-Dialog (Delta-Operationen): Diagramm hinzufügen/entfernen, Schwellwert ändern, Button umbenennen, Liste/Datum/Kategorie nachrüsten — Datenbestand bleibt erhalten | ✅ |
| Donut-Chart (Swift Charts) über Kategorie-Aufteilung der gespeicherten Einträge | ✅ |
| SwiftData-Persistenz der Einträge pro Karte | ✅ |
| Export ①: generierter, lauffähiger SwiftUI-Code (`.swift`) in Downloads | ✅ |
| Export ②: Spec-JSON teilen (ShareLink — AirDrop-Analog) | ✅ |

**Bewusst draußen (vertrauensvoll dokumentiert, kein stiller Scope-Cut):**
- Voice-Diktat (SFSpeechRecognizer/Whisper) → **M1**
- Lokales VLM für freie Skizzen-Interpretation (MVP nutzt deterministische Heuristik am selben Port) → **M1**
- MCP-/Shortcuts-Verdrahtung (Reminders, Drive, GPS) → **M2**
- Swift-Playgrounds-/App-Store-Pipeline (① end-to-end) → **M3**
- Widgets, AirDrop-Player-App, CRDT-Sync → **M4**
- PencilKit (iPad) — macOS-MVP nutzt Maus/Stift-freien Zeichnen-Canvas → **M1**

**Akzeptanzkriterien:**
1. Aus dem Beispiel-Satz (Beleg-Tracker mit 250-€-Regel) entsteht in einem Handgriff eine lauffähige Karte.
2. Ein Foto einer echten deutschen Quittung füllt die Felder (Händler, Betrag, Datum) korrekt.
3. Über 250 € → rotes Feld + Genehmigungs-Checkbox erscheint.
4. „Füge ein Diagramm hinzu" → Donut-Chart erscheint, alte Einträge bleiben.
5. Export erzeugt eine `.swift`-Datei mit `@Model` + `Form` + Button, die sich in Xcode/Playgrounds öffnen lässt.
6. `swift test` grün: Generator, Parser, Regeln, Refiner, Exporter, Skizzen-Heuristik.

---

## 10. Roadmap

| Meilenstein | Inhalt | Abhängigkeit |
|---|---|---|
| **M0 (jetzt)** | Kern-Loop auf macOS: Spec-IR, Generator, Runtime, OCR, Regeln, Verfeinerung, Export ①② | — |
| **M1** | iPad-Port: PencilKit-Skizzen, Voice-Diktat (Whisper/SFSpeech), lokales VLM als `SpecInterpreter` | M0 |
| **M2** | MCP-Client + App-Intents-Verdrahtung: Reminders, Kalender, Maps/GPS, Dateien, Share-Targets | M0 |
| **M3** | Playgrounds-Export-Pipeline: `.swiftpm`-Generierung, Signierung, TestFlight/Store-Submission; frei-dynamische Entity-Codegen | M1 |
| **M4** | Player-App (Homescreen-Icons via URL-Schema), Sperrbildschirm-Widgets, AirDrop-Stacks, optionales CRDT/CloudKit-Sync | M2 |

---

## 11. Risiken & Mitigationen

| Risiko | Impact | Mitigation |
|---|---|---|
| Guideline 2.5.2: Apple erkennt interpretierte Specks als „dynamischen Code" an | Player-Pfad wird abgelehnt | Spec enthält ausschließlich Daten (kein Script-Blob, kein JS/WASM-Code); Player ist eine gewöhnliche nativen App, die JSON rendert — wie Tabletop/Notion-Viewer. Early Review-Feedback über Swift Playgrounds-Entwicklungspartner einholen. |
| Lokale VLM-Qualität für freie Skizzen (M1) | Interpretationsfehler frustrieren | MVP-Heuristik bleibt Fallback; Interpretation ist immer als Spec editierbar (Prinzip 6); Few-Shot-Beispiele je Karten-Typ. |
| SwiftData-Limits bei sehr großen Karten | Performance | Local-First-Daten sind ohnehin klein (Tracker-Größe); Pagination in Listen; Export ③ für Wachstum nach Xcode. |
| OCR-Qualität bei handschriftlichen/krummen Belegen | Felder falsch | VisionKit `.accurate` + Spracheinstellung de-DE; OCR-Ergebnis ist immer vor dem Speichern korrigierbar; „Nochmal scannen"-Aktion. |
| Scope-Creeple Richtung „zweites Bubble" | Fokus-Verlust | Design-Dekret: Es wird keine Konfigurations-Bäume geben. Jedes Feature muss den Vier-Schritte-Flow bedienen. |

---

## 12. KPIs

| KPI | Ziel (M0) | Ziel (M1) |
|---|---|---|
| Zeit von Absicht bis laufende Karte | < 90 s | < 60 s (Voice+Sketch) |
| Schritte ohne Menü/Klick-Baum | ≥ 80 % | ≥ 95 % |
| On-Device-Anteil (Bytes, die das Gerät verlassen) | 0 % | 0 % |
| OCR-Feldtrefferquote (Händler/Betrag/Datum) | ≥ 90 % | ≥ 95 % |
| Export ① kompiliert im ersten Versuch | ≥ 90 % | ≥ 98 % |

---

## 13. Projektstatus (M0)

**Bau-Status dieses Repos:**

```
hypercardAI/
├── KONZEPT.md                 ← dieses Dokument
├── README.md                  ← Quickstart
└── HyperCard/                 ← SPM-Paket (MVP)
    ├── Package.swift
    ├── Sources/HyperCardCore/ ← IR, Generator, Regeln, OCR-Parser, Exporter, Skizzen-Heuristik
    ├── Sources/HyperCardApp/  ← SwiftUI-App (Canvas, Intent, Runtime, Refine, Export)
    └── Tests/HyperCardCoreTests/
```

**Laufen:**
- `swift build` — alles kompilieren
- `swift test` — Unit-Tests (Generator, Receipt-Parser, Regeln, Refiner, Exporter, Skizzen)
- `swift run HyperCardApp` — die Studio-App starten
