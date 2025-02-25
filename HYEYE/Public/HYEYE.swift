//
//  HYEYE.swift
//  Pod
//
//  Created by stephenchen on 2025/01/27.
//

@_exported import IJKMediaFramework
import IJKMediaFramework.IJKFFOptions
import Photos
import AVFoundation

public protocol HYEYEProtocol {
    func openVideo(url: URL) -> IJKFFMoviePlayerController?
}

public protocol HYEYEDelegate: AnyObject {
    func playbackStateDidChange(_ state: IJKMPMoviePlaybackState)
    func playbackDidFinishWithError(_ error: HYEYE.PlaybackError)
    func playbackDidPrepared()
    func playbackFirstFrameRendered()
    func recordingStateDidChange(isRecording: Bool, path: String?)
    func didCaptureImage(_ image: UIImage)
    func captureProgressDidUpdate(current: Int, total: Int)
}

public class HYEYE: NSObject {
    // MARK: - Properties
    public static let sharedInstance = HYEYE().priInit()
    public weak var delegate: HYEYEDelegate?
    
    private var player: IJKFFMoviePlayerController?
    private var currentUrl: URL?
    private var isPraperedToPlay: Bool = false
    
    // 进度相关属性
    private var lastProgressUpdate: TimeInterval = 0
    private let progressUpdateInterval: TimeInterval = 0.1
    
    // 录制相关属性
    private var isRecording = false
    private var currentRecordingPath: String?
    
    private var lastError: Error?
    
    // 重试相关属性
    private var prepareRetryCount = 0
    private let maxPrepareRetryCount = 3
    
    private func priInit() -> HYEYE {
        registNotice()
        return self
    }
    
    // MARK: - Public Methods
    public func play() {
        guard let player else {
            print("HYEYE Error: player is nil")
            handlePlaybackError(.playbackFailed)
            return
        }
        
        if !player.isPreparedToPlay {
            print("HYEYE: player not prepared, preparing first")
            player.prepareToPlay()
        } else {
            print("HYEYE: starting playback")
            player.play()
        }
    }
    
    public func pause() {
        guard let player else { return }
        print("HYEYE: stopping playback")
        
        // 先暂停播放
        player.pause()
        
        // 检查停止是否成功
        if player.playbackState != .stopped {
            print("HYEYE Error: Failed to stop playback")
        }
    }
    
    public func shutdown() {
        guard let player else { return }
        print("HYEYE: shutting down player")
        player.shutdown()
        self.player = nil
    }
    
    public func checkPreparedToPlay() -> Bool {
        return player?.isPreparedToPlay ?? false
    }
    
    public func checkIsPlaying() -> Bool {
        return player?.isPlaying() ?? false
    }
    
    public func prepareToPlay() {
        guard let player else {
            print("HYEYE Error: player is nil")
            handlePlaybackError(.playbackFailed)
            return
        }
        
        print("HYEYE: preparing to play")
        
        // 确保播放器处于正确状态
        if player.playbackState == .playing {
            player.stop()
        }
        
        isPraperedToPlay = true
        player.prepareToPlay()
    }
    
    public func currentPlaybackUrl() -> URL? {
        return currentUrl
    }
    
