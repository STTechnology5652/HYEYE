//
//  HYPlayer.swift
//  HYEYE
//
//  Created by stephen Li on 2025/2/26.
//

import Foundation

import IJKMediaFramework.IJKFFOptions
import Photos
import AVFoundation
import RxSwift
import RxRelay
import RxCocoa
import SnapKit

private class HYPlayerContainerView: UIView {
    private var disPoseBag: DisposeBag = DisposeBag()
    struct OutPut {
        let playerViewInitSuccess: BehaviorRelay<Void> = BehaviorRelay(value: ())
    }
    
    var outPut: OutPut = OutPut()
    
    private var initPlayerSuccess: Bool = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if initPlayerSuccess == false {
            initPlayerSuccess = true
            outPut.playerViewInitSuccess.accept(())
        }
    }
}

extension HYPlayer {
    func play() {
        guard let player else { return }
        guard player.isPlaying() == false else {
            print ("(player is playing)")
            return
        }
        
        // 处理组合状态
        if player.loadState.contains(.playthroughOK) {
            print("player load state contains: playthrough OK")
            player.play()
        } else if player.loadState.contains(.stalled) {
            print("player load state contains: stalled")
            player.play()
        } else if player.loadState.contains(.playable) {
            print("player load state contains: playable")
            player.play()
        } else {
            print("player load state contains: unknown")
            output.playerStateTtacer.accept(.loading)
            prepareRetryCount = 0
            prepareError()
        }
    }
    
    func stop() {
        guard let player else {
            return
        }
        
        switch player.playbackState {
        case .paused:
            print("player is paused")
        case .stopped:
            print("player is stopped")
        case .playing:
            player.pause()
        case .interrupted:
            print("player is interupted")
        case .seekingForward:
            break
        case .seekingBackward:
            break
        }
    }
    
    func shutdown() {
        guard let player else {
            return
        }
        
        player.shutdown()
    }
    
    func takePhoto() -> UIImage? {
        return player?.thumbnailImageAtCurrentTime()
    }
    
    func isRecordingVodeo() -> Bool {
        guard let player else {
            return false
        }
        return player.videoRecordingStatus == VideoRecordingStatusRecording
    }
    
    func stopRecordVideo() {
        guard let player else {
            return
        }
        
        player.stopRecordVideo()
    }
    
    func recordVideo() -> Bool {
        guard let player else {
            return false
        }
        
        if player.isPlaying() == false {
            return false
        }
        
        // 获取 Documents 目录
        let fm = FileManager.default
        
        // 创建日期格式化器
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd-HH_mm_ss"
        let fileName = df.string(from: Date())
        // 创建录制视频存储目录
        if !fm.fileExists(atPath: Self.videoStorePath.path) {
            do {
                print("start create dir \(Self.videoStorePath.path)")
                try fm.createDirectory(at: Self.videoStorePath, withIntermediateDirectories: true)
            } catch {
                print("create dir error: \(error)")
                return false
            }
        }
        
        // 完整的文件路径
        let filePath = Self.videoStorePath.appendingPathComponent(fileName)
        
        print("start record video to \(filePath.path)")
        player.startRecordVideo(atPath: Self.videoStorePath.path, withFileName: fileName, width: 1080, height: 1920)
        return true
    }
    
    static func allRecordedVideos() -> [URL] {
        do {
            return try FileManager.default.contentsOfDirectory(at: Self.videoStorePath, includingPropertiesForKeys: nil, options: [])
        } catch {
            return []
        }
    }
    
    public func showDebugView(show: Bool) {
        player?.shouldShowHudView = show
    }
}

class HYPlayer: NSObject {
    struct Output {
        let playerStateTtacer: BehaviorRelay<HYEyePlayerState> = BehaviorRelay(value: .loading)
        let firstFrameRendered: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
        let recordVideoFinishTracker: BehaviorRelay<URL?> = BehaviorRelay<(URL?)>(value: nil)
    }
    
    static func == (lhs: HYPlayer, rhs: HYPlayer) -> Bool {
        lhs.url == rhs.url
    }
    
    let output: Output = Output()
    
