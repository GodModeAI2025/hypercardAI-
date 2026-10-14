import XCTest
@testable import HyperCardCore

final class GeneratorTests: XCTestCase {
    let generator = HyperCardGenerator()

    func testExpenseIntent() {
        let spec = generator.generate(GeneratorInput(intent: "Baue mir einen Beleg- und Spesen-Tracker. Kamera, Händler, Datum, Kategorie, Bruttobetrag. Über 250 Euro rot und Genehmigung. Monatsliste. Mit Diagramm."))
        XCTAssertEqual(spec.entity, .expense)
        XCTAssertTrue(spec.hasComponent(.capture))
        XCTAssertTrue(spec.hasComponent(.button))
        XCTAssertTrue(spec.hasComponent(.list))
        XCTAssertTrue(spec.hasComponent(.category))
        XCTAssertTrue(spec.hasComponent(.date))
        XCTAssertTrue(spec.hasComponent(.check))
        XCTAssertTrue(spec.hasComponent(.chart))
        XCTAssertEqual(spec.rules.count, 1)
        XCTAssertEqual(spec.rules.first?.threshold, 250)
        XCTAssertTrue(spec.rules.first?.effects.contains(.highlight(field: "gross")) ?? false)
        XCTAssertTrue(spec.rules.first?.effects.contains(.reveal(field: "needsApproval")) ?? false)
    }

    func testTodoIntent() {
        let spec = generator.generate(GeneratorInput(intent: "Erstelle eine Aufgaben-Liste mit Fälligkeitsdatum und einer Übersicht aller offenen Aufgaben."))
        XCTAssertEqual(spec.entity, .todo)
        XCTAssertTrue(spec.hasComponent(.button))
        XCTAssertTrue(spec.hasComponent(.date))
        XCTAssertTrue(spec.hasComponent(.list))
        var action: Action?
        for c in spec.components {
            if case .button(_, let a) = c { action = a }
        }
        XCTAssertEqual(action, .add)
    }

    func testNoteWithSketchHints() {
        let hints = SketchHint(rowCount: 2, hasTopImage: true, hasBottomButton: true)
        let spec = generator.generate(GeneratorInput(intent: "Mach eine Karte für mich", hints: hints))
        XCTAssertEqual(spec.entity, .note)
        XCTAssertEqual(spec.components.filter { $0.kind == .text }.count, 2)
        XCTAssertTrue(spec.hasComponent(.capture))
    }

    func testSimpleNote() {
        let spec = generator.generate(GeneratorInput(intent: "Notizen"))
        XCTAssertEqual(spec.entity, .note)
        XCTAssertEqual(spec.components.filter { $0.kind == .text }.count, 1)
    }
}

final class ReceiptParserTests: XCTestCase {
    func testCafeReceipt() {
        let text = "Café Kraft\nBahnhofstraße 12\n14.10.2026 09:15\nEspresso 3,50\nCroissant 4,20\nSumme 7,70"
        let data = ReceiptParser.parse(text)
        XCTAssertEqual(data.merchant, "Café Kraft")
        XCTAssertEqual(data.gross, 7.7, accuracy: 0.001)
        XCTAssertEqual(data.categoryHint, "Bewirtung")
        let c = Calendar.current.dateComponents([.year, .month, .day], from: data.date ?? Date.distantPast)
        XCTAssertEqual(c.year, 2026)
        XCTAssertEqual(c.month, 10)
        XCTAssertEqual(c.day, 14)
    }

    func testInvoice() {
        let text = "Rechnung Nr. 2026-113\nBüro Müller GmbH\nMusterweg 3\nRechnungsdatum 12.01.2026\nPapier 85,00\nMwSt 19 % 16,15\nGesamtbetrag 101,15"
        let data = ReceiptParser.parse(text)
        XCTAssertEqual(data.merchant, "Büro Müller GmbH")
        XCTAssertEqual(data.vat, 16.15, accuracy: 0.001)
        XCTAssertEqual(data.gross, 101.15, accuracy: 0.001)
        XCTAssertEqual(data.categoryHint, "Büro")
    }

    func testNoAmount() {
        let data = ReceiptParser.parse("Hallo Welt")
        XCTAssertNil(data.gross)
    }
}

final class RuleEngineTests: XCTestCase {
    func testThresholdRule() {
        let rule = Rule(field: "gross", op: .greaterThan, threshold: 250, effects: [.highlight(field: "gross"), .reveal(field: "needsApproval")])
        let spec = CardSpec(title: "T", entity: .expense, fields: [:], components: [], rules: [rule], origin: "x")
        let engine = RuleEngine()
        let below = engine.evaluate([rule], values: ["gross": "200,00"])
        XCTAssertTrue(below.revealedFields.isEmpty)
        let over = engine.evaluate([rule], values: ["gross": "250,01"])
        XCTAssertEqual(over.revealedFields, ["needsApproval"])
        XCTAssertEqual(over.highlightedFields, ["gross"])
        XCTAssertTrue(engine.isVisible("needsApproval", in: spec, outcome: over))
        XCTAssertFalse(engine.isVisible("needsApproval", in: spec, outcome: below))
        XCTAssertTrue(engine.isVisible("merchant", in: spec, outcome: below))
    }
}

