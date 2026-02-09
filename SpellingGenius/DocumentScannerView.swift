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

                // 1. Group observations into rows based on vertical midY proximity
                var rows: [[VNRecognizedTextObservation]] = []
                let yThreshold: CGFloat = 0.025 // Allows for slight tilt in the scan

                for obs in observations {
                    if let index = rows.firstIndex(where: { abs($0[0].boundingBox.midY - obs.boundingBox.midY) < yThreshold }) {
                        rows[index].append(obs)
                    } else {
                        rows.append([obs])
                    }
                }

                // 2. Sort rows top-to-bottom, and words within rows left-to-right
                let sortedRows = rows.sorted { $0[0].boundingBox.midY > $1[0].boundingBox.midY }
                
                let lines = sortedRows.map { row in
                    row.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
                       .compactMap { $0.topCandidates(1).first?.string }
                       .joined(separator: "    ") // Inject a wide gap to help the parser
                }

                let (title, pairs) = Self.parseLines(lines)

                DispatchQueue.main.async {
                    self.onCompletion(title, pairs)
                    self.dismiss()
                }
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en", "sv"]
            
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
                    let remainder = String(trimmed[prefixMatch.range.upperBound...]).trimmingCharacters(in: .whitespaces)
                    
                    // Split by the wide gap we injected (4 spaces)
                    let components = remainder.components(separatedBy: "    ").filter { !$0.isEmpty }
                    
                    if components.count >= 2 {
                        // Standard case: Left side English, Right side Swedish
                        pairs.append(TempWordPair(swedish: components.last!, english: components.first!))
                    } else {
                        // Fallback: If OCR merged them with single spaces, use last word as Swedish
                        let words = remainder.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                        if words.count >= 2 {
                            pairs.append(TempWordPair(swedish: words.last!, english: words.dropLast().joined(separator: " ")))
                        }
                    }
                } else if pairs.isEmpty {
                    // Handle multi-line title
                    title = (title == nil) ? trimmed : "\(title!) \(trimmed)"
                }
            }
            return (title, pairs)
        }
    }
}
