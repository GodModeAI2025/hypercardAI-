import Foundation

public struct IntentAnalysis: Equatable {
    public var isExpense: Bool
    public var isTodo: Bool
    public var wantsCapture: Bool
    public var wantsCategory: Bool
    public var wantsDate: Bool
    public var wantsCurrency: Bool
    public var wantsList: Bool
    public var wantsChart: Bool
    public var threshold: Double?
    public var wantsHighlight: Bool
    public var wantsApproval: Bool

    public init(
        isExpense: Bool,
        isTodo: Bool,
        wantsCapture: Bool,
        wantsCategory: Bool,
        wantsDate: Bool,
        wantsCurrency: Bool,
        wantsList: Bool,
        wantsChart: Bool,
        threshold: Double?,
        wantsHighlight: Bool,
        wantsApproval: Bool
    ) {
        self.isExpense = isExpense
        self.isTodo = isTodo
        self.wantsCapture = wantsCapture
        self.wantsCategory = wantsCategory
        self.wantsDate = wantsDate
        self.wantsCurrency = wantsCurrency
        self.wantsList = wantsList
        self.wantsChart = wantsChart
        self.threshold = threshold
        self.wantsHighlight = wantsHighlight
        self.wantsApproval = wantsApproval
    }
}

public struct IntentAnalyzer {
    public init() {}

    public func analyze(_ rawText: String) -> IntentAnalysis {
        let text = rawText.lowercased()

        return IntentAnalysis(
            isExpense: Self.containsAny(text, ["beleg", "spesen", "quittung", "rechnung", "ausgabe", "erstatt", "kosten"]),
            isTodo: Self.containsAny(text, ["todo", "aufgabe", "erinnerung", "erledig", "checkliste", "pflichten"]),
            wantsCapture: Self.containsAny(text, ["kamera", "foto", "fotograf", "scann", "ocr", "belegfoto", "quittung fotografier"]),
            wantsCategory: Self.containsAny(text, ["kategorie", "kategorien"]),
            wantsDate: Self.containsAny(text, ["datum", "zeitpunkt", "wann", "monatsliste"]),
            wantsCurrency: Self.containsAny(text, ["betrag", "euro", "€", "summe", "kosten", "preis", "brutto", "netto"]),
            wantsList: Self.containsAny(text, ["liste", "monatsliste", "übersicht", "liste."]),
            wantsChart: Self.containsAny(text, ["diagramm", "donut", "kreisdiagramm", "aufteilung", "chart", "diagram"]),
            threshold: Self.threshold(in: rawText),
            wantsHighlight: Self.containsAny(text, ["rot", "hervorheb", "markier", "auffällig", "warnung"]),
            wantsApproval: Self.containsAny(text, ["genehmig", "freigab", "approv"])
        )
    }

    public static func containsAny(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }

    public static func threshold(in rawText: String) -> Double? {
        let lowered = rawText.lowercased()
        guard let anchor = lowered.range(of: "über") ?? lowered.range(of: ">") ?? lowered.range(of: "ab ") else {
            return nil
        }
        return parseNumber(after: lowered, from: anchor.upperBound)
    }

    static func parseNumber(after text: String, from index: String.Index) -> Double? {
        let tail = text[index...].prefix(30)
        var digits: [Character] = []
        var separators = 0
        for char in tail {
            if char.isNumber {
                digits.append(char)
            } else if (char == "," || char == "."), !digits.isEmpty {
                separators += 1
                digits.append(char)
                if separators > 2 { break }
            } else {
                if !digits.isEmpty { break }
            }
        }
        guard !digits.isEmpty else { return nil }
        return normalizeAmount(String(digits))
    }

    public static func normalizeAmount(_ raw: String) -> Double? {
        var s = raw.filter { $0.isNumber || $0 == "," || $0 == "." }
        guard !s.isEmpty else { return nil }
        let hasComma = s.contains(",")
        let hasDot = s.contains(".")
        if hasComma {
            s = s.replacingOccurrences(of: ".", with: "")
            s = s.replacingOccurrences(of: ",", with: ".")
        } else if hasDot {
            let dots = s.filter { $0 == "." }.count
            if dots > 1 {
                s = s.replacingOccurrences(of: ".", with: "")
            }
        }
        return Double(s)
    }

    public static func quotedPhrase(in text: String) -> String? {
        let patterns: [Character] = ["„", "“", "\"", "'", "‚"]
        for startChar in patterns {
            guard let start = text.firstIndex(of: startChar) else { continue }
            let rest = text[text.index(after: start)...]
            guard let end = rest.firstIndex(where: { patterns.contains($0) }) else { continue }
            let phrase = String(rest[rest.startIndex..<end])
            if !phrase.isEmpty && phrase.count < 60 {
                return phrase
            }
        }
        return nil
    }
}
