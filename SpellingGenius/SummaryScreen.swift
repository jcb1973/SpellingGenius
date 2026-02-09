import SwiftUI

struct SummaryScreen: View {
    @Environment(\.dismiss) private var dismiss
    let attempts: [Attempt]
    let totalWords: Int
    
    private var score: Int {
        attempts.filter { $0.correct }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Score Section
            VStack(spacing: 10) {
                Text("Resultat")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text("\(score) / \(totalWords)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(scoreColor)
                
                Text(feedbackMessage)
                    .font(.headline)
            }
            .padding(.vertical, 40)
            
            // Results List
            List {
                Section("Genomgång") {
                    ForEach(attempts) { attempt in
                        ResultRow(attempt: attempt)
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            // Footer Action
            Button(action: { dismiss() }) {
                Text("Färdig")
                    .frame(maxWidth: .infinity)
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .navigationBarBackButtonHidden(true) // Force them to use the "Färdig" button
    }
    
    private var scoreColor: Color {
        let percentage = Double(score) / Double(totalWords)
        if percentage >= 0.8 { return .green }
        if percentage >= 0.5 { return .orange }
        return .red
    }
    
    private var feedbackMessage: String {
        let percentage = Double(score) / Double(totalWords)
        if percentage == 1.0 { return "Perfekt! 🥳" }
        if percentage >= 0.7 { return "Bra jobbat! 👍" }
        return "Fortsätt öva! 💪"
    }
}

struct ResultRow: View {
    let attempt: Attempt
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(attempt.wordPair?.swedish ?? "Okänt ord")
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text("Ditt svar:")
                    Text(attempt.userInput.isEmpty ? "(tomt)" : attempt.userInput)
                        .italic()
                }
                .font(.caption)
                .foregroundStyle(attempt.correct ? .green : .red)
            }
            
            Spacer()
            
            if !attempt.correct {
                VStack(alignment: .trailing) {
                    Text("Rätt svar:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(attempt.wordPair?.english ?? "")
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
