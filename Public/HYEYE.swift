class HYEYE {
    static let sharedInstance = HYEYE()
    
    // MARK: - Properties
    let playbackState = PublishSubject<PlaybackState>()
    let playbackError = PublishSubject<Error>()
    let isPreparedToPlay = BehaviorSubject<Bool>(value: false)
    let firstFrameRendered = PublishSubject<Void>()
    
    // MARK: - Photo Capture
    func takePhoto(config: HYPhotoConfig, progressCallback: @escaping (Int, Int) -> Void) {
        // 直接在这里实现拍照逻辑，而不是调用 startPhotoCapture
        guard let player = getCurrentPlayer() else {
            print("HYEYE: No active player")
            return
        }
        
        var capturedFrames = 0
        let targetFrames = config.targetFrameCount
        
        // 实现拍照逻辑
        startCapturingFrames(
            player: player,
            interval: config.frameInterval,
            quality: config.imageQuality,
            savePath: config.savePath
        ) { frame in
            capturedFrames += 1
            progressCallback(capturedFrames, targetFrames)
            
            if capturedFrames >= targetFrames {
                self.stopCapturingFrames()
            }
        }
    }
    
    // MARK: - Private Methods
    private func getCurrentPlayer() -> Any? {
        // 返回当前播放器实例
        return nil // 实现具体逻辑
    }
    
    private func startCapturingFrames(
        player: Any,
        interval: Int,
        quality: Float,
        savePath: String?,
        frameCallback: @escaping (Data) -> Void
    ) {
        // 实现帧捕获逻辑
    }
    
    private func stopCapturingFrames() {
        // 停止帧捕获
    }
}

// MARK: - Supporting Types
public struct HYPhotoConfig {
    let frameInterval: Int
    let targetFrameCount: Int
    let savePath: String?
    let imageQuality: Float
    let saveOriginalData: Bool
    
    public init(
        frameInterval: Int = 5,
        targetFrameCount: Int = 100,
        savePath: String? = nil,
        imageQuality: Float = 0.8,
        saveOriginalData: Bool = false
    ) {
        self.frameInterval = frameInterval
        self.targetFrameCount = targetFrameCount
        self.savePath = savePath
        self.imageQuality = imageQuality
        self.saveOriginalData = saveOriginalData
    }
}

public enum PlaybackState {
    case idle
    case preparing
    case playing
    case paused
    case stopped
    case error(Error)
}