final class RefinerTests: XCTestCase {
    func makeSpec() -> CardSpec {
        HyperCardGenerator().generate(GeneratorInput(intent: "Beleg-Tracker mit Kamera, Betrag und Monatsliste. Über 250 Euro rot und Genehmigung."))
    }

    func testAddChart() {
        let result = HyperCardRefiner().apply("Füge noch ein Donut-Diagramm hinzu, das die Ausgaben nach Kategorie anzeigt.", to: makeSpec())
        XCTAssertTrue(result.spec.hasComponent(.chart))
    }

    func testRemoveChart() {
        var spec = makeSpec()
        spec.addComponent(.chart(title: "Diagramm", dataField: "category"))
        let result = HyperCardRefiner().apply("Entferne das Diagramm.", to: spec)
        XCTAssertFalse(result.spec.hasComponent(.chart))
    }

    func testThresholdUpdate() {
        let result = HyperCardRefiner().apply("Wenn der Betrag über 500 Euro liegt, soll das Feld rot markiert werden.", to: makeSpec())
        XCTAssertEqual(result.spec.rules.first?.threshold, 500)
        XCTAssertTrue(result.spec.rules.first?.effects.contains(.highlight(field: "gross")) ?? false)
    }

    func testRenameButton() {
        let result = HyperCardRefiner().apply("Button soll „Speichern“ heißen.", to: makeSpec())
        var label: String?
        for c in result.spec.components {
            if case .button(let l, _) = c { label = l }
        }
        XCTAssertEqual(label, "Speichern")
    }
}

final class CodeExporterTests: XCTestCase {
    func testExpenseExport() {
        let spec = HyperCardGenerator().generate(GeneratorInput(intent: "Beleg-Tracker mit Kamera, Kategorie, Datum, Betrag, Monatsliste. Über 250 Euro rot und Genehmigung. Mit Diagramm."))
        let source = CodeExporter.swiftSource(for: spec)
        XCTAssertTrue(source.contains("@Model"))
        XCTAssertTrue(source.contains("final class Expense"))
        XCTAssertTrue(source.contains("struct ExpenseCardView"))
        XCTAssertTrue(source.contains("SectorMark"))
        XCTAssertTrue(source.contains(".modelContainer(for: Expense.self)"))
        XCTAssertTrue(source.contains("if gross > 250"))
        XCTAssertTrue(source.contains("Button(\"Ausgabe buchen\")"))
    }

    func testTodoExport() {
        let spec = HyperCardGenerator().generate(GeneratorInput(intent: "Aufgaben-Liste mit Fälligkeitsdatum"))
        let source = CodeExporter.swiftSource(for: spec)
        XCTAssertTrue(source.contains("final class TodoEntry"))
        XCTAssertTrue(source.contains("struct TodoCardView"))
        XCTAssertTrue(source.contains(".modelContainer(for: TodoEntry.self)"))
    }
}

final class SketchHintExtractorTests: XCTestCase {
    func line(_ y: Double) -> [SketchPoint] {
        var pts: [SketchPoint] = []
        var x = 0.2
        while x <= 0.801 {
            pts.append(SketchPoint(x: x, y: y))
            x += 0.02
        }
        return pts
    }

    func square(cx: Double, cy: Double, w: Double, h: Double) -> [SketchPoint] {
        var pts: [SketchPoint] = []
        let x0 = cx - w / 2, x1 = cx + w / 2, y0 = cy - h / 2, y1 = cy + h / 2
        var x = x0
        while x <= x1 + 0.001 { pts.append(SketchPoint(x: x, y: y0)); x += 0.02 }
        var y = y0
        while y <= y1 + 0.001 { pts.append(SketchPoint(x: x1, y: y)); y += 0.02 }
        x = x1
        while x >= x0 - 0.001 { pts.append(SketchPoint(x: x, y: y1)); x -= 0.02 }
        y = y1
        while y >= y0 - 0.001 { pts.append(SketchPoint(x: x0, y: y)); y -= 0.02 }
        return pts
    }

    func testHints() {
        let strokes = [
            square(cx: 0.5, cy: 0.175, w: 0.3, h: 0.25),
            line(0.40),
            line(0.50),
            line(0.60),
            line(0.85)
        ]
        let hints = SketchHintExtractor.hints(from: strokes)
        XCTAssertEqual(hints?.hasTopImage, true)
        XCTAssertEqual(hints?.rowCount, 3)
        XCTAssertEqual(hints?.hasBottomButton, true)
    }

    func testEmpty() {
        XCTAssertNil(SketchHintExtractor.hints(from: []))
    }
}
