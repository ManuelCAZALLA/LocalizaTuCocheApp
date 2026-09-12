import Foundation
import AVFoundation

protocol VoiceGuideServiceProtocol {
    func speak(_ text: String)
}

final class VoiceGuideService: VoiceGuideServiceProtocol {
    
    private let synthesizer: AVSpeechSynthesizer
    private let audioSession: AVAudioSession
    
    init(
        synthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer(),
        audioSession: AVAudioSession = .sharedInstance()
    ) {
        self.synthesizer = synthesizer
        self.audioSession = audioSession
    }

    private func setupAudioSession() {
        do {
            // .duckOthers: Baja el volumen mientras la app habla
            try audioSession.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Error configurando AudioSession: \(error)")
        }
    }

    func speak(_ text: String) {
        
        setupAudioSession()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectVoice()
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }

    private func selectVoice() -> AVSpeechSynthesisVoice? {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "es"
        let regionCode = Locale.current.region?.identifier ?? "ES"
        let bcp47Tag = "\(languageCode)-\(regionCode)"
        
        
        return AVSpeechSynthesisVoice(language: bcp47Tag)
            ?? AVSpeechSynthesisVoice(language: languageCode)
    }
}
