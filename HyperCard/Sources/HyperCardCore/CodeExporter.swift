import Foundation

public struct CodeExporter {
    public init() {}

    public static func swiftSource(for spec: CardSpec) -> String {
        var parts: [String] = []
        var imports = ["import SwiftUI", "import SwiftData"]
        if spec.hasComponent(.chart) { imports.append("import Charts") }
        parts.append(imports.joined(separator: "\n"))
        parts.append("")
        parts.append(modelSource(for: spec))
        if spec.hasComponent(.chart) {
            parts.append("")
            parts.append(categoryTotalSource)
        }
        parts.append("")
        parts.append(viewSource(for: spec))
        parts.append("")
        parts.append(appSource(for: spec))
        return parts.joined(separator: "\n")
    }

    static let categoryTotalSource = """
    struct CategoryTotal: Identifiable {
        let key: String
        let value: Double
        var id: String { key }
    }
    """

    static func modelSource(for spec: CardSpec) -> String {
        switch spec.entity {
        case .expense:
            return """
            @Model
            final class Expense {
                var merchant: String
                var category: String
                var gross: Double
                var date: Date
                var needsApproval: Bool

                init(merchant: String = "", category: String = "Sonstiges", gross: Double = 0, date: Date = .now, needsApproval: Bool = false) {
                    self.merchant = merchant
                    self.category = category
                    self.gross = gross
                    self.date = date
                    self.needsApproval = needsApproval
                }
            }
            """
        case .todo:
            return """
            @Model
            final class TodoEntry {
                var title: String
                var due: Date?
                var done: Bool

                init(title: String = "", due: Date? = nil, done: Bool = false) {
                    self.title = title
                    self.due = due
                    self.done = done
                }
            }
            """
        case .note:
            return """
            @Model
            final class NoteEntry {
                var text: String
                var createdAt: Date

                init(text: String = "", createdAt: Date = .now) {
                    self.text = text
                    self.createdAt = createdAt
                }
            }
            """
        }
    }
    static func viewSource(for spec: CardSpec) -> String {
        switch spec.entity {
        case .expense: return expenseView(for: spec)
        case .todo: return todoView(for: spec)
        case .note: return noteView(for: spec)
        }
    }

