import SwiftUI
import SwiftData

struct WordSetEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let wordSet: WordSet?

    @State private var viewModel = WordSetEditorViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                } header: {
                    Button {
                        viewModel.showingScanner = true
                    } label: {
                        Label("Skanna läxa", systemImage: "doc.text.viewfinder")
                    }
                    .buttonStyle(.bordered)
                }

                Section("Information") {
                    TextField("Titel", text: $viewModel.title)
                    DatePicker("Datum", selection: $viewModel.date, displayedComponents: .date)
                }

                Section("Ordpar") {
                    ForEach($viewModel.pairs) { $pair in
                        HStack {
                            TextField("Svenska", text: $pair.swedish)
                            Divider()
                            TextField("Engelska", text: $pair.english)
                        }
                    }
                    .onDelete { viewModel.deletePairs(at: $0) }

                    Button { viewModel.addPair() } label: {
                        Label("Lägg till ord", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle(wordSet == nil ? "Ny läxa" : "Redigera läxa")
            .onAppear { viewModel.loadExistingData(from: wordSet) }
            .sheet(isPresented: $viewModel.showingScanner) {
                DocumentScannerView(viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") {
                        viewModel.save(to: modelContext, wordSet: wordSet)
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                    .fontWeight(.bold)
                }
            }
        }
    }
}
