import Foundation

public struct RefineResult: Equatable {
    public var spec: CardSpec
    public var message: String

    public init(spec: CardSpec, message: String) {
        self.spec = spec
        self.message = message
    }
}

public struct HyperCardRefiner {
    public let analyzer: IntentAnalyzer

    public init(analyzer: IntentAnalyzer = IntentAnalyzer()) {
        self.analyzer = analyzer
    }

    public func apply(_ phrase: String, to spec: CardSpec) -> RefineResult {
        let text = phrase.lowercased()
        var spec = spec

        if containsAny(text, ["entferne", "entfernen", "weg", "ohne"]) && containsAny(text, ["diagramm", "chart", "diagram"]) {
            spec.components.removeAll { $0.kind == .chart }
            return RefineResult(spec: spec, message: "Diagramm entfernt.")
        }

        if let threshold = IntentAnalyzer.threshold(in: phrase) {
            var effects: [Rule.Effect] = []
            if containsAny(text, ["rot", "hervorheb", "markier", "warnung"]) {
                effects.append(.highlight(field: spec.entity == .expense ? "gross" : "title"))
            }
            if containsAny(text, ["genehmig", "freigab", "checkbox", "approv"]) {
                let field = "needsApproval"
                if spec.fields[field] == nil {
                    spec.setField(field, type: .bool, label: "Genehmigung erforderlich")
                }
                if !spec.hasComponent(.check) {
                    spec.addComponent(.check(field: field))
                }
                effects.append(.reveal(field: field))
            }
            if effects.isEmpty {
                effects.append(.highlight(field: spec.entity == .expense ? "gross" : "title"))
                effects.append(.reveal(field: "needsApproval"))
            }
            spec.rules.removeAll { $0.field == (spec.entity == .expense ? "gross" : "title") }
            spec.rules.append(Rule(field: spec.entity == .expense ? "gross" : "title", op: .greaterThan, threshold: threshold, effects: effects))
            if spec.fields["needsApproval"] == nil {
                spec.setField("needsApproval", type: .bool, label: "Genehmigung erforderlich")
            }
            if spec.rules.contains(where: { $0.revealTargets.contains("needsApproval") }) && !spec.hasComponent(.check) {
                spec.addComponent(.check(field: "needsApproval"))
            }
            return RefineResult(spec: spec, message: "Regel aktualisiert: ab \(threshold.formatted()) € wird markiert.")
        }

        if containsAny(text, ["diagramm", "donut", "kreisdiagramm", "aufteilung", "chart", "diagram"]) {
            if !spec.hasComponent(.chart) {
                let dataField = spec.entity == .expense ? "category" : "text"
                spec.addComponent(.chart(title: "Aufteilung nach Kategorie", dataField: dataField))
                return RefineResult(spec: spec, message: "Diagramm hinzugefügt.")
            }
        }

        if let label = IntentAnalyzer.quotedPhrase(in: phrase) {
            if containsAny(text, ["button", "umbenenn", "heißt", "heiße", "beschrift"]) {
                for (index, component) in spec.components.enumerated() {
                    if case .button = component {
                        spec.components[index] = .button(label: label, action: savedAction(for: spec))
                    }
                }
                return RefineResult(spec: spec, message: "Button umbenannt in „\(label)\".")
            }
        }

        if containsAny(text, ["liste", "übersicht"]) && !spec.hasComponent(.list) {
            spec.addComponent(.list(title: "Einträge"))
            return RefineResult(spec: spec, message: "Liste hinzugefügt.")
        }

        if spec.entity == .expense, containsAny(text, ["datum", "zeitpunkt"]) && !spec.hasComponent(.date) {
            spec.setField("date", type: .date, label: "Datum")
            spec.addComponent(.date(field: "date"))
            return RefineResult(spec: spec, message: "Datum-Feld hinzugefügt.")
        }

        if spec.entity == .expense, containsAny(text, ["kategorie"]) && !spec.hasComponent(.category) {
            spec.setField("category", type: .category, label: "Kategorie", options: HyperCardGenerator.defaultCategories)
            spec.addComponent(.category(field: "category"))
            return RefineResult(spec: spec, message: "Kategorie-Feld hinzugefügt.")
        }

        return RefineResult(
            spec: spec,
            message: "Das verfeinere ich in einem späteren Schritt. Jetzt möglich: Diagramm hinzufügen/entfernen, Schwellwert-Regel („über 500 €“), Button umbenennen, Liste/Datum/Kategorie nachrüsten."
        )
    }

    func savedAction(for spec: CardSpec) -> Action {
        for component in spec.components {
            if case .button(_, let action) = component {
                return action
            }
        }
        return spec.entity == .todo ? .add : .save
    }

    func containsAny(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }
}
