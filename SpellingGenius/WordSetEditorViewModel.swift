import Foundation
import Observation
import SwiftData
import Vision
import CoreGraphics
import SwiftUI

// MARK: - Temporary Word Pair Model

struct TempWordPair: Identifiable {
    var id = UUID()
    var swedish: String = ""
    var english: String = ""
}

// MARK: - ViewModel

@MainActor
@Observable
final class WordSetEditorViewModel {
    var title = ""
    var date = Date()
    var pairs: [TempWordPair] = [TempWordPair()]
    var showingScanner = false

    var canSave: Bool { !title.isEmpty }

    // MARK: - Data Loading

    func loadExistingData(from wordSet: WordSet?) {
        guard let wordSet else { return }
        title = wordSet.title
        date = wordSet.date
        pairs = wordSet.words.map { TempWordPair(swedish: $0.swedish, english: $0.english) }
        if pairs.isEmpty { pairs.append(TempWordPair()) }
    }

    // MARK: - Pair Management

    func addPair() {
        pairs.append(TempWordPair())
    }

    func deletePairs(at offsets: IndexSet) {
        pairs.remove(atOffsets: offsets)
    }

    // MARK: - Persistence

    func save(to modelContext: ModelContext, wordSet: WordSet?) {
        if let existingSet = wordSet {
            existingSet.title = title
            existingSet.date = date
            existingSet.words.forEach { modelContext.delete($0) }

            for pair in pairs where !pair.swedish.isEmpty {
                let newPair = WordPair(english: pair.english, swedish: pair.swedish)
                newPair.wordSet = existingSet
                modelContext.insert(newPair)
            }
        } else {
            let newSet = WordSet(title: title, date: date)
            for pair in pairs where !pair.swedish.isEmpty {
                let newPair = WordPair(english: pair.english, swedish: pair.swedish)
                newPair.wordSet = newSet
                modelContext.insert(newPair)
            }
            modelContext.insert(newSet)
        }
        try? modelContext.save()
    }

    // MARK: - Scan Processing

    func processScannedImage(_ cgImage: CGImage) async {
        let lines = await Task.detached(priority: .userInitiated) {
            Self.performOCR(on: cgImage)
        }.value

        let (scannedTitle, scannedPairs) = Self.parseLines(lines)

        if let scannedTitle, !scannedTitle.isEmpty, title.isEmpty {
            title = scannedTitle
        }
        if let last = pairs.last, last.swedish.isEmpty && last.english.isEmpty {
            pairs.removeLast()
        }
        pairs.append(contentsOf: scannedPairs)
        if pairs.isEmpty {
            pairs.append(TempWordPair())
        }
    }

    // MARK: - OCR

    nonisolated private static func performOCR(on cgImage: CGImage) -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en", "sv"]

        try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])

        guard let observations = request.results else { return [] }
        return buildLines(from: observations)
    }

    // MARK: - Line Building

    nonisolated static func buildLines(from observations: [VNRecognizedTextObservation]) -> [String] {
        guard !observations.isEmpty else { return [] }

        let rowClusterThreshold: CGFloat = 0.03
        let sortedByY = observations.sorted { $0.boundingBox.midY > $1.boundingBox.midY }

        var rows: [[VNRecognizedTextObservation]] = []
        for obs in sortedByY {
            if let index = rows.firstIndex(where: {
                abs($0[0].boundingBox.midY - obs.boundingBox.midY) < rowClusterThreshold
            }) {
                rows[index].append(obs)
            } else {
                rows.append([obs])
            }
        }

        let sortedRows = rows.sorted { $0[0].boundingBox.midY > $1[0].boundingBox.midY }

        return sortedRows.map { row in
            let sortedRow = row.sorted { $0.boundingBox.minX < $1.boundingBox.minX }

            guard sortedRow.count > 1 else {
                return sortedRow.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
            }

            // Find the largest horizontal gap to identify the column boundary
            var maxGap: CGFloat = 0
            var splitIndex = 0

            for i in 0..<(sortedRow.count - 1) {
                let gap = sortedRow[i + 1].boundingBox.minX - sortedRow[i].boundingBox.maxX
                if gap > maxGap {
                    maxGap = gap
                    splitIndex = i
                }
            }

            let leftSide = sortedRow[0...splitIndex]
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")

            let rightSide = sortedRow[(splitIndex + 1)...]
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")

            guard !rightSide.isEmpty else { return leftSide }
            return "\(leftSide) \(splitMarker) \(rightSide)"
        }
    }

    // MARK: - Parsing

    nonisolated static let splitMarker = "|SPLIT|"

    nonisolated static func parseLines(_ lines: [String]) -> (title: String?, pairs: [TempWordPair]) {
        var title: String?
        var pairs: [TempWordPair] = []
        let numberedPrefix = /^\d+\.\s*/

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            guard let prefixMatch = trimmed.prefixMatch(of: numberedPrefix) else {
                // Non-numbered lines before any pairs are treated as the title
                if pairs.isEmpty {
                    title = title.map { "\($0) \(trimmed)" } ?? trimmed
                }
                continue
            }

            let remainder = String(trimmed[prefixMatch.range.upperBound...])

            // Try structured split first (from column detection)
            if remainder.contains(splitMarker) {
                let parts = remainder.components(separatedBy: splitMarker)
                guard parts.count >= 2 else { continue }
                let english = parts[0].trimmingCharacters(in: .whitespaces)
                let swedish = parts[1].trimmingCharacters(in: .whitespaces)
                guard !english.isEmpty, !swedish.isEmpty else { continue }
                pairs.append(TempWordPair(swedish: swedish, english: english))
            } else {
                // Fallback: last word is Swedish, rest is English
                let words = remainder.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                guard words.count >= 2 else { continue }
                let swedish = words[words.count - 1]
                let english = words.dropLast().joined(separator: " ")
                pairs.append(TempWordPair(swedish: swedish, english: english))
            }
        }

        return (title, pairs)
    }
}
