//
//  HYEYE.swift
//  Pod
//
//  Created by stephenchen on 2025/01/27.
//

@_exported import IJKMediaFramework
import IJKMediaFramework.IJKFFOptions
import RxCocoa
import RxSwift
import Photos
import AVFoundation

public protocol HYEYEProtocol {
    static func openVideo(url: URL) -> IJKFFMoviePlayerController?
}

public protocol HYEYEDelegate: AnyObject {
    func playbackStateDidChange(_ state: IJKMPMoviePlaybackState)
    func playbackDidFinishWithError(_ error: HYEYE.PlaybackError)
    func playbackDidPrepared()
}

public class HYEYE: NSObject {
    // MARK: - Properties
    public static let sharedInstance = HYEYE()
    
    // Rx Signals
    public let playbackState = PublishRelay<IJKMPMoviePlaybackState>()
    public let playbackError = PublishRelay<PlaybackError>()
    public let firstFrameRendered = PublishRelay<Void>()
    public let isPreparedToPlay = PublishRelay<Bool>()
    public let capturedImage = PublishRelay<UIImage>()
    public let captureProgress = PublishRelay<(current: Int, total: Int)>()
    
    private var disposeBag = DisposeBag()
    private var player: IJKFFMoviePlayerController?
    
    public weak var delegate: HYEYEDelegate?
    
    // 进度相关属性
    private var lastProgressUpdate: TimeInterval = 0
    private let progressUpdateInterval: TimeInterval = 0.1
    
    // MARK: - Public Methods
    public static func openVideo(url: URL) -> IJKFFMoviePlayerController? {
        return HYEYE.sharedInstance.openVideo(url: url)
    }
    
    override init() {
        super.init()
        setupAudioSession()
        registNotice()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("HYEYE: 设置音频会话失败: \(error.localizedDescription)")
        }
    }
    
    private func openVideo(url: URL) -> IJKFFMoviePlayerController? {
        let options = IJKFFOptions.byDefault()
        
        // 基础配置
        options?.setPlayerOptionIntValue(Int64(RtpJpegParsePacketMethodDrop.rawValue), forKey: "rtp-jpeg-parse-packet-method")
        options?.setPlayerOptionIntValue(5000 * 1000, forKey: "readtimeout")
        
        // 添加后台播放配置
        options?.setPlayerOptionIntValue(1, forKey: "pause-in-background") // 0 表示不暂停
        options?.setPlayerOptionIntValue(1, forKey: "enable-background-play") // 启用后台播放
        
        // 创建播放器
        let player = IJKFFMoviePlayerController(contentURL: url, with: options)
        player?.shouldAutoplay = true
        player?.scalingMode = .aspectFit
        player?.shouldShowHudView = false
        player?.delegate = self
        
        // 设置后台播放
        player?.setPauseInBackground(false)
        
        self.player = player
        return player
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
            captureProgress.accept((count, total))
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
        
        // 使用 thumbnailImageAtCurrentTime 方法进行截图
        if let image = player.thumbnailImageAtCurrentTime() {
            // 保存图片
            if let savePath = config.savePath {
                saveToFile(image: image, path: savePath, quality: config.imageQuality)
            } else {
                PHPhotoLibrary.requestAuthorization { [weak self] status in
                    guard let self = self else { return }
                    
                    if status == .authorized {
                        self.saveToPhotoLibrary(image: image, quality: config.imageQuality)
                    }
                    progressCallback(1, 1)
                }
            }
            
            // 发送截图结果
            capturedImage.accept(image)
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
        print("HYEYE: 拍照完成 - 文件名: \(fileName), 结果码: \(resultCode)")
        
        if resultCode == 0 {
            if let image = UIImage(contentsOfFile: fileName) {
                capturedImage.accept(image)
            }
        } else {
            print("HYEYE: 截图失败，错误码: \(resultCode)")
        }
    }
    
    public func player(onNotifyDeviceConnected player: IJKFFMoviePlayerController) {
        print("HYEYE: 设备已连接")
    }
}

// MARK: - Notification Handling
extension HYEYE {
    private func registNotice() -> Self {
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
        
        return self
    }
    
    @objc private func mediaIsPreparedToPlayDidChange(_ notification: Notification) {
        guard let player = notification.object as? IJKFFMoviePlayerController else { return }
        if player.isPreparedToPlay {
            isPreparedToPlay.accept(true)
            delegate?.playbackDidPrepared()
        }
    }
    
    @objc private func moviePlayBackStateDidChange(_ notification: Notification) {
        guard let player = notification.object as? IJKFFMoviePlayerController else { return }
        playbackState.accept(player.playbackState)
    }
    
    @objc private func moviePlayerFirstVideoFrameRendered(_ notification: Notification) {
        firstFrameRendered.accept(())
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
        playbackError.accept(error)
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
