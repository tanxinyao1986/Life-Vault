import SwiftUI
import AVFoundation
import SwiftData

// MARK: - SplashView

struct SplashView: View {
    @State private var player: AVPlayer?
    @State private var splashOpacity = 1.0

    var body: some View {
        ZStack {
            // 主界面始终在底层，Splash 淡出后自然显现
            ContentView()

            // 视频层
            ZStack {
                Color.black.ignoresSafeArea()

                if let player {
                    VideoFillView(player: player)
                        .ignoresSafeArea()
                }
            }
            .ignoresSafeArea()
            .opacity(splashOpacity)
            .allowsHitTesting(splashOpacity > 0.05)
        }
        .onAppear { startVideo() }
    }

    // MARK: - Private

    private func startVideo() {
        guard let url = Bundle.main.url(forResource: "福袋金币炸裂视频", withExtension: "mov") else {
            // 视频资源不存在时静默跳过
            withAnimation(.easeOut(duration: 0.4)) { splashOpacity = 0 }
            return
        }

        let avPlayer = AVPlayer(url: url)
        avPlayer.isMuted = false          // 保留金币音效
        player = avPlayer
        avPlayer.play()

        // 异步读取真实时长，在视频结束前 0.8s 开始淡出
        Task {
            let asset = AVURLAsset(url: url)
            let videoDuration: Double
            if let dur = try? await asset.load(.duration) {
                videoDuration = CMTimeGetSeconds(dur)
            } else {
                videoDuration = 5.0   // 读取失败时的保底时长
            }

            let fadeStart = max(videoDuration - 0.8, 0.5)
            try? await Task.sleep(for: .seconds(fadeStart))

            withAnimation(.easeInOut(duration: 0.8)) {
                splashOpacity = 0
            }
        }
    }
}

// MARK: - VideoFillView
// 以 sublayer 方式添加 AVPlayerLayer，在 layoutSubviews 中强制同步 frame，
// 确保 resizeAspectFill 真正填满全屏、无黑边。

struct VideoFillView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

final class PlayerContainerView: UIView {
    let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 每次 SwiftUI 重新布局时，强制将 playerLayer 拉伸至与 view 完全一致
        // setDisableActions 防止 layer 产生隐式位移动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}

// MARK: - Preview

#Preview {
    SplashView()
        .modelContainer(for: SuccessEntry.self, inMemory: true)
}
