import Foundation

public struct CardSpec: Codable, Identifiable, Equatable {
    public var id: UUID
    public var title: String
    public var entity: EntityKind
    public var fields: [String: FieldDef]
    public var components: [Component]
    public var rules: [Rule]
    public var createdAt: Date
    public var origin: String

    public init(
        id: UUID = UUID(),
        title: String,
        entity: EntityKind,
        fields: [String: FieldDef],
        components: [Component],
        rules: [Rule] = [],
        createdAt: Date = .now,
        origin: String
    ) {
        self.id = id
        self.title = title
        self.entity = entity
        self.fields = fields
        self.components = components
        self.rules = rules
        self.createdAt = createdAt
        self.origin = origin
    }

    public mutating func setField(_ id: String, type: FieldType, label: String, options: [String] = []) {
        fields[id] = FieldDef(type: type, label: label, options: options)
    }

    public mutating func addComponent(_ component: Component) {
        components.append(component)
    }

    public mutating func removeComponent(id: String) {
        components.removeAll { $0.id == id }
    }

    public func hasComponent(_ kind: Component.Kind) -> Bool {
        components.contains { $0.kind == kind }
    }
}

public enum EntityKind: String, Codable, CaseIterable, Equatable {
    case expense
    case todo
    case note

    public var displayName: String {
        switch self {
        case .expense: return "Beleg- & Spesen-Tracker"
        case .todo: return "Aufgaben-Tracker"
        case .note: return "Notiz-Karte"
        }
    }
}

public enum FieldType: String, Codable, Equatable {
    case text
    case currency
    case date
    case category
    case bool
    case image
}

public struct FieldDef: Codable, Equatable {
    public var type: FieldType
    public var label: String
    public var options: [String]

    public init(type: FieldType, label: String, options: [String] = []) {
        self.type = type
        self.label = label
        self.options = options
    }
}

public enum Component: Codable, Equatable, Identifiable {
    case capture(field: String, extract: Bool)
    case text(field: String, placeholder: String)
    case currency(field: String)
    case date(field: String)
    case category(field: String)
    case check(field: String)
    case button(label: String, action: Action)
    case chart(title: String, dataField: String)
    case list(title: String)

    public enum Kind: String, Equatable {
        case capture, text, currency, date, category, check, button, chart, list
    }

    public var kind: Kind {
        switch self {
        case .capture: return .capture
        case .text: return .text
        case .currency: return .currency
        case .date: return .date
        case .category: return .category
        case .check: return .check
        case .button: return .button
        case .chart: return .chart
        case .list: return .list
        }
    }

    public var id: String {
        switch self {
        case .capture(let field, _): return "capture-\(field)"
        case .text(let field, _): return "text-\(field)"
        case .currency(let field): return "currency-\(field)"
        case .date(let field): return "date-\(field)"
        case .category(let field): return "category-\(field)"
        case .check(let field): return "check-\(field)"
        case .button(let label, let action): return "button-\(action.rawValue)-\(label.hashValue)"
        case .chart(_, let dataField): return "chart-\(dataField)"
        case .list: return "list"
        }
    }

    public var label: String? {
        switch self {
        case .button(let label, _): return label
        case .chart(let title, _): return title
        case .list(let title): return title
        default: return nil
        }
    }
}

public enum Action: String, Codable, Equatable {
    case save
    case add
}

public struct Rule: Codable, Equatable, Identifiable {
    public enum Op: String, Codable, Equatable {
        case greaterThan
        case lessThan
    }

    public enum Effect: Codable, Equatable {
        case highlight(field: String)
        case reveal(field: String)
    }

    public var id: UUID
    public var field: String
    public var op: Op
    public var threshold: Double
    public var effects: [Effect]

    public init(
        id: UUID = UUID(),
        field: String,
        op: Op,
        threshold: Double,
        effects: [Effect]
    ) {
        self.id = id
        self.field = field
        self.op = op
        self.threshold = threshold
        self.effects = effects
    }

    public var revealTargets: [String] {
        effects.compactMap { effect in
            if case .reveal(let field) = effect { return field }
            return nil
        }
    }

    public var highlightTargets: [String] {
        effects.compactMap { effect in
            if case .highlight(let field) = effect { return field }
            return nil
        }
    }
}

public struct SketchPoint: Codable, Equatable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct SketchHint: Codable, Equatable {
    public var rowCount: Int
    public var hasTopImage: Bool
    public var hasBottomButton: Bool

    public init(rowCount: Int, hasTopImage: Bool, hasBottomButton: Bool) {
        self.rowCount = rowCount
        self.hasTopImage = hasTopImage
        self.hasBottomButton = hasBottomButton
    }
}