    private var disPoseBag: DisposeBag = DisposeBag()
    
    private var player: IJKFFMoviePlayerController?
    private let url: URL
    
    private var playerContainerView: HYPlayerContainerView?
    private weak var displayView: UIView?
    
    private var prepareRetryCount = 0
    private let maxPrepareRetryCount = 5
    private static let videoStorePath: URL = FileManager.default.temporaryDirectory.appendingPathComponent("HYCam_VideoStore")
    
    deinit {
        print("HYPlayer deinit")
        playerContainerView
        guard let player else {
            return
        }
        
        disPoseBag = DisposeBag()
        player.shutdown()
        player.view.removeFromSuperview()
        playerContainerView?.removeFromSuperview()
        playerContainerView = nil
    }
    
    init(displayView: UIView, url: URL) {
        self.displayView = displayView
        self.url = url
        
        super.init()
        
        registNotification()
        createPlayer()
        bindData()
    }
    
    private func createPlayer() {
        print("HYEYE: opening video with url: \(url)")
        
        // 如果已有播放器实例，先关闭它
        if let existingPlayer = player {
            self.player = nil
            existingPlayer.shutdown()
            existingPlayer.view.removeFromSuperview()
            self.playerContainerView?.removeFromSuperview()
        }
        
        let playerBackView = HYPlayerContainerView()
        self.playerContainerView = playerBackView
        
        // 创建新的播放器实例
        let options = IJKFFOptions.byDefault()
        
        // RTSP 相关配置
        options?.setFormatOptionIntValue(10 * 1000000, forKey: "stimeout")
        options?.setFormatOptionIntValue(10 * 1000000, forKey: "timeout")
        options?.setFormatOptionIntValue(10 * 1000000, forKey: "initial_timeout")
        
        // RTSP 传输配置
        options?.setFormatOptionValue("udp", forKey: "rtsp_transport")
        options?.setFormatOptionIntValue(0, forKey: "rtsp_flags")
        options?.setFormatOptionIntValue(Int64(PreferredVideoTypeH264.rawValue), forKey: "video")

        // UDP 相关配置 - 允许丢包
        options?.setFormatOptionIntValue(32768, forKey: "buffer_size")
        options?.setFormatOptionIntValue(16, forKey: "reorder_queue_size")
        options?.setFormatOptionValue("prefer_tcp", forKey: "rtsp_flags")
        options?.setFormatOptionIntValue(1, forKey: "fflags")  // 允许丢弃损坏的包
        options?.setFormatOptionIntValue(1, forKey: "skip_frame")  // 允许跳过帧
        options?.setFormatOptionIntValue(1, forKey: "skip_loop_filter")  // 跳过循环过滤
        
        // 重连相关配置
        options?.setFormatOptionIntValue(1, forKey: "reconnect")
        options?.setFormatOptionIntValue(1, forKey: "reconnect_at_eof")
        options?.setFormatOptionIntValue(1, forKey: "reconnect_streamed")
        options?.setFormatOptionIntValue(2, forKey: "reconnect_delay_max")
        
        // 缓冲和性能相关配置
        options?.setPlayerOptionIntValue(1, forKey: "packet-buffering")
        options?.setPlayerOptionIntValue(5, forKey: "min-frames")
        options?.setPlayerOptionIntValue(3 * 1024 * 1024, forKey: "max-buffer-size")
        options?.setPlayerOptionIntValue(1, forKey: "framedrop")  // 允许丢帧
        options?.setPlayerOptionIntValue(1, forKey: "enable-accurate-seek")  // 允许精确查找
        options?.setPlayerOptionIntValue(0, forKey: "sync-av-start")  // 不等待音视频同步
        
        // 其他优化配置
        options?.setPlayerOptionIntValue(15, forKey: "max-fps")
        options?.setFormatOptionIntValue(500000, forKey: "analyzeduration")
        options?.setFormatOptionIntValue(32, forKey: "probesize")
        options?.setPlayerOptionIntValue(1, forKey: "fast")  // 快速解码模式
        
        // MJPEG 相关配置
        options?.setPlayerOptionIntValue(1, forKey: "rtp-jpeg-parse-packet-method")
        options?.setPlayerOptionIntValue(0, forKey: "videotoolbox")
        
        // 性能优化
        options?.setPlayerOptionIntValue(1, forKey: "framedrop")
        options?.setPlayerOptionIntValue(1, forKey: "start-on-prepared")
        options?.setPlayerOptionIntValue(0, forKey: "sync-av-start")
        options?.setPlayerOptionIntValue(1, forKey: "mediacodec")
        
        // 使用 FFmpeg 滤镜处理视频方向 -- 此处可以调整组有颠倒的问题， 但是显示HUB后发现，是设备内原是视频流的问题，不应该在解码层解决
//        options?.setOptionValue("hflip,vflip", forKey: "vf", of: kIJKFFOptionCategoryPlayer)
        
        // 设置 RTSP 参数
        options?.setFormatOptionValue("nobuffer", forKey: "fflags")
        options?.setFormatOptionValue("1", forKey: "correct_ts_overflow")
        
        // 创建新的播放器
        let newPlayer = IJKFFMoviePlayerController(contentURL: url, with: options)
        newPlayer?.shouldAutoplay = false
        newPlayer?.scalingMode = .aspectFit
        newPlayer?.shouldShowHudView = false
        
        // 设置后台播放
        newPlayer?.setPauseInBackground(false)
        IJKFFMoviePlayerController.setLogLevel(k_IJK_LOG_INFO)  // 改为 INFO 级别，减少日志输出
        
        self.player = newPlayer
        newPlayer?.delegate = self
    }
    