    public func openVideo(url: URL) -> IJKFFMoviePlayerController? {
        print("HYEYE: opening video with url: \(url)")
        
        // 如果已有播放器实例，先关闭它
        if let existingPlayer = player {
            existingPlayer.shutdown()
            self.player = nil
        }
        
        // 创建新的播放器实例
        let options = IJKFFOptions.byDefault()
        
        // 添加 MJPEG 相关配置
        options?.setPlayerOptionIntValue(1, forKey: "rtp-jpeg-parse-packet-method")
        options?.setPlayerOptionIntValue(0, forKey: "videotoolbox") // 关闭硬解码
        options?.setPlayerOptionIntValue(1, forKey: "framedrop") // 允许丢帧
        options?.setPlayerOptionIntValue(15, forKey: "max-fps") // 限制最大帧率
        
        // 设置缓冲区大小
        options?.setPlayerOptionIntValue(1, forKey: "packet-buffering")
        options?.setPlayerOptionIntValue(10, forKey: "min-frames")
        options?.setPlayerOptionIntValue(15 * 1024 * 1024, forKey: "max-buffer-size")
        
        // 设置重连参数
        options?.setFormatOptionIntValue(1, forKey: "reconnect")
        options?.setFormatOptionIntValue(1, forKey: "reconnect_at_eof")
        options?.setFormatOptionIntValue(1, forKey: "reconnect_streamed")
        options?.setFormatOptionIntValue(4, forKey: "reconnect_delay_max")
        
        // 添加后台播放配置
        options?.setPlayerOptionIntValue(1, forKey: "pause-in-background")
        
        // 创建新的播放器
        let newPlayer = IJKFFMoviePlayerController(contentURL: url, with: options)
        newPlayer?.shouldAutoplay = true
        newPlayer?.scalingMode = .aspectFit
        newPlayer?.shouldShowHudView = false
        newPlayer?.delegate = self
        
        // 设置后台播放
        newPlayer?.setPauseInBackground(false)
        
        self.player = newPlayer
        self.currentUrl = url
        
        return newPlayer
    }
    
    // 截图方法
    public func takeSnapshot() -> UIImage? {
        guard let player = player else {
            print("HYEYE: 没有活动的播放器")
            return nil
        }
        return player.thumbnailImageAtCurrentTime()
    }
    
    // 更新进度的辅助方法
    private func updateProgress(count: Int, total: Int) {
        let now = Date().timeIntervalSince1970
        if now - lastProgressUpdate >= progressUpdateInterval {
            delegate?.captureProgressDidUpdate(current: count, total: total)
            lastProgressUpdate = now
        }
    }
    
    // MARK: - Photo Capture
    public typealias PhotoConfig = HYPhotoConfig
    
    public func takePhoto(config: HYPhotoConfig, progressCallback: @escaping (Int, Int) -> Void) {
        guard let player = player else {
            print("HYEYE: 没有活动的播放器")
            progressCallback(0, 0)
            return
        }
        
        if let image = player.thumbnailImageAtCurrentTime() {
            if let savePath = config.savePath {
                saveToFile(image: image, path: savePath, quality: config.imageQuality)
            } else {
                PHPhotoLibrary.requestAuthorization { [weak self] status in
                    if status == .authorized {
                        self?.saveToPhotoLibrary(image: image, quality: config.imageQuality)
                    }
                    progressCallback(1, 1)
                }
            }
            
            delegate?.didCaptureImage(image)
            progressCallback(1, 1)
        } else {
            print("HYEYE: 截图失败")
            progressCallback(0, 0)
        }
    }
    
