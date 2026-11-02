import AppKit
import Foundation
import PDFKit

// Build the image-backed quant question bank from the user's local HP PDFs.
// Usage: swift scripts/import_quant_bank.swift <source-root> <site-root>

struct Question: Codable {
    let topic: String
    let img: String
    let source: String
    let letter: String
    let opts: [String]
}

let fm = FileManager.default
let args = CommandLine.arguments
guard args.count == 3 else { fatalError("Usage: import_quant_bank.swift <source-root> <site-root>") }
let sourceRoot = URL(fileURLWithPath: args[1], isDirectory: true)
let siteRoot = URL(fileURLWithPath: args[2], isDirectory: true)
let imageDir = siteRoot.appendingPathComponent("provsfragor/quant-import", isDirectory: true)
try fm.createDirectory(at: imageDir, withIntermediateDirectories: true)

func regexMatches(_ pattern: String, _ text: String) -> [NSTextCheckingResult] {
    let re = try! NSRegularExpression(pattern: pattern)
    return re.matches(in: text, range: NSRange(location: 0, length: (text as NSString).length))
}

func norm(_ s: String) -> String {
    s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "sv_SE"))
}

func yearAndSeason(_ name: String) -> String? {
    let n = name.lowercased()
    guard let m = regexMatches("^(20\\d{2})(vt[12]?|ht)", n).first else { return nil }
    let ns = n as NSString
    return ns.substring(with: m.range)
}

func readPDFText(_ url: URL) -> String {
    guard let d = PDFDocument(url: url) else { return "" }
    return (0..<d.pageCount).compactMap { d.page(at: $0)?.string }.joined(separator: "\n")
}

func categoryFor(_ text: String, subject: String) -> String {
    let t = norm(text)
    let rules: [(String, [String])] = [
        ("Geometri", ["triangel", "vinkel", "cirkel", "radie", "diameter", "hypotenus", "area", "omkrets", "rektangel", "kvadrat", "kub", "volym", "cm²", "cm³", "°"]),
        ("Koordinater och avstånd", ["koordinat", "koordinatsystem", "avståndet", "punkterna", "lutning", "x-axeln", "y-axeln", "grafen"]),
        ("Statistik och sannolikhet", ["sannolikhet", "median", "medelvärde", "frekvens", "slump", "diagram", "tabell", "statistik", "andel", "procentandel"]),
        ("Flöde och pumpar", ["pump", "m³/min", "km/h", "hastighet", "fyller", "tömmer", "liter per", "arbetar tillsammans"]),
        ("Procent", ["procent", "%", "rabatt", "ökade med", "minskade med"]),
        ("Potenser", ["potens", "upphöjt", "²", "³", "^", "exponent"]),
        ("Rötter", ["√", "kvadratrot", "kubikrot", "roten ur"]),
        ("Bråk och decimaler", ["bråk", "nämnare", "täljare", "decimal", "förkorta", "gemensam nämnare", "delat med"]),
        ("Tal och delbarhet", ["delbar", "primtal", "delare", "rest", "siffrorna", "jämnt delbar", "udda tal", "heltal"]),
        ("Algebra", ["ekvation", "förenkla", "uttrycket", "sambandet", "variabel", "lös ekvationen", "x =", "y ="])
    ]
    for (topic, words) in rules where words.contains(where: t.contains) { return topic }
    switch subject {
    case "NOG": return "Kvantitativa resonemang (NOG)"
    case "DTK": return "Diagram och tabeller (DTK)"
    case "KVA": return "Kvantitativa jämförelser (KVA)"
    default: return "Algebra"
    }
}

func subjectFor(_ file: URL, _ qNo: Int) -> (String, Int) {
    let n = file.lastPathComponent.lowercased()
    if !n.contains("kvantitativ") {
        for code in ["xyz", "kva", "nog", "dtk"] where n.contains("-" + code) || n.contains("_" + code) { return (code.uppercased(), qNo) }
    }
    if qNo <= 12 { return ("XYZ", qNo) }
    if qNo <= 22 { return ("KVA", qNo - 12) }
    if qNo <= 28 { return ("NOG", qNo - 22) }
    return ("DTK", qNo - 28)
}

