import SwiftUI
import VisionKit
import Vision

struct DocumentScannerView: UIViewControllerRepresentable {
    let onCompletion: (_ title: String?, _ pairs: [TempWordPair]) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion, dismiss: dismiss)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onCompletion: (_ title: String?, _ pairs: [TempWordPair]) -> Void
        let dismiss: DismissAction

        init(onCompletion: @escaping (_ title: String?, _ pairs: [TempWordPair]) -> Void, dismiss: DismissAction) {
            self.onCompletion = onCompletion
            self.dismiss = dismiss
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                onCompletion(nil, [])
                dismiss()
                return
            }
            recognizeText(in: scan.imageOfPage(at: 0))
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            dismiss()
        }

        private func recognizeText(in image: UIImage) {
            guard let cgImage = image.cgImage else {
                onCompletion(nil, [])
                dismiss()
                return
            }

            let request = VNRecognizeTextRequest { [weak self] request, error in
                guard let self = self, let observations = request.results as? [VNRecognizedTextObservation] else { return }

                // 1. Group observations into rows based on vertical proximity (Y-axis)
                // Increased threshold to 0.03 to handle paper folds/curves
                var rows: [[VNRecognizedTextObservation]] = []
                let yThreshold: CGFloat = 0.03
                
                let sortedByY = observations.sorted { $0.boundingBox.midY > $1.boundingBox.midY }

                for obs in sortedByY {
                    if let index = rows.firstIndex(where: { abs($0[0].boundingBox.midY - obs.boundingBox.midY) < yThreshold }) {
                        rows[index].append(obs)
                    } else {
                        rows.append([obs])
                    }
                }

                // 2. Process each row to find the largest horizontal gap
                let sortedRows = rows.sorted { $0[0].boundingBox.midY > $1[0].boundingBox.midY }
                
                let lines = sortedRows.map { row in
                    let sortedRow = row.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
                    
                    var maxGap: CGFloat = 0
                    var splitIndex = 0
                    
                    // If there's more than one text box, find the jump between columns
                    if sortedRow.count > 1 {
                        for i in 0..<(sortedRow.count - 1) {
                            let gap = sortedRow[i+1].boundingBox.minX - sortedRow[i].boundingBox.maxX
                            if gap > maxGap {
                                maxGap = gap
                                splitIndex = i
                            }
                        }
                    }
                    
                    let leftSide = sortedRow[0...splitIndex]
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: " ")
                    
                    let rightSide = sortedRow[(splitIndex+1)...]
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: " ")
                    
                    // Use a unique separator that the parser will look for
                    return rightSide.isEmpty ? leftSide : "\(leftSide) |SPLIT| \(rightSide)"
                }

                let (title, pairs) = Self.parseLines(lines)

                DispatchQueue.main.async {
                    self.onCompletion(title, pairs)
                    self.dismiss()
                }
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en", "sv"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                try? handler.perform([request])
            }
        }

        // MARK: - Parsing Logic

        static func parseLines(_ lines: [String]) -> (title: String?, pairs: [TempWordPair]) {
            var title: String?
            var pairs: [TempWordPair] = []
            let numberedPrefix = /^\d+\.\s*/

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }

                if let prefixMatch = trimmed.prefixMatch(of: numberedPrefix) {
                    let remainder = String(trimmed[prefixMatch.range.upperBound...])
                    
                    if remainder.contains("|SPLIT|") {
                        let parts = remainder.components(separatedBy: "|SPLIT|")
                        let english = parts[0].trimmingCharacters(in: .whitespaces)
                        let swedish = parts[1].trimmingCharacters(in: .whitespaces)
                        pairs.append(TempWordPair(swedish: swedish, english: english))
                    } else {
                        // Fallback: If OCR merged everything into one box
                        let words = remainder.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                        if words.count >= 2 {
                            pairs.append(TempWordPair(swedish: words.last!, english: words.dropLast().joined(separator: " ")))
                        }
                    }
                } else if pairs.isEmpty {
                    // Title logic: Only active until the first numbered pair is found
                    title = (title == nil) ? trimmed : "\(title!) \(trimmed)"
                }
            }
            return (title, pairs)
        }
    }
}