    private func bindData() {
        guard let player else {
            
            return
        }
        
        guard let displayView else {
            
            return
        }
        
        guard let playerView = player.view else {
            
            return
        }
        
        let playBackView = HYPlayerContainerView()
        self.playerContainerView = playBackView
        
        self.disPoseBag = DisposeBag()
        
        registNotification()
        playerContainerView?.outPut.playerViewInitSuccess
            .skip(1)
            .subscribe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.playerViewLayoutSuccess()
            })
            .disposed(by: disPoseBag)
        
        playBackView.addSubview(playerView)
        displayView.addSubview(playBackView)
        
        playBackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 添加视频变换
        playerView.transform = CGAffineTransform(scaleX: -1, y: 1)
    }
    
    private func registNotification() {
        let notiCenter = NotificationCenter.default
        
        // 播放器准备状态改变
        notiCenter.rx.notification(.IJKMPMediaPlaybackIsPreparedToPlayDidChange)
            .subscribe(onNext: { [weak self] notification in
                guard let player = notification.object as? IJKFFMoviePlayerController else { return }
                print("HYEYE: Prepare state changed, isPreparedToPlay: \(player.isPreparedToPlay)")
                
                if player.isPreparedToPlay {
                    print("HYEYE: Player prepared to play success")
                    self?.output.playerStateTtacer.accept(.loaded)
                } else {
                    print("HYEYE: Player prepare failed")
                    self?.prepareError()
                }
            })
            .disposed(by: disPoseBag)
        
        // 播放完成状态监听
        notiCenter.rx.notification(.IJKMPMoviePlayerPlaybackDidFinish)
            .subscribe(onNext: { [weak self] notification in
                guard let reason = notification.userInfo?[IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] as? Int else { return }
                print("HYEYE: Playback finished with reason: \(reason)")
                
                // 检查是否是错误结束
                if reason == IJKMPMovieFinishReason.playbackError.rawValue {
                    print("HYEYE Error: Playback finished with error")
                    self?.prepareError()
                }
            })
            .disposed(by: disPoseBag)
        
        // 添加加载状态监听
        notiCenter.rx.notification(.IJKMPMoviePlayerLoadStateDidChange)
            .subscribe(onNext: { [weak self] notification in
                guard let player = notification.object as? IJKFFMoviePlayerController else { return }
                print("HYEYE: Load state changed: \(player.loadState.rawValue)")
                
                if player.loadState == .stalled {
                    print("HYEYE: Player stalled")
                    self?.prepareError()
                } else if player.loadState.contains(.playthroughOK) {
                    print("HYEYE: Player ready for playthrough")
                    self?.prepareRetryCount = 0
                    player.play()
                }
            })
            .disposed(by: disPoseBag)
        
        // 播放状态改变
        notiCenter.rx.notification(.IJKMPMoviePlayerPlaybackStateDidChange)
            .subscribe(onNext: { [weak self] notification in
                guard let self, let player = notification.object as? IJKFFMoviePlayerController else { return }
                print("HYEYE: Playback state changed to: \(player.playbackState.rawValue)")
                if player.loadState.rawValue == 0 {
                    print("HYEYE: Player is not loaded, skip state changing")
                    return
                }
                
                switch player.playbackState {
                case .playing:
                    print("HYEYE: Player is playing")
                    output.playerStateTtacer.accept(.playing)
                case .stopped:
                    print("HYEYE: Player stopped")
                    output.playerStateTtacer.accept(.stopped)
                case .paused:
                    print("HYEYE: Player paused")
                    output.playerStateTtacer.accept(.paused)
                case .interrupted:
                    print("HYEYE Error: Playback interrupted")
                    output.playerStateTtacer.accept(.shutdown)
                default:
                    break
                }
            })
            .disposed(by: disPoseBag)
        
        // 首帧渲染
        notiCenter.rx.notification(.IJKMPMoviePlayerFirstVideoFrameRendered)
            .subscribe(onNext: { [weak self] _ in
                print("HYEYE: First video frame rendered")
                guard let self else { return }
                output.firstFrameRendered.accept(true)
            })
            .disposed(by: disPoseBag)
        
        // 应用进入后台
        notiCenter.rx.notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                print("HYEYE: App entering background")
                self?.player?.pause()
            })
            .disposed(by: disPoseBag)
        
        // 应用进入前台
        notiCenter.rx.notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                print("HYEYE: App entering foreground")
                if let player = self?.player, player.isPreparedToPlay {
                    player.play()
                }
            })
            .disposed(by: disPoseBag)
    }
    
    private func playerViewLayoutSuccess() {
        // 只有页面展开的时候，才能去 prepareToPlay
        print(#function + " playerViewLayoutSuccess: \(player)")
        DispatchQueue.main.async { [weak self] in
            self?.player?.prepareToPlay()
        }
    }
    
    private func prepareError() {
        prepareRetryCount += 1
        print("HYEYE: Prepare retry count: \(prepareRetryCount)")
        if prepareRetryCount < maxPrepareRetryCount {
            output.playerStateTtacer.accept(.loading)
            // 延迟重试前先关闭当前播放器
            let oldPlayer = player
            player = nil
            
            print("HYEYE: Retrying prepare...")
            // 重新创建播放器
            self.createPlayer()
            self.bindData() // 重新绑定视图
            oldPlayer?.shutdown()
            // 等待视图布局完成后会自动调用 prepareToPlay
        } else {
            print("HYEYE Error: Max prepare retry count reached")
            output.playerStateTtacer.accept(.loadfailed)
        }
    }
}

//MARK: - IJKFFMoviePlayerDelegate methods
extension HYPlayer: IJKFFMoviePlayerDelegate {
    public func player(_ player: IJKFFMoviePlayerController, didReceiveRtcpSrData data: Data) {
        print(#function)
    }
    
    public func player(_ player: IJKFFMoviePlayerController, didReceive data: Data) {
        print(#function)
    }
    
    public func playerDidTakePicture(_ player: IJKFFMoviePlayerController, resultCode: Int32, fileName: String) {
        print(#function)
    }
    
    public func player(onNotifyDeviceConnected player: IJKFFMoviePlayerController) {
        print(#function)
    }
    
    public func playerDidRecordVideo(_ player: IJKFFMoviePlayerController, resultCode: Int32, fileName: String) {
        print(#function + " resultCode:\(resultCode) fileName:\(fileName)")
        output.recordVideoFinishTracker.accept(URL(string: fileName))
    }
    
    public func playerOnNotifyDeviceConnected(_ player: IJKFFMoviePlayerController) {
        print(#function)
    }
}
