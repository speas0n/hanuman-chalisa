import AVFoundation
import SwiftUI

@MainActor
final class PronunciationPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isPlaying = false
    @Published private(set) var activeLine: Int?
    @Published var error: String?
    private var player: AVAudioPlayer?
    private var queue: [(URL, Int)] = []
    private var gap: Task<Void, Never>?
    private var rate: Float = 1
    private var interruption: NSObjectProtocol?

    override init() {
        super.init()
        interruption = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.stop() }
        }
    }

    deinit {
        if let interruption { NotificationCenter.default.removeObserver(interruption) }
    }

    func play(passage: Passage, line: Int? = nil, speed: Float, repeatThree: Bool) {
        stop()
        error = nil
        rate = speed
        let lines = line.map { [$0] } ?? Array(passage.lines.indices)
        var clips: [(URL, Int)] = []
        for index in lines {
            let name = String(format: "%02d-%d", passage.id, index)
            guard let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "audio") else {
                error = "This recording could not be opened. Try another passage, or reinstall the app."
                return
            }
            clips.append((url, index))
        }
        queue = Array(repeating: clips, count: repeatThree ? 3 : 1).flatMap { $0 }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
            isPlaying = true
            next()
        } catch { fail() }
    }

    func stop() {
        gap?.cancel()
        gap = nil
        player?.stop()
        player = nil
        queue.removeAll()
        isPlaying = false
        activeLine = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func next() {
        guard !queue.isEmpty else { stop(); return }
        let (url, line) = queue.removeFirst()
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.enableRate = true
            player?.rate = rate
            activeLine = line
            guard player?.play() == true else { fail(); return }
        } catch { fail() }
    }

    private func fail() {
        stop()
        error = "Audio could not play. Check your audio output and try again."
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self, self.player === player else { return }
            guard flag else { self.fail(); return }
            self.gap = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(650))
                guard !Task.isCancelled else { return }
                self?.next()
            }
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            guard let self, self.player === player else { return }
            self.fail()
        }
    }
}
