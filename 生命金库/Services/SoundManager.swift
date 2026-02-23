import AVFoundation

enum SoundEffect {
    case coinTap
    case coinStoreSuccess
    case openPouchDetail
    case switchPouch
    case like
    case splashEnd
}

final class SoundManager {
    static let shared = SoundManager()

    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private var sessionConfigured = false

    private init() {}

    func play(_ effect: SoundEffect) {
        guard UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true else { return }
        configureSessionIfNeeded()

        guard let url = urlFor(effect) else { return }
        do {
            if let player = players[effect] {
                player.currentTime = 0
                player.play()
                return
            }
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[effect] = player
            player.play()
        } catch {
            // silent fail
        }
    }

    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func urlFor(_ effect: SoundEffect) -> URL? {
        switch effect {
        case .coinTap:
            return Bundle.main.url(forResource: "轻触金币（铸造入口）", withExtension: "wav")
        case .coinStoreSuccess:
            return Bundle.main.url(forResource: "金币纳入囊中成功", withExtension: "aac")
        case .openPouchDetail:
            return Bundle.main.url(forResource: "打开锦囊详情", withExtension: "mp3")
        case .switchPouch:
            return Bundle.main.url(forResource: "切换锦囊", withExtension: "mp3")
        case .like:
            return Bundle.main.url(forResource: "点赞", withExtension: "wav")
        case .splashEnd:
            return Bundle.main.url(forResource: "9", withExtension: "mp3")
        }
    }
}
