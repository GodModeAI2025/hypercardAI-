import Foundation
import HyperCardCore

func usage() {
    print("HyperCard Studio (M0) — Apps aus Sprache, ohne Code")
    print("")
    print("Verwendung:")
    print("  swift run HyperCardApp \"<Intention>\"")
    print("  swift run HyperCardApp \"<Intention>\" --export <Datei.swift>")
    print("  swift run HyperCardApp --ocr <Quittung.txt>")
    print("")
    print("Beispiel:")
    print("  swift run HyperCardApp \"Baue mir einen Beleg-Tracker mit Kamera. Über 250 Euro rot und Genehmigung.\" --export BelegTracker.swift")
}

let args = Array(CommandLine.arguments.dropFirst())

if args.contains("--help") {
    usage()
    exit(0)
}

if args.isEmpty {
    usage()
    exit(1)
}

if let ocrIdx = args.firstIndex(of: "--ocr"), ocrIdx + 1 < args.count {
    let path = args[ocrIdx + 1]
    guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
        print("Datei nicht lesbar: \(path)")
        exit(1)
    }
    let data = ReceiptParser.parse(text)
    print("Vision-Agent (OCR-Ergebnis):")
    print("  Händler:      \(data.merchant ?? "–")")
    if let date = data.date {
        print("  Datum:        \(date.formatted(.dateTime.day().month().year()))")
    }
    if let gross = data.gross {
        print("  Bruttobetrag: \(gross.formatted(.number.precision(.fractionLength(2)))) €")
    } else {
        print("  Bruttobetrag: –")
    }
    if let net = data.net {
        print("  Netto:        \(net.formatted(.number.precision(.fractionLength(2)))) €")
    }
    if let vat = data.vat {
        print("  MwSt:         \(vat.formatted(.number.precision(.fractionLength(2)))) €")
    }
    print("  Kategorie:    \(data.categoryHint ?? "Sonstiges")")
    exit(0)
}
let intent = args.joined(separator: " ").trimmingCharacters(in: .whitespaces)

var exportPath: String?
if let exportIdx = args.firstIndex(of: "--export"), exportIdx + 1 < args.count {
    exportPath = args[exportIdx + 1]
}

let spec = HyperCardGenerator().generate(GeneratorInput(intent: intent))

print("=== \(spec.title) ===")
print("Entity:       \(spec.entity.rawValue)")
print("Komponenten:  \(spec.components.count)")
for component in spec.components {
    let label = component.label.map { "  \($0)" } ?? ""
    print("  - \(component.kind.rawValue)\(label)")
}
for rule in spec.rules {
    let effects = rule.effects.count
    print("Regel:        \(rule.field) > \(rule.threshold.formatted()) -> \(effects) Effekte")
}

if let exportPath {
    let source = CodeExporter.swiftSource(for: spec)
    let url = URL(fileURLWithPath: exportPath)
    do {
        try source.write(to: url, atomically: true, encoding: .utf8)
        print("")
        print("Export:       \(url.path) (\(source.count) Zeichen)")
        print("Nächster Schritt: In Xcode oder Swift Playgrounds öffnen -> App Store.")
    } catch {
        print("Export fehlgeschlagen: \(error)")
        exit(1)
    }
}

