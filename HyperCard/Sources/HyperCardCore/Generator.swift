import Foundation

public struct GeneratorInput {
    public var intent: String
    public var hints: SketchHint?

    public init(intent: String, hints: SketchHint? = nil) {
        self.intent = intent
        self.hints = hints
    }
}

public struct HyperCardGenerator {
    public let analyzer: IntentAnalyzer

    public static let defaultCategories = ["Bewirtung", "Fahrt", "Büro", "Miete", "Sonstiges"]

    public init(analyzer: IntentAnalyzer = IntentAnalyzer()) {
        self.analyzer = analyzer
    }

    public func generate(_ input: GeneratorInput) -> CardSpec {
        let a = analyzer.analyze(input.intent)
        let hints = input.hints

        if a.isExpense {
            return expenseSpec(intent: input.intent, a: a, hints: hints)
        }
        if a.isTodo {
            return todoSpec(intent: input.intent, a: a)
        }
        return noteSpec(intent: input.intent, a: a, hints: hints)
    }

    func expenseSpec(intent: String, a: IntentAnalysis, hints: SketchHint?) -> CardSpec {
        var spec = CardSpec(
            id: UUID(),
            title: "Beleg- & Spesen-Tracker",
            entity: .expense,
            fields: [:],
            components: [],
            origin: intent
        )

        let showCapture = a.wantsCapture || hints?.hasTopImage == true
        if showCapture {
            spec.setField("image", type: .image, label: "Beleg")
            spec.addComponent(.capture(field: "image", extract: a.wantsCapture))
        }

        spec.setField("merchant", type: .text, label: "Händler")
        spec.addComponent(.text(field: "merchant", placeholder: "z. B. Café Kraft"))

        if a.wantsCategory || hints?.rowCount ?? 0 >= 2 {
            spec.setField("category", type: .category, label: "Kategorie", options: Self.defaultCategories)
            spec.addComponent(.category(field: "category"))
        }

        spec.setField("gross", type: .currency, label: "Bruttobetrag")
        spec.addComponent(.currency(field: "gross"))

        if a.wantsDate {
            spec.setField("date", type: .date, label: "Datum")
            spec.addComponent(.date(field: "date"))
        }

        var rules: [Rule] = []
        if let threshold = a.threshold {
            var effects: [Rule.Effect] = []
            if a.wantsHighlight { effects.append(.highlight(field: "gross")) }
            effects.append(.reveal(field: "needsApproval"))
            rules.append(Rule(field: "gross", op: .greaterThan, threshold: threshold, effects: effects))
            spec.setField("needsApproval", type: .bool, label: "Genehmigung erforderlich")
            spec.addComponent(.check(field: "needsApproval"))
        } else if a.wantsApproval {
            spec.setField("needsApproval", type: .bool, label: "Genehmigung erforderlich")
            spec.addComponent(.check(field: "needsApproval"))
        }

        spec.addComponent(.button(label: "Ausgabe buchen", action: .save))

        if a.wantsChart {
            spec.addComponent(.chart(title: "Ausgaben nach Kategorie", dataField: "category"))
        }

        if a.wantsList {
            spec.addComponent(.list(title: "Monatsliste"))
        } else {
            spec.addComponent(.list(title: "Einträge"))
        }

        spec.rules = rules
        return spec
    }

    func todoSpec(intent: String, a: IntentAnalysis) -> CardSpec {
        var spec = CardSpec(
            id: UUID(),
            title: "Aufgaben-Tracker",
            entity: .todo,
            fields: [:],
            components: [],
            origin: intent
        )

        spec.setField("title", type: .text, label: "Aufgabe")
        spec.addComponent(.text(field: "title", placeholder: "Was ist zu erledigen?"))

        if a.wantsDate {
            spec.setField("due", type: .date, label: "Fällig am")
            spec.addComponent(.date(field: "due"))
        }

        spec.addComponent(.button(label: "Hinzufügen", action: .add))
        spec.addComponent(.list(title: "Offene Aufgaben"))

        spec.rules = []
        return spec
    }

    func noteSpec(intent: String, a: IntentAnalysis, hints: SketchHint?) -> CardSpec {
        let rowCount = max(1, hints?.rowCount ?? 1)
        var spec = CardSpec(
            id: UUID(),
            title: titleFromIntent(intent),
            entity: .note,
            fields: [:],
            components: [],
            origin: intent
        )

        if hints?.hasTopImage == true {
            spec.setField("image", type: .image, label: "Bild")
            spec.addComponent(.capture(field: "image", extract: false))
        }

        for index in 0..<rowCount {
            let id = index == 0 ? "text" : "text\(index + 1)"
            let label = index == 0 ? "Notiz" : "Notiz \(index + 1)"
            spec.setField(id, type: .text, label: label)
            spec.addComponent(.text(field: id, placeholder: label))
        }

        spec.addComponent(.button(label: "Speichern", action: .save))
        spec.addComponent(.list(title: "Einträge"))

        spec.rules = []
        return spec
    }

    func titleFromIntent(_ intent: String) -> String {
        let words = intent
            .components(separatedBy: .whitespaces)
            .filter { $0.count > 2 }
            .prefix(4)
        let title = words.joined(separator: " ")
        guard !title.isEmpty else { return "Notiz-Karte" }
        return title.prefix(1).uppercased() + title.dropFirst()
    }
}
