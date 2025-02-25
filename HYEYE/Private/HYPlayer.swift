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

class HYPlayer: NSObject {
    struct Output {
        let loadFinish: BehaviorRelay<Bool> = BehaviorRelay(value: false)
        let playerStopped: BehaviorRelay<Void> = BehaviorRelay(value: ())
        let playerStarted: BehaviorRelay<Void> = BehaviorRelay(value: ())
        let playerPaused: BehaviorRelay<Void> = BehaviorRelay(value: ())
        let playerInterupted: BehaviorRelay<Void> = BehaviorRelay(value: ())
        let playerShutDownd: BehaviorRelay<Void> = BehaviorRelay(value: ())
        let firstFrameRendered: BehaviorRelay<Void> = BehaviorRelay(value: ())
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
    
    func play() {
        guard let player else {
            return
        }
        
        if player.isPreparedToPlay == false {
           print("player is prepareing")
            return
        }
        
        switch player.playbackState {
        case .paused:
            player.play()
        case .stopped:
            player.play()
        case .playing:
            print("player is playing")
        case .interrupted:
            print("player is interupted")
            player.shutdown()
            player.prepareToPlay()
        case .seekingForward:
            break
        case .seekingBackward:
            break
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
        
        // 添加后台播放配置
        options?.setPlayerOptionIntValue(1, forKey: "pause-in-background")
        
        // 创建新的播放器
        let newPlayer = IJKFFMoviePlayerController(contentURL: url, with: options)
        newPlayer?.shouldAutoplay = true
        newPlayer?.scalingMode = .aspectFit
        newPlayer?.shouldShowHudView = false
//        newPlayer?.delegate = self
        
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
        
        let disposeBag = DisposeBag()
        self.disPoseBag = disposeBag
        
        playerContainerView?.outPut.playerViewInitSuccess
            .skip(1)
            .subscribe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.playerViewLayoutSuccess()
            })
            .disposed(by: disPoseBag)
        
        playerView.backgroundColor = .cyan
        playBackView.addSubview(playerView)
        displayView.insertSubview(playBackView, at: 0)
        
        playBackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
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
                    self?.output.loadFinish.accept(true)
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
                    player.play()
                }
            })
            .disposed(by: disPoseBag)
        
        // 播放状态改变
        notiCenter.rx.notification(.IJKMPMoviePlayerPlaybackStateDidChange)
            .subscribe(onNext: { [weak self] notification in
                guard let self, let player = notification.object as? IJKFFMoviePlayerController else { return }
                print("HYEYE: Playback state changed to: \(player.playbackState.rawValue)")
                
                switch player.playbackState {
                case .playing:
                    print("HYEYE: Player is playing")
                    output.playerStarted.accept(())
                case .stopped:
                    print("HYEYE: Player stopped")
                    output.playerStopped.accept(())
                case .paused:
                    print("HYEYE: Player paused")
                    output.playerPaused.accept(())
                case .interrupted:
                    print("HYEYE Error: Playback interrupted")
                    output.playerInterupted.accept(())
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
                output.firstFrameRendered.accept(())
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.player?.prepareToPlay()
        }
    }
    
    private func prepareError() {
        prepareRetryCount += 1
        print("HYEYE: Prepare retry count: \(prepareRetryCount)")
        
        if prepareRetryCount < maxPrepareRetryCount {
            // 延迟重试前先关闭当前播放器
            player?.shutdown()
            player = nil
            
            print("HYEYE: Retrying prepare...")
            // 重新创建播放器
            self.createPlayer()
            self.bindData() // 重新绑定视图
            // 等待视图布局完成后会自动调用 prepareToPlay
        } else {
            print("HYEYE Error: Max prepare retry count reached")
            output.loadFinish.accept(false)
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
        print(#function)
    }
}