    // MARK: - Private Methods
    private func saveToFile(image: UIImage, path: String, quality: Float) {
        let fileManager = FileManager.default
        
        // 确保目录存在
        try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        
        // 生成文件名
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let fileName = "\(path)/IMG_\(timestamp).jpg"
        
        // 保存文件
        if let data = image.jpegData(compressionQuality: CGFloat(quality)) {
            do {
                try data.write(to: URL(fileURLWithPath: fileName))
                print("HYEYE: 照片保存到文件: \(fileName)")
            } catch {
                print("HYEYE: 照片保存到文件失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveToPhotoLibrary(image: UIImage, quality: Float) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            if success {
                print("HYEYE: 照片保存到相册成功")
            } else {
                print("HYEYE: 照片保存到相册失败: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    // MARK: - Video Recording
    public func startRecording(fileName: String? = nil) -> String? {
        guard let player = player, !isRecording else {
            print("HYEYE: 录制失败 - 播放器未就绪或已在录制中")
            return nil
        }
        
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            print("HYEYE: 获取 Documents 目录失败")
            return nil
        }
        
        let videoDirectory = (documentsPath as NSString).appendingPathComponent("Videos")
        try? FileManager.default.createDirectory(atPath: videoDirectory, withIntermediateDirectories: true)
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let videoFileName = fileName ?? "VID_\(timestamp).mp4"
        let videoPath = (videoDirectory as NSString).appendingPathComponent(videoFileName)
        
        player.startRecordVideo(atPath: videoDirectory, withFileName: videoFileName, width: 0, height: 0)
        
        isRecording = true
        currentRecordingPath = videoPath
        delegate?.recordingStateDidChange(isRecording: true, path: videoPath)
        
        return videoPath
    }
    
    public func stopRecording() {
        guard let player = player, isRecording else { return }
        
        player.stopRecordVideo()
        isRecording = false
        let path = currentRecordingPath
        currentRecordingPath = nil
        delegate?.recordingStateDidChange(isRecording: false, path: path)
    }
    
    public var isVideoRecording: Bool {
        return isRecording
    }
    
    public var currentVideoPath: String? {
        return currentRecordingPath
    }
}

// MARK: - IJKFFMoviePlayerDelegate
extension HYEYE: IJKFFMoviePlayerDelegate {
    public func player(_ player: IJKFFMoviePlayerController, didReceiveRtcpSrData data: Data) {
        print("HYEYE: 收到 RTCP SR 数据，长度: \(data.count)")
    }
    
    public func player(_ player: IJKFFMoviePlayerController, didReceive data: Data) {
        print("HYEYE: 收到数据包，长度: \(data.count)")
    }
    
    public func playerDidTakePicture(_ player: IJKFFMoviePlayerController, resultCode: Int32, fileName: String) {
        if resultCode == 0, let image = UIImage(contentsOfFile: fileName) {
            delegate?.didCaptureImage(image)
        }
    }
    
    public func player(onNotifyDeviceConnected player: IJKFFMoviePlayerController) {
        print("HYEYE: 设备已连接")
    }
    
    public func playerDidRecordVideo(_ player: IJKFFMoviePlayerController, resultCode: Int32, fileName: String) {
        isRecording = false
        currentRecordingPath = nil
        delegate?.recordingStateDidChange(isRecording: false, path: fileName)
    }
}

// MARK: - Notification Handling
extension HYEYE {
    private func registNotice() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(mediaIsPreparedToPlayDidChange(_:)),
                                             name: .IJKMPMediaPlaybackIsPreparedToPlayDidChange,
                                             object: nil)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(moviePlayBackStateDidChange(_:)),
                                             name: .IJKMPMoviePlayerPlaybackStateDidChange,
                                             object: nil)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(moviePlayerFirstVideoFrameRendered(_:)),
                                             name: .IJKMPMoviePlayerFirstVideoFrameRendered,
                                             object: nil)
        
        // 添加应用生命周期通知
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(applicationWillResignActive(_:)),
                                             name: UIApplication.willResignActiveNotification,
                                             object: nil)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(applicationDidBecomeActive(_:)),
                                             name: UIApplication.didBecomeActiveNotification,
                                             object: nil)
    }
    
    @objc private func mediaIsPreparedToPlayDidChange(_ notification: Notification) {
        guard let player = notification.object as? IJKFFMoviePlayerController else { return }
        
        if player.isPreparedToPlay {
            print("HYEYE: Player prepared successfully")
            prepareRetryCount = 0  // 重置重试计数
            delegate?.playbackDidPrepared()
        } else {
            print("HYEYE Error: Player preparation failed")
            handlePrepareError()
        }
    }
    
    private func handlePrepareError() {
        prepareRetryCount += 1
        print("HYEYE: Prepare retry count: \(prepareRetryCount)")
        
        if prepareRetryCount < maxPrepareRetryCount {
            // 延迟重试
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                print("HYEYE: Retrying prepare...")
                self?.prepareToPlay()
            }
        } else {
            print("HYEYE Error: Max prepare retry count reached")
            handlePlaybackError(.playbackFailed)
        }
    }
    
    @objc private func moviePlayBackStateDidChange(_ notification: Notification) {
        guard let player = notification.object as? IJKFFMoviePlayerController else { return }
        
        print("HYEYE: Playback state changed to: \(player.playbackState.rawValue)")
        
        // 处理播放状态变化
        switch player.playbackState {
        case .paused:
            self.delegate?.playbackStateDidChange(.paused)
        case .stopped:
            self.delegate?.playbackStateDidChange(.stopped)
        case .interrupted:
            print("HYEYE Error: Playback interrupted")
            handlePlaybackError(.playbackFailed)
        default:
            break
        }
        
        delegate?.playbackStateDidChange(player.playbackState)
    }
    
    @objc private func moviePlayerFirstVideoFrameRendered(_ notification: Notification) {
        delegate?.playbackFirstFrameRendered()
    }
    
    @objc private func applicationWillResignActive(_ notification: Notification) {
        // 确保进入后台时不暂停播放
        player?.setPauseInBackground(false)
    }
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        // 如果需要，可以在这里添加恢复播放的逻辑
        if let player = player, !player.isPlaying() {
            player.play()
        }
    }
}

