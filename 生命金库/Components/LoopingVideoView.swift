import SwiftUI
import AVFoundation

// MARK: - LoopingVideoView
// SwiftUI wrapper for a transparent, seamlessly-looping video.
// Designed for HEVC + Alpha Channel videos (e.g. coin_spin.mov).
// The view and its AVPlayerLayer both use a .clear background so
// the video alpha blends naturally with whatever is behind it.

struct LoopingVideoView: View {
    let resourceName: String
    let fileExtension: String
    var fallback: AnyView? = nil   // shown when video file is missing

    @State private var videoFound = true

    var body: some View {
        Group {
            if videoFound {
                LoopingPlayerRepresentable(
                    resourceName: resourceName,
                    fileExtension: fileExtension,
                    onFileNotFound: { videoFound = false }
                )
                .background(Color.clear)
            } else {
                fallback ?? AnyView(EmptyView())
            }
        }
    }
}

// MARK: - UIViewRepresentable bridge

private struct LoopingPlayerRepresentable: UIViewRepresentable {
    let resourceName: String
    let fileExtension: String
    var onFileNotFound: () -> Void

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        LoopingPlayerUIView(
            resourceName: resourceName,
            fileExtension: fileExtension,
            onFileNotFound: onFileNotFound
        )
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {}
}

// MARK: - Backing UIView

final class LoopingPlayerUIView: UIView {
    private let playerLayer  = AVPlayerLayer()
    private var queuePlayer: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    init(resourceName: String,
         fileExtension: String,
         onFileNotFound: @escaping () -> Void) {

        super.init(frame: .zero)
        backgroundColor = .clear

        // ── 1. Locate the asset ──────────────────────────────────
        guard let url = Bundle.main.url(
            forResource: resourceName,
            withExtension: fileExtension
        ) else {
            print(String(localized: "⚠️ LoopingVideoView: '\(resourceName).\(fileExtension)' not found in bundle."))
            DispatchQueue.main.async { onFileNotFound() }
            return
        }

        // ── 2. Set up seamless looping ───────────────────────────
        let templateItem = AVPlayerItem(url: url)
        let player       = AVQueuePlayer()
        looper           = AVPlayerLooper(player: player, templateItem: templateItem)
        queuePlayer      = player

        player.isMuted = true   // decorative element – no audio bleed

        // ── 3. Configure AVPlayerLayer for transparency ──────────
        playerLayer.player          = player
        playerLayer.videoGravity    = .resizeAspect
        playerLayer.backgroundColor = UIColor.clear.cgColor  // essential for alpha

        layer.backgroundColor = UIColor.clear.cgColor
        layer.addSublayer(playerLayer)

        player.play()
    }

    required init?(coder: NSCoder) { fatalError() }

    // Keep playerLayer frame in sync with the view on every layout pass
    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}

// MARK: - Convenience initialiser (coin_spin defaults)

extension LoopingVideoView {
    /// Pre-configured for the spinning coin asset with GoldCoinView fallback.
    static func coin(size: CGFloat) -> some View {
        LoopingVideoView(
            resourceName: "coin_spin",
            fileExtension: "mov",
            fallback: AnyView(GoldCoinView(size: size))
        )
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        AppBackground()
        LoopingVideoView.coin(size: 220)
    }
}