func answerMap(for sourceURL: URL, passNumber: Int?) -> [Int: String] {
    guard let season = yearAndSeason(sourceURL.lastPathComponent) else { return [:] }
    let folder = sourceURL.deletingLastPathComponent()
    guard let items = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else { return [:] }
    let facits = items.filter { $0.lastPathComponent.lowercased().hasPrefix(season + "-") && $0.lastPathComponent.lowercased().contains("facit") && $0.pathExtension.lowercased() == "pdf" }
    guard let facitURL = facits.sorted(by: { $0.lastPathComponent.count < $1.lastPathComponent.count }).first,
          let doc = PDFDocument(url: facitURL) else { return [:] }
    let fname = sourceURL.lastPathComponent.lowercased()
    let subjectCode = ["XYZ", "KVA", "NOG", "DTK"].first { fname.contains($0.lowercased()) }
    var selectedHeading: (PDFPage, CGFloat)?
    for i in 0..<doc.pageCount {
        guard let page = doc.page(at: i), let s = page.string else { continue }
        let ns = s as NSString
        if let passNumber {
            let matches = regexMatches("Provpass\\s+(\\d+)", s)
            guard let target = matches.first(where: { ns.substring(with: $0.range(at: 1)) == String(passNumber) }) else { continue }
            let r = target.range(at: 0)
            selectedHeading = (page, page.selection(for: r)!.bounds(for: page).midX)
            break
        }
        if let subjectCode {
            let matches = regexMatches("(?i)Delprov[^\\n]*(?:\\b|:)\\s*" + subjectCode + "\\b|Delprov[^\\n]*" + subjectCode + "\\b", s)
            if let h = matches.first {
                selectedHeading = (page, page.selection(for: h.range)!.bounds(for: page).midX)
                break
            }
        }
    }
    guard let (keyPage, targetX) = selectedHeading, let s = keyPage.string else { return [:] }
    let ns = s as NSString
    var map: [Int: String] = [:]
    for q in 1...40 {
        let matches = regexMatches("(?<![0-9])(\\d{1,2})\\s+([A-E])\\b", s).filter { ns.substring(with: $0.range(at: 1)) == String(q) }
        guard let best = matches.min(by: {
            let x1 = keyPage.selection(for: $0.range)!.bounds(for: keyPage).midX
            let x2 = keyPage.selection(for: $1.range)!.bounds(for: keyPage).midX
            return abs(x1 - targetX) < abs(x2 - targetX)
        }) else { continue }
        map[q] = ns.substring(with: best.range(at: 2))
    }
    return map
}

