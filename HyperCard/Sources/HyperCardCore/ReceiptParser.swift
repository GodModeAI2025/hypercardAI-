import Foundation

public struct ReceiptData: Equatable {
    public var merchant: String?
    public var date: Date?
    public var gross: Double?
    public var net: Double?
    public var vat: Double?
    public var categoryHint: String?
    public var rawText: String

    public init(
        merchant: String? = nil,
        date: Date? = nil,
        gross: Double? = nil,
        net: Double? = nil,
        vat: Double? = nil,
        categoryHint: String? = nil,
        rawText: String
    ) {
        self.merchant = merchant
        self.date = date
        self.gross = gross
        self.net = net
        self.vat = vat
        self.categoryHint = categoryHint
        self.rawText = rawText
    }
}

public struct ReceiptParser {
    public init() {}

    static let amountPattern = try! NSRegularExpression(
        pattern: "(\\d{1,3}(?:[. ]\\d{3})*(?:,\\d{2})|\\d+[,.]\\d{2})",
        options: []
    )

    static let dayMonthYearPattern = try! NSRegularExpression(
        pattern: "(\\d{1,2})[./](\\d{1,2})[./](\\d{2,4})",
        options: []
    )

    static let isoDatePattern = try! NSRegularExpression(
        pattern: "(\\d{4})-(\\d{2})-(\\d{2})",
        options: []
    )

    public static func parse(_ text: String) -> ReceiptData {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var merchant: String?
        var date: Date?
        var gross: Double?
        var net: Double?
        var vat: Double?
        var lastAmount: Double?

        for line in lines {
            let amounts = amounts(in: line)
            if let amount = amounts.last {
                lastAmount = amount
            }

            if date == nil, let parsed = Self.date(in: line) {
                date = parsed
                continue
            }

            let lowered = line.lowercased()
            if amounts.isEmpty && merchant == nil && isMerchantLine(line, lowered: lowered) {
                merchant = line
            }

            if amounts.isEmpty { continue }
            if lowered.contains("netto"), net == nil { net = amounts.last }
            if lowered.contains("mwst") || lowered.contains("umsatzsteuer") || lowered.contains("vat"), vat == nil {
                vat = amounts.last
            }
            if isTotalLine(lowered), gross == nil {
                gross = amounts.last
            }
        }

        if gross == nil { gross = lastAmount }

        let categoryHint = categoryHint(merchant: merchant, text: text)

        return ReceiptData(
            merchant: merchant,
            date: date,
            gross: gross,
            net: net,
            vat: vat,
            categoryHint: categoryHint,
            rawText: text
        )
    }

    static func isTotalLine(_ lowered: String) -> Bool {
        [
            "summe", "total", "gesamt", "brutto", "endbetrag",
            "zu zahlen", "zzgl", "bearing", "total due", "fällig"
        ].contains { lowered.contains($0) }
    }

    static func isMerchantLine(_ line: String, lowered: String) -> Bool {
        guard line.count >= 2 else { return false }
        let blocked: [String] = [
            "rechnung", "datum", "nr.", "nr ", "kasse", "seite", "straße",
            "str.", "weg", "platz", "allee", "höhe", "telefon", "tel", "mail",
            "www", "http", "iban", "bic", "konto", "steuer", "id ", "uid",
            "netto", "mwst", "umsatz", "summe", "total", "seit", "beleg",
            "kaffee", "wasser", "espresso", "brot", "wurst", "schorle"
        ]
        if blocked.contains { lowered.hasPrefix($0) } { return false }
        let letters = line.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
        return letters >= 3
    }

    static func amounts(in line: String) -> [Double] {
        var result: [Double] = []
        let fullRange = NSRange(location: 0, length: line.utf16.count)
        let matches = amountPattern.matches(in: line, options: [], range: fullRange)
        for match in matches {
            guard let range = Range(match.range(at: 1), in: line) else { continue }
            if let value = IntentAnalyzer.normalizeAmount(String(line[range])) {
                result.append(value)
            }
        }
        return result
    }

    static func date(in line: String) -> Date? {
        let fullRange = NSRange(location: 0, length: line.utf16.count)
        if let match = isoDatePattern.firstMatch(in: line, options: [], range: fullRange),
           let y = Int(line.substring(match, group: 1)),
           let m = Int(line.substring(match, group: 2)),
           let d = Int(line.substring(match, group: 3)) {
            return makeDate(day: d, month: m, year: y)
        }
        if let match = dayMonthYearPattern.firstMatch(in: line, options: [], range: fullRange),
           let d = Int(line.substring(match, group: 1)),
           let m = Int(line.substring(match, group: 2)),
           let y = Int(line.substring(match, group: 3)) {
            return makeDate(day: d, month: m, year: y)
        }
        return nil
    }

    static func makeDate(day: Int, month: Int, year: Int) -> Date? {
        guard (1...31).contains(day), (1...12).contains(month) else { return nil }
        var year = year
        if year < 100 { year += year < 70 ? 2000 : 1900 }
        guard (1950...2100).contains(year) else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }

    static func categoryHint(merchant: String?, text: String) -> String? {
        let source = ((merchant ?? "") + " " + text).lowercased()
        if ["café", "cafe", "bäckerei", "bäck", "restaurant", "lunch", "coffee", "kneipe", "pizzeria", "imbiß", "imbiss"].contains { source.contains($0) } {
            return "Bewirtung"
        }
        if ["taxi", "bahn", "sbb", "flixbus", "benzin", "tankstelle", "hotel", "parkhaus", "fernbus"].contains { source.contains($0) } {
            return "Fahrt"
        }
        if ["büro", "bureau", "stapler", "papier", "office", "mediamarkt", "saturn", "druckerei", "toner"].contains { source.contains($0) } {
            return "Büro"
        }
        if ["miete", "wohnung", "strom", "gas", "wasser", "vodafone", "telekom", "miete"].contains { source.contains($0) } {
            return "Miete"
        }
        return nil
    }
}

extension String {
    func substring(_ match: NSTextCheckingResult, group: Int) -> String {
        guard let range = Range(match.range(at: group), in: self) else { return "" }
        return String(self[range])
    }
}
