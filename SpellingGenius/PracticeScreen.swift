//
//  PracticeScreen.swift
//  SpellingGenius
//
//  Created by John Cieslik-Bridgen on 2026-02-08.
//

import SwiftUI
import SwiftData

struct PracticeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let wordSet: WordSet
    
    // Quiz State
    @State private var tts = TTSManager()
    @State private var currentIndex = 0
    @State private var userInput = ""
    @State private var showingFeedback = false
    @State private var isCorrect = false
    @State private var attempts: [Attempt] = []
    
    // Computed property for the current word
    var currentWord: WordPair? {
        guard currentIndex < wordSet.words.count else { return nil }
        return wordSet.words[currentIndex]
    }

    var body: some View {
        VStack(spacing: 30) {
            if let word = currentWord {
                // Progress indicator
                ProgressView(value: Double(currentIndex), total: Double(wordSet.words.count))
                    .padding()

                Spacer()

                // Display Swedish Word
                VStack(spacing: 10) {
                    Text("Swedish:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(word.swedish)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                }

                // Input Field
                TextField("Type English word", text: $userInput)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never) // Add this
                    .autocorrectionDisabled(true)        // Add this
                    .keyboardType(.asciiCapable)
                    .focused($isFocused)
                    .onSubmit(checkAnswer)
                    .disabled(showingFeedback)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .padding(.horizontal)

                // Feedback Area
                if showingFeedback {
                    feedbackSection(for: word)
                }

                Spacer()
                
                if !showingFeedback {
                    Button("Check Answer") {
                        checkAnswer()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(userInput.isEmpty)
                }

            } else {
                // Summary/Finished State
                SummaryScreen(attempts: attempts, totalWords: wordSet.words.count)
            }
            
               
        }
        .onAppear {
            Task {
                // Delay for 500 milliseconds (0.5 seconds)
                try? await Task.sleep(for: .seconds(0.5))
                
                if let word = currentWord {
                    tts.speakSwedish(word.swedish)
                }
            }
        }
        .onChange(of: currentIndex) { _, _ in
            if let word = currentWord {
                tts.speakSwedish(word.swedish)
            }
        }
        .padding()
        .navigationTitle(wordSet.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @FocusState private var isFocused: Bool

    // MARK: - Logic
    
    private func checkAnswer() {
        guard let word = currentWord else { return }
        
        isCorrect = userInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == word.english.lowercased()
        
        // Create and save the attempt
        let newAttempt = Attempt(userInput: userInput, correct: isCorrect, timeSeconds: 0) // Time tracking can be added later
        newAttempt.wordPair = word
        attempts.append(newAttempt)
        
        withAnimation {
            showingFeedback = true
        }
    }

    private func nextWord() {
        userInput = ""
        showingFeedback = false
        currentIndex += 1
    }

    // MARK: - Subviews

    @ViewBuilder
    private func feedbackSection(for word: WordPair) -> some View {
        VStack(spacing: 15) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "x.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(isCorrect ? .green : .red)
            
            if !isCorrect {
                Text("Correct answer was:")
                    .font(.subheadline)
                Text(word.english)
                    .font(.title)
                    .bold()
            } else {
                Text("Well done!")
                    .font(.title)
            }
            
            Button(currentIndex + 1 < wordSet.words.count ? "Next Word" : "See Results") {
                nextWord()
            }
            .buttonStyle(.bordered)
        }
    }

    private var quizSummary: some View {
        VStack(spacing: 20) {
            Text("Quiz Complete!")
                .font(.largeTitle)
                .bold()
            
            let correctCount = attempts.filter { $0.correct }.count
            Text("\(correctCount) out of \(wordSet.words.count) correct")
                .font(.title2)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
