import Foundation
import SwiftData

@Model
final class WordSet {
    @Attribute(.unique) var id: UUID
    var title: String
    var date: Date
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \WordPair.wordSet)
    var words: [WordPair]
    
    init(title: String = "", date: Date = Date()) {
        self.id = UUID()
        self.title = title.isEmpty ? date.formatted(date: .abbreviated, time: .omitted) : title
        self.date = date
        self.createdAt = Date()
        self.words = []
    }
}

@Model
final class WordPair {
    @Attribute(.unique) var id: UUID
    var english: String
    var swedish: String
    
    var wordSet: WordSet?
    
    @Relationship(deleteRule: .cascade, inverse: \Attempt.wordPair)
    var attempts: [Attempt]
    
    init(english: String, swedish: String) {
        self.id = UUID()
        self.english = english
        self.swedish = swedish
        self.attempts = []
    }
    
    var isMastered: Bool {
        let masteryThreshold = 3 // Will move to AppSettings later
        guard attempts.count >= masteryThreshold else { return false }
        
        let recent = attempts
            .sorted { $0.timestamp < $1.timestamp }
            .suffix(masteryThreshold)
        
        return recent.allSatisfy { $0.correct }
    }
}

@Model
final class Attempt {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var promptLanguage: String // "swedish" for MVP
    var userInput: String
    var correct: Bool
    var timeSeconds: Double
    
    var wordPair: WordPair?
    
    init(userInput: String, correct: Bool, timeSeconds: Double) {
        self.id = UUID()
        self.timestamp = Date()
        self.promptLanguage = "swedish"
        self.userInput = userInput
        self.correct = correct
        self.timeSeconds = timeSeconds
    }
}
