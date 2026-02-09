import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WordSet.date, order: .reverse) private var wordSets: [WordSet]
    @State private var showingCreateSheet = false
    @State private var editingSet: WordSet? // For editing

    
    var body: some View {
        NavigationStack {
            List {
                
                if wordSets.isEmpty {
                    ContentUnavailableView(
                        "Inga läxor än",
                        systemImage: "book.closed",
                        description: Text("Tryck på + för att lägga till din första ordlista.")
                    )
                } else {
                    
                    ForEach(wordSets) { wordSet in
                        NavigationLink(destination: PracticeScreen(wordSet: wordSet)) {
                            WordSetRow(wordSet: wordSet)
                                .swipeActions(edge: .leading) { // Swipe from left to right
                                    Button {
                                        editingSet = wordSet // Set a state variable to trigger the sheet
                                    } label: {
                                        Label("Redigera", systemImage: "pencil")
                                    }
                                    .tint(.orange)
                                }
                        }
                       
                    }
                    .onDelete(perform: deleteWordSets) // Add this line
                }
            }
            .navigationTitle("Spelling Genius")
            .toolbar {
                Button(action: { showingCreateSheet = true }) {
                    Label("Add", systemImage: "plus")
                }
            }
            .sheet(item: $editingSet) { wordSet in
                WordSetEditor(wordSet: wordSet)
            }
            .sheet(isPresented: $showingCreateSheet) {
                WordSetEditor(wordSet: nil)
            }
        }
    }
    
    // Temporary function to test data
    private func addSampleWordSet() {
        let wordSet = WordSet(title: "Test Words", date: Date())
        
        let word1 = WordPair(english: "bird", swedish: "fågel")
        let word2 = WordPair(english: "castle", swedish: "slott")
        
        wordSet.words = [word1, word2]
        
        modelContext.insert(wordSet)
    }
    
    private func deleteWordSets(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(wordSets[index])
        }
        
        // SwiftData saves automatically, but you can wrap this in a
        // try? modelContext.save() if you want to be explicit.
    }
}



struct WordSetRow: View {
    let wordSet: WordSet
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(wordSet.title)
                .font(.headline)
            HStack {
                Text(wordSet.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(masteryText)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var masteryText: String {
        let mastered = wordSet.words.filter { $0.isMastered }.count
        return "\(mastered)/\(wordSet.words.count) mastered"
    }
}
