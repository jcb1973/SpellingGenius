import SwiftUI
import SwiftData

struct WordSetEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // The existing set to edit (nil if creating new)
    let wordSet: WordSet?
    
    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var pairs: [TempWordPair] = [TempWordPair()]
    @State private var showingScanner = false
    
    var body: some View {
        NavigationStack {
            
            
            
            Form {

                Section {
                } header: {
                    Button {
                        showingScanner = true
                    } label: {
                        Label("Skanna läxa", systemImage: "doc.text.viewfinder")
                    }
                    .buttonStyle(.bordered)
                }


                Section("Information") {
                    TextField("Titel", text: $title)
                    DatePicker("Datum", selection: $date, displayedComponents: .date)
                }
                
                Section("Ordpar") {
                    ForEach($pairs) { $pair in
                        HStack {
                            TextField("Svenska", text: $pair.swedish)
                            Divider()
                            TextField("Engelska", text: $pair.english)
                        }
                    }
                    .onDelete(perform: deletePair)
                    
                    Button(action: { pairs.append(TempWordPair()) }) {
                        Label("Lägg till ord", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle(wordSet == nil ? "Ny läxa" : "Redigera läxa")
            .onAppear(perform: loadExistingData)
            .sheet(isPresented: $showingScanner) {
                DocumentScannerView { scannedTitle, scannedPairs in
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
            }
            .toolbar {
                // Cleaned up toolbar with just the text buttons
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") { save() }
                        .disabled(title.isEmpty)
                        .fontWeight(.bold)
                }
            }
        }
    }
    private func loadExistingData() {
        // Only load if we are editing an existing set
        guard let wordSet = wordSet else { return }
        title = wordSet.title
        date = wordSet.date
        
        // Map existing WordPairs to our Temp format
        pairs = wordSet.words.map { TempWordPair(swedish: $0.swedish, english: $0.english) }
        
        // Ensure there's at least one empty row if the set was empty
        if pairs.isEmpty { pairs.append(TempWordPair()) }
    }
    
    private func save() {
        if let existingSet = wordSet {
            // Update existing
            existingSet.title = title
            existingSet.date = date
            
            // Clear old pairs to avoid duplicates
            existingSet.words.forEach { modelContext.delete($0) }
            
            // Add new pairs from the current state
            for pair in pairs where !pair.swedish.isEmpty {
                let newPair = WordPair(english: pair.english, swedish: pair.swedish)
                newPair.wordSet = existingSet
                modelContext.insert(newPair)
            }
        } else {
            // Create new
            let newSet = WordSet(title: title, date: date)
            for pair in pairs where !pair.swedish.isEmpty {
                let newPair = WordPair(english: pair.english, swedish: pair.swedish)
                newPair.wordSet = newSet
                modelContext.insert(newPair)
            }
            modelContext.insert(newSet)
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    private func deletePair(at offsets: IndexSet) {
        pairs.remove(atOffsets: offsets)
    }
}

// MARK: - Helper Model
// Defined outside the View struct so it is accessible to the whole file
struct TempWordPair: Identifiable {
    var id = UUID()
    var swedish: String = ""
    var english: String = ""
}