//MARK: - Protocol Implementation
extension HYEYE: HYEYEProtocol {
    public enum PlaybackError {
        case connectionFailed
        case playbackFailed
        case unknown
        
        public var description: String {
            switch self {
            case .connectionFailed:
                return "无法连接到RTSP流，请检查：\n1. 设备是否在线\n2. 网络连接是否正常\n3. RTSP地址是否正确"
            case .playbackFailed:
                return "播放过程中发生错误，请尝试重新连接"
            case .unknown:
                return "未知错误"
            }
        }
    }
    
    private func handlePlaybackError(_ error: PlaybackError) {
        print("播放错误: \(error.description)")
        delegate?.playbackDidFinishWithError(error)
    }
}

// MARK: - PhotoSaver
private class PhotoSaver: NSObject {
    private let saveQueue = DispatchQueue(label: "com.hyeye.photosaver", qos: .userInitiated)
    
    func savePhoto(_ image: UIImage, quality: Float, completion: @escaping (Bool, Error?) -> Void) {
        saveQueue.async {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }
    }
}

// MARK: - Image Processing
extension HYEYE {
    private func createImage(from frameData: Data, width: Int, height: Int, pixelFormat: UInt32) -> UIImage? {
        print("HYEYE: 开始转换图像 - 格式: \(pixelFormat)")
        
        switch pixelFormat {
        case kCVPixelFormatType_32BGRA:
            return createBGRAImage(from: frameData, width: width, height: height)
        case kCVPixelFormatType_420YpCbCr8Planar: // YUV420P
            return createYUVImage(from: frameData, width: width, height: height)
        default:
            print("HYEYE: 不支持的像素格式: \(pixelFormat)")
            return nil
        }
    }
    
    private func createBGRAImage(from frameData: Data, width: Int, height: Int) -> UIImage? {
        guard let provider = CGDataProvider(data: frameData as CFData) else { return nil }
        
        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func createYUVImage(from frameData: Data, width: Int, height: Int) -> UIImage? {
        let ySize = width * height
        let uvSize = (width * height) / 4
        
        guard frameData.count >= ySize + (uvSize * 2) else {
            print("HYEYE: YUV 数据大小不正确")
            return nil
        }
        
        // 创建 CVPixelBuffer
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferMetalCompatibilityKey: true
        ] as CFDictionary
        
        CVPixelBufferCreate(kCFAllocatorDefault,
                           width,
                           height,
                           kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                           attrs,
                           &pixelBuffer)
        
        guard let buffer = pixelBuffer else {
            print("HYEYE: 创建 PixelBuffer 失败")
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        // 复制 Y 平面数据
        let yData = frameData.subdata(in: 0..<ySize)
        let yAddress = CVPixelBufferGetBaseAddressOfPlane(buffer, 0)
        yData.copyBytes(to: yAddress!.assumingMemoryBound(to: UInt8.self), count: ySize)
        
        // 复制 UV 平面数据
        let uvData = frameData.subdata(in: ySize..<(ySize + uvSize * 2))
        let uvAddress = CVPixelBufferGetBaseAddressOfPlane(buffer, 1)
        uvData.copyBytes(to: uvAddress!.assumingMemoryBound(to: UInt8.self), count: uvSize * 2)
        
        // 创建 CIImage
        let ciImage = CIImage(cvPixelBuffer: buffer)
        
        // 转换为 UIImage
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("HYEYE: 创建 CGImage 失败")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
