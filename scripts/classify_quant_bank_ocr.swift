import AppKit
import Foundation
import Vision

struct Question: Codable {
    let topic: String
    let img: String
    let source: String
    let letter: String
    let opts: [String]
}

let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let jsonURL = root.appendingPathComponent("quant-bank.json")
let imageRoot = root.appendingPathComponent("provsfragor")
var questions = try JSONDecoder().decode([Question].self, from: Data(contentsOf: jsonURL))
let rootPattern = try! NSRegularExpression(pattern: "(?i)(√|sqrt|roten|kvadratrot|kubikrot|(?<![A-Za-z])[vV]\\s*\\d|\\d\\s*[vV]\\s*\\d)")
let fractionPattern = try! NSRegularExpression(pattern: "(?<![0-9])\\d+\\s*/\\s*\\d+(?![0-9])")
let optionPattern = try! NSRegularExpression(pattern: "^[A-D](?:\\s|$)")
var roots = 0
var fractions = 0

for i in questions.indices {
    guard questions[i].topic == "Algebra" || questions[i].topic == "Kvantitativa jämförelser (KVA)" else { continue }
    guard questions[i].source.contains("XYZ") || questions[i].source.contains("KVA") else { continue }
    let imageURL = imageRoot.appendingPathComponent(questions[i].img)
    guard let image = NSImage(contentsOf: imageURL), let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["sv-SE", "en-US"]
    try VNImageRequestHandler(cgImage: cg).perform([request])
    let observations = (request.results ?? []).sorted { $0.boundingBox.midY > $1.boundingBox.midY }
    var stem: [String] = []
    for observation in observations {
        guard let text = observation.topCandidates(1).first?.string else { continue }
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let range = NSRange(location: 0, length: (trimmed as NSString).length)
        if observation.boundingBox.minX < 0.25 && optionPattern.firstMatch(in: trimmed, range: range) != nil { break }
        stem.append(trimmed)
    }
    let text = stem.joined(separator: " ")
    let range = NSRange(location: 0, length: (text as NSString).length)
    if rootPattern.firstMatch(in: text, range: range) != nil {
        questions[i] = Question(topic: "Rötter", img: questions[i].img, source: questions[i].source, letter: questions[i].letter, opts: questions[i].opts)
        roots += 1
    } else if fractionPattern.firstMatch(in: text, range: range) != nil {
        questions[i] = Question(topic: "Bråk och decimaler", img: questions[i].img, source: questions[i].source, letter: questions[i].letter, opts: questions[i].opts)
        fractions += 1
    }
    if (i + 1) % 250 == 0 { FileHandle.standardError.write(Data("OCR \(i + 1)/\(questions.count)\n".utf8)) }
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
let data = try encoder.encode(questions)
try data.write(to: jsonURL)
let js = "window.HP_QUANT_BANK=" + String(data: data, encoding: .utf8)! + ";\n"
try js.write(to: root.appendingPathComponent("quant-bank.js"), atomically: true, encoding: .utf8)
print("OCR reclassified \(roots) root questions and \(fractions) fraction questions")
