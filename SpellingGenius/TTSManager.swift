import Foundation
import AVFoundation

@Observable
class TTSManager {
    private let synthesizer = AVSpeechSynthesizer()
    
    func speakSwedish(_ text: String) {
        // Stop any current speech before starting new one
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Explicitly set to Swedish
        utterance.voice = AVSpeechSynthesisVoice(language: "sv-SE")
        
        // Adjust speed for students (0.5 is default, 0.4 is slightly slower/clearer)
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
    }
}