func makeQuestionImage(page: PDFPage, pageString: String, marker: NSTextCheckingResult, allMarkers: [NSTextCheckingResult], imageURL: URL) -> (String, String)? {
    let ns = pageString as NSString
    guard let markerSelection = page.selection(for: marker.range) else { return nil }
    let markerBox = markerSelection.bounds(for: page)
    var box = markerBox
    var questionText = ""
    var cursor = 0
    while cursor < ns.length {
        let lineRange = ns.lineRange(for: NSRange(location: cursor, length: 0))
        cursor = NSMaxRange(lineRange)
        if lineRange.length == 0 { break }
        let line = ns.substring(with: lineRange).trimmingCharacters(in: .whitespacesAndNewlines)
        if line.isEmpty { continue }
        if allMarkers.contains(where: { NSIntersectionRange($0.range, lineRange).length > 0 }) { continue }
        guard let lineSelection = page.selection(for: lineRange) else { continue }
        let r = lineSelection.bounds(for: page)
        if r.isEmpty { continue }
        let dx = (r.midX - markerBox.midX) / 1.8
        let dy = (r.midY - markerBox.midY)
        let ownDistance = dx * dx + dy * dy
        var nearest = ownDistance
        for other in allMarkers where other.range.location != marker.range.location {
            guard let os = page.selection(for: other.range) else { continue }
            let ob = os.bounds(for: page)
            let ox = (r.midX - ob.midX) / 1.8
            let oy = r.midY - ob.midY
            nearest = min(nearest, ox * ox + oy * oy)
        }
        if ownDistance <= nearest + 0.01 { box = box.union(r); questionText += line + " " }
    }
    let pageRect = page.bounds(for: .mediaBox)
    box = box.insetBy(dx: -15, dy: -15).intersection(pageRect)
    guard box.width > 24, box.height > 20 else { return nil }
    let scale: CGFloat = 1.75
    let thumb = page.thumbnail(of: CGSize(width: pageRect.width * scale, height: pageRect.height * scale), for: .mediaBox)
    guard let rep = NSBitmapImageRep(data: thumb.tiffRepresentation ?? Data()), let cg = rep.cgImage else { return nil }
    let crop = CGRect(x: box.minX * scale, y: (pageRect.height - box.maxY) * scale, width: box.width * scale, height: box.height * scale).integral.intersection(CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
    guard let cropped = cg.cropping(to: crop) else { return nil }
    let data = NSBitmapImageRep(cgImage: cropped).representation(using: .jpeg, properties: [.compressionFactor: 0.93])
    guard let data else { return nil }
    try? data.write(to: imageURL)
    return (imageURL.lastPathComponent, questionText)
}

let enumerator = fm.enumerator(at: sourceRoot, includingPropertiesForKeys: nil)!
var sources: [URL] = []
while let url = enumerator.nextObject() as? URL {
    guard url.pathExtension.lowercased() == "pdf" else { continue }
    let n = url.lastPathComponent.lowercased()
    guard !n.contains("facit"), !n.contains("version"), !n.contains("alla") else { continue }
    guard n.contains("kvantitativ") || ["xyz", "kva", "nog", "dtk"].contains(where: n.contains) else { continue }
    // The older single-subtest files are imported only when they contain searchable question text.
    sources.append(url)
}
sources.sort { $0.path < $1.path }

var all: [Question] = []
var report: [String] = []
for (sourceIndex, url) in sources.enumerated() {
    guard let doc = PDFDocument(url: url) else { continue }
    let name = url.lastPathComponent.lowercased()
    let isFullPass = name.contains("kvantitativ")
    let passNumber = isFullPass ? regexMatches("provpass[- ]?(\\d+)", name).first.flatMap { Int((name as NSString).substring(with: $0.range(at: 1))) } : nil
    let answers = answerMap(for: url, passNumber: passNumber)
    guard !answers.isEmpty else { continue }
    let season = yearAndSeason(name) ?? ""
    let year = String(season.prefix(4))
    let term = season.contains("ht") ? "höst" : "vår"
    var added = 0
    var seenNumbers = Set<Int>()
    for pageIndex in 0..<doc.pageCount {
        guard let page = doc.page(at: pageIndex), let s = page.string, s.count > 10 else { continue }
        let ns = s as NSString
        let markers = regexMatches("(?<![0-9])(\\d{1,2})\\.(?=\\s|[$-])", s).filter {
            guard let n = Int(ns.substring(with: $0.range(at: 1))), answers[n] != nil else { return false }
            // Numbered questions begin a line; adjacent question labels may share a line (e.g. "5. 6.").
            let lineRange = ns.lineRange(for: NSRange(location: $0.range.location, length: 0))
            let prefix = ns.substring(with: NSRange(location: lineRange.location, length: $0.range.location - lineRange.location)).trimmingCharacters(in: .whitespaces)
            return prefix.isEmpty || regexMatches("^\\d{1,2}\\.$", prefix).first != nil
        }
        for marker in markers {
            guard let qNo = Int(ns.substring(with: marker.range(at: 1))), let answer = answers[qNo] else { continue }
            guard !seenNumbers.contains(qNo) else { continue }
            let (subject, localNo) = subjectFor(url, qNo)
            let slug = "q-\(year)-\(season.dropFirst(4))-\(passNumber.map(String.init) ?? subject.lowercased())-p\(pageIndex+1)-n\(qNo)-s\(sourceIndex)"
            let imageURL = imageDir.appendingPathComponent(slug + ".jpg")
            guard let (imageName, questionText) = makeQuestionImage(page: page, pageString: s, marker: marker, allMarkers: markers, imageURL: imageURL) else { continue }
            seenNumbers.insert(qNo)
            let topic = categoryFor(questionText, subject: subject)
            let passLabel = passNumber.map { ", provpass \($0)" } ?? ""
            let source = "\(year) \(term) · \(subject), fråga \(localNo)\(passLabel)"
            let labels = subject == "NOG" ? ["A", "B", "C", "D", "E"] : ["A", "B", "C", "D"]
            all.append(Question(topic: topic, img: "quant-import/" + imageName, source: source, letter: answer, opts: labels))
            added += 1
        }
    }
    if added > 0 {
        let missing = (1...40).filter { answers[$0] != nil && !seenNumbers.contains($0) }
        let noKey = (1...40).filter { answers[$0] == nil }
        report.append("\(added)\tmissing=\(missing) noKey=\(noKey)\t\(url.path)")
    }
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
let jsonData = try encoder.encode(all)
let output = siteRoot.appendingPathComponent("quant-bank.json")
try jsonData.write(to: output)
let js = "window.HP_QUANT_BANK=" + String(data: jsonData, encoding: .utf8)! + ";\n"
try js.write(to: siteRoot.appendingPathComponent("quant-bank.js"), atomically: true, encoding: .utf8)
print("Imported \(all.count) questions from \(report.count) source PDFs")
print(report.joined(separator: "\n"))