    static func expenseView(for spec: CardSpec) -> String {
        let hasCategory = spec.hasComponent(.category)
        let hasDate = spec.hasComponent(.date)
        let hasCheck = spec.hasComponent(.check)
        let hasChart = spec.hasComponent(.chart)
        let hasList = spec.hasComponent(.list)
        let listTitle = componentListTitle(for: spec, fallback: "Einträge")
        let buttonLabel = componentButtonLabel(for: spec, fallback: "Speichern")
        let threshold = spec.rules.first?.threshold

        var l: [String] = []
        l.append("struct ExpenseCardView: View {")
        l.append("    @Environment(\\.modelContext) private var context")
        l.append("    @Query(sort: \\Expense.date, order: .reverse) private var entries: [Expense]")
        l.append("")
        l.append("    @State private var merchant = \"\"")
        if hasCategory { l.append("    @State private var category = \"Sonstiges\"") }
        l.append("    @State private var grossText = \"\"")
        if hasDate { l.append("    @State private var date = Date.now") }
        if hasCheck { l.append("    @State private var needsApproval = false") }
        l.append("")
        l.append("    private var gross: Double {")
        l.append("        Double(grossText.replacingOccurrences(of: \",\", with: \".\")) ?? 0")
        l.append("    }")
        if hasChart {
            l.append("")
            l.append("    private var categoryTotals: [CategoryTotal] {")
            l.append("        Dictionary(grouping: entries, by: \\.category)")
            l.append("            .map { CategoryTotal(key: $0, value: $1.reduce(0) { $0 + $1.gross }) }")
            l.append("            .sorted { $0.value > $1.value }")
            l.append("    }")
        }
        l.append("")
        l.append("    var body: some View {")
        l.append("        Form {")
        l.append("            Section(\"Händler\") {")
        l.append("                TextField(\"z. B. Café Kraft\", text: $merchant)")
        l.append("            }")
        if hasCategory {
            l.append("            Section(\"Kategorie\") {")
            l.append("                Picker(\"Kategorie\", selection: $category) {")
            l.append("                    ForEach([\"Bewirtung\", \"Fahrt\", \"Büro\", \"Miete\", \"Sonstiges\"], id: \\.self) { option in")
            l.append("                        Text(option).tag(option)")
            l.append("                    }")
            l.append("                }")
            l.append("            }")
        }
        l.append("            Section(\"Bruttobetrag\") {")
        l.append("                HStack {")
        l.append("                    TextField(\"0,00\", text: $grossText)")
        l.append("                    Text(\"€\").foregroundStyle(.secondary)")
        l.append("                }")
        l.append("            }")
        if hasDate {
            l.append("            Section(\"Datum\") {")
            l.append("                DatePicker(\"Datum\", selection: $date, displayedComponents: .date)")
            l.append("            }")
        }
        if let threshold {
            l.append("            Section {")
            l.append("                if gross > \(formatNumber(threshold)) {")
            l.append("                    Text(\"Betrag über \(formatNumber(threshold)) €\").foregroundStyle(.red)")
            l.append("                    Toggle(\"Genehmigung erforderlich\", isOn: $needsApproval)")
            l.append("                }")
            l.append("            }")
        }
        l.append("            Section {")
        l.append("                Button(\"\(buttonLabel)\") {")
        var insertArgs = ["merchant: merchant"]
        if hasCategory { insertArgs.append("category: category") }
        insertArgs.append("gross: gross")
        if hasDate { insertArgs.append("date: date") }
        if hasCheck { insertArgs.append("needsApproval: needsApproval") }
        l.append("                    context.insert(Expense(\(insertArgs.joined(separator: ", ")))")
        l.append("                    merchant = \"\"")
        l.append("                    grossText = \"\"")
        if hasCheck { l.append("                    needsApproval = false") }
        l.append("                }")
        l.append("                .buttonStyle(.borderedProminent)")
        l.append("            }")
        if hasChart {
            let chartTitle = componentChartTitle(for: spec)
            l.append("            Section(\"\(chartTitle)\") {")
            l.append("                if entries.isEmpty {")
            l.append("                    Text(\"Noch keine Einträge\").foregroundStyle(.secondary)")
            l.append("                } else {")
            l.append("                    Chart(categoryTotals) { item in")
            l.append("                        SectorMark(")
            l.append("                            angle: .value(\"Summe\", item.value),")
            l.append("                            innerRadius: .ratio(0.6),")
            l.append("                            angularInset: 1.5")
            l.append("                        )")
            l.append("                        .foregroundStyle(by: .value(\"Kategorie\", item.key))")
            l.append("                    }")
            l.append("                    .frame(height: 220)")
            l.append("                }")
            l.append("            }")
        }
        if hasList {
            l.append("            Section(\"\(listTitle)\") {")
            l.append("                ForEach(entries) { entry in")
            l.append("                    LabeledContent(")
            l.append("                        entry.merchant.isEmpty ? \"–\" : entry.merchant,")
            l.append("                        value: entry.gross.formatted(.currency(code: \"EUR\"))")
            l.append("                    )")
            l.append("                }")
            l.append("                .onDelete { indexSet in")
            l.append("                    for index in indexSet {")
            l.append("                        context.delete(entries[index])")
            l.append("                    }")
            l.append("                }")
            l.append("            }")
        }
        l.append("        }")
        l.append("        .navigationTitle(\"\(spec.title)\")")
        l.append("    }")
        l.append("}")
        return l.joined(separator: "\n")
    }
    static func todoView(for spec: CardSpec) -> String {
        let hasDate = spec.hasComponent(.date)
        let listTitle = componentListTitle(for: spec, fallback: "Offene Aufgaben")
        let buttonLabel = componentButtonLabel(for: spec, fallback: "Hinzufügen")
        var l: [String] = []
        l.append("struct TodoCardView: View {")
        l.append("    @Environment(\\.modelContext) private var context")
        l.append("    @Query private var entries: [TodoEntry]")
        l.append("")
        l.append("    @State private var title = \"\"")
        if hasDate { l.append("    @State private var due = Date.now") }
        l.append("")
        l.append("    var body: some View {")
        l.append("        Form {")
        l.append("            Section(\"Aufgabe\") {")
        l.append("                TextField(\"Was ist zu erledigen?\", text: $title)")
        l.append("            }")
        if hasDate {
            l.append("            Section(\"Fällig am\") {")
            l.append("                DatePicker(\"Fällig am\", selection: $due, displayedComponents: .date)")
            l.append("            }")
        }
        l.append("            Section {")
        l.append("                Button(\"\(buttonLabel)\") {")
        if hasDate {
            l.append("                    context.insert(TodoEntry(title: title, due: due))")
        } else {
            l.append("                    context.insert(TodoEntry(title: title))")
        }
        l.append("                    title = \"\"")
        l.append("                }")
        l.append("                .buttonStyle(.borderedProminent)")
        l.append("            }")
        l.append("            Section(\"\(listTitle)\") {")
        l.append("                ForEach(entries) { entry in")
        l.append("                    HStack {")
        l.append("                        Text(entry.title)")
        l.append("                        Spacer()")
        if hasDate {
            l.append("                        if let due = entry.due {")
            l.append("                            Text(due, format: .dateTime.day().month().year())")
            l.append("                                .font(.caption)")
            l.append("                                .foregroundStyle(.secondary)")
            l.append("                        }")
        }
        l.append("                        Button {")
        l.append("                            context.delete(entry)")
        l.append("                        } label: {")
        l.append("                            Image(systemName: \"trash\")")
        l.append("                        }")
        l.append("                        .buttonStyle(.borderless)")
        l.append("                    }")
        l.append("                }")
        l.append("            }")
        l.append("        }")
        l.append("        .navigationTitle(\"\(spec.title)\")")
        l.append("    }")
        l.append("}")
        return l.joined(separator: "\n")
    }
    static func noteView(for spec: CardSpec) -> String {
        let listTitle = componentListTitle(for: spec, fallback: "Einträge")
        let buttonLabel = componentButtonLabel(for: spec, fallback: "Speichern")
        var l: [String] = []
        l.append("struct NoteCardView: View {")
        l.append("    @Environment(\\.modelContext) private var context")
        l.append("    @Query(sort: \\NoteEntry.createdAt, order: .reverse) private var entries: [NoteEntry]")
        l.append("")
        l.append("    @State private var text = \"\"")
        l.append("")
        l.append("    var body: some View {")
        l.append("        Form {")
        l.append("            Section(\"Notiz\") {")
        l.append("                TextField(\"Notiz\", text: $text, axis: .vertical)")
        l.append("                    .lineLimit(3...8)")
        l.append("            }")
        l.append("            Section {")
        l.append("                Button(\"\(buttonLabel)\") {")
        l.append("                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)")
        l.append("                    guard !trimmed.isEmpty else { return }")
        l.append("                    context.insert(NoteEntry(text: trimmed))")
        l.append("                    text = \"\"")
        l.append("                }")
        l.append("                .buttonStyle(.borderedProminent)")
        l.append("            }")
        l.append("            Section(\"\(listTitle)\") {")
        l.append("                ForEach(entries) { entry in")
        l.append("                    VStack(alignment: .leading, spacing: 2) {")
        l.append("                        Text(entry.text)")
        l.append("                        Text(entry.createdAt, format: .dateTime.day().month().year())")
        l.append("                            .font(.caption)")
        l.append("                            .foregroundStyle(.secondary)")
        l.append("                    }")
        l.append("                }")
        l.append("                .onDelete { indexSet in")
        l.append("                    for index in indexSet {")
        l.append("                        context.delete(entries[index])")
        l.append("                    }")
        l.append("                }")
        l.append("            }")
        l.append("        }")
        l.append("        .navigationTitle(\"\(spec.title)\")")
        l.append("    }")
        l.append("}")
        return l.joined(separator: "\n")
    }
    static func appSource(for spec: CardSpec) -> String {
        let viewName: String
        let model: String
        switch spec.entity {
        case .expense:
            viewName = "ExpenseCardView"
            model = "Expense"
        case .todo:
            viewName = "TodoCardView"
            model = "TodoEntry"
        case .note:
            viewName = "NoteCardView"
            model = "NoteEntry"
        }
        return """
        @main
        struct HyperCardGeneratedApp: App {
            var body: some Scene {
                WindowGroup {
                    NavigationStack {
                        \(viewName)()
                    }
                }
                .modelContainer(for: \(model).self)
            }
        }
        """
    }

    static func formatNumber(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(value)
    }

    static func componentListTitle(for spec: CardSpec, fallback: String) -> String {
        for component in spec.components {
            if case .list(let title) = component { return title }
        }
        return fallback
    }

    static func componentButtonLabel(for spec: CardSpec, fallback: String) -> String {
        for component in spec.components {
            if case .button(let label, _) = component { return label }
        }
        return fallback
    }

    static func componentChartTitle(for spec: CardSpec) -> String {
        for component in spec.components {
            if case .chart(let title, _) = component { return title }
        }
        return "Diagramm"
    }
}
