import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    let viewModel: WordSetEditorViewModel
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, dismiss: dismiss)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let viewModel: WordSetEditorViewModel
        let dismiss: DismissAction

        init(viewModel: WordSetEditorViewModel, dismiss: DismissAction) {
            self.viewModel = viewModel
            self.dismiss = dismiss
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            guard scan.pageCount > 0, let cgImage = scan.imageOfPage(at: 0).cgImage else {
                dismiss()
                return
            }
            Task {
                await viewModel.processScannedImage(cgImage)
                dismiss()
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            dismiss()
        }
    }
}
