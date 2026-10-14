import Foundation

public struct RuleEngine {
    public init() {}

    public func evaluate(
        _ rules: [Rule],
        values: [String: String]
    ) -> RuleOutcome {
        var highlighted: Set<String> = []
        var revealed: Set<String> = []
        var satisfied: [UUID] = []

        for rule in rules {
            guard let value = parsedValue(for: values[rule.field]) else { continue }
            let met: Bool
            switch rule.op {
            case .greaterThan: met = value > rule.threshold
            case .lessThan: met = value < rule.threshold
            }
            guard met else { continue }
            satisfied.append(rule.id)
            highlighted.formUnion(rule.highlightTargets)
            revealed.formUnion(rule.revealTargets)
        }

        return RuleOutcome(
            highlightedFields: highlighted,
            revealedFields: revealed,
            satisfiedRuleIDs: satisfied
        )
    }

    public func isVisible(_ field: String, in spec: CardSpec, outcome: RuleOutcome) -> Bool {
        let targeted = spec.rules.contains { $0.revealTargets.contains(field) }
        guard targeted else { return true }
        return outcome.revealedFields.contains(field)
    }

    public func isHighlighted(_ field: String, in outcome: RuleOutcome) -> Bool {
        outcome.highlightedFields.contains(field)
    }

    public func parsedValue(for raw: String?) -> Double? {
        guard let raw, !raw.isEmpty else { return nil }
        return IntentAnalyzer.normalizeAmount(raw)
    }
}

public struct RuleOutcome: Equatable {
    public var highlightedFields: Set<String>
    public var revealedFields: Set<String>
    public var satisfiedRuleIDs: [UUID]

    public init(
        highlightedFields: Set<String>,
        revealedFields: Set<String>,
        satisfiedRuleIDs: [UUID]
    ) {
        self.highlightedFields = highlightedFields
        self.revealedFields = revealedFields
        self.satisfiedRuleIDs = satisfiedRuleIDs
    }
}
