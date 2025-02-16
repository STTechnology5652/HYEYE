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

public protocol HYEYEProtocol {
    static func openVideo(url: URL) -> IJKFFMoviePlayerController?
}

public protocol HYEYEDelegate: AnyObject {
    func playbackStateDidChange(_ state: IJKMPMoviePlaybackState)
    func playbackDidFinishWithError(_ error: HYEYE.PlaybackError)
    func playbackDidPrepared()
}

public class HYEYE {
    private var disposeBag: DisposeBag = DisposeBag()
    private var player: IJKFFMoviePlayerController?
    
    public static let sharedInstance = HYEYE().registNotice()
    
    public weak var delegate: HYEYEDelegate?
    
    /*
     /* Register observers for the various movie object notifications. */
     -(void)installMovieNotificationObservers
     {
         NSLog(@"installMovieNotificationObservers");

         [[NSNotificationCenter defaultCenter] addObserver:self
                                                  selector:@selector(loadStateDidChange:)
                                                      name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                    object:_player];
         
         [[NSNotificationCenter defaultCenter] addObserver:self
                                                  selector:@selector(moviePlayBackDidFinish:)
                                                      name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                    object:_player];
         
         [[NSNotificationCenter defaultCenter] addObserver:self
                                                  selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                      name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                    object:_player];
         
         [[NSNotificationCenter defaultCenter] addObserver:self
                                                  selector:@selector(moviePlayBackStateDidChange:)
                                                      name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                    object:_player];
         
         [[NSNotificationCenter defaultCenter] addObserver:self
                                                  selector:@selector(moviePlayerDidShutdown:)
                                                      name:IJKMPMoviePlayerDidShutdownNotification
                                                    object:_player];
         
         [[NSNotificationCenter defaultCenter] addObserver:self
                                                  selector:@selector(moviePlayerFirstVideoFrameDidRender:)
                                                      name:IJKMPMoviePlayerFirstVideoFrameRenderedNotification
                                                    object:_player];
     }
     */
    
    private func registNotice() -> Self {
        let notiCenter = NotificationCenter.default
        
        // Load state change notification
        notiCenter.rx.notification(.IJKMPMoviePlayerLoadStateDidChange)
            .subscribe { [weak self] notification in
                self?.loadStateDidChange(notification)
            }
            .disposed(by: disposeBag)
        
        // Playback finish notification
        notiCenter.rx.notification(.IJKMPMoviePlayerPlaybackDidFinish)
            .subscribe { [weak self] notification in
                self?.moviePlayBackDidFinish(notification)
            }
            .disposed(by: disposeBag)
        
        // Media prepared to play notification
        notiCenter.rx.notification(.IJKMPMediaPlaybackIsPreparedToPlayDidChange)
            .subscribe { [weak self] notification in
                self?.mediaIsPreparedToPlayDidChange(notification)
            }
            .disposed(by: disposeBag)
        
        // Playback state change notification
        notiCenter.rx.notification(.IJKMPMoviePlayerPlaybackStateDidChange)
            .subscribe { [weak self] notification in
                self?.moviePlayBackStateDidChange(notification)
            }
            .disposed(by: disposeBag)
        
        // Player shutdown notification
        notiCenter.rx.notification(.IJKMPMoviePlayerDidShutdown)
            .subscribe { [weak self] notification in
                self?.moviePlayerDidShutdown(notification)
            }
            .disposed(by: disposeBag)
        
        // First video frame rendered notification
        notiCenter.rx.notification(.IJKMPMoviePlayerFirstVideoFrameRendered)
            .subscribe { [weak self] notification in
                self?.moviePlayerFirstVideoFrameDidRender(notification)
            }
            .disposed(by: disposeBag)
        
        return self
    }
    
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
}

//MARK: - IJKFFMoviePlayer notification
private extension HYEYE {
    // 通知处理方法
    func loadStateDidChange(_ notification: Notification) {
        guard let player = notification.object as? IJKFFMoviePlayerController else { return }
        
        let loadState: IJKMPMovieLoadState = player.loadState
        print("Load state changed: \(loadState.rawValue)")
        
        if (loadState.rawValue & IJKMPMovieLoadState.playable.rawValue) != 0 {
            print("视频加载完成，可以播放")
            // 可以尝试立即开始播放
            player.play()
        }
        
        if (loadState.rawValue & IJKMPMovieLoadState.playthroughOK.rawValue) != 0 {
            print("视频缓冲充足")
        }
        
        if (loadState.rawValue & IJKMPMovieLoadState.stalled.rawValue) != 0 {
            print("视频加载停滞，正在缓冲")
            // 可以显示loading提示
        }
        
        // 检查错误状态
        if loadState.rawValue == 0 {
            print("加载状态异常，可能是连接失败")
        }
    }
    
    func moviePlayBackDidFinish(_ notification: Notification) {
        guard let player = notification.object as? IJKFFMoviePlayerController,
              let userInfo = notification.userInfo,
              let finishReason = userInfo[IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] as? Int else {
            print("播放结束通知解析失败")
            return
        }
        
        print("notification: \(notification)")
        switch finishReason {
        case IJKMPMovieFinishReason.playbackEnded.rawValue:
            print("播放完成")
            cleanupPlayer()
        case IJKMPMovieFinishReason.playbackError.rawValue:
            let errorCode = player.currentPlaybackTime // 使用播放时间来判断是否是连接错误
            if errorCode == 0 {
                print("RTSP连接失败，错误码: \(finishReason)")
                handlePlaybackError(.connectionFailed)
            } else {
                print("播放过程中发生错误，错误码: \(finishReason)")
                handlePlaybackError(.playbackFailed)
            }
            cleanupPlayer()
        case IJKMPMovieFinishReason.userExited.rawValue:
            print("用户退出播放")
            cleanupPlayer()
        default:
            print("未知的播放结束原因: \(finishReason)")
            cleanupPlayer()
        }
    }
    
    private func handlePlaybackError(_ error: PlaybackError) {
        print("播放错误: \(error.description)")
        delegate?.playbackDidFinishWithError(error)
    }
    
    private func cleanupPlayer() {
        player?.shutdown()
        player = nil
        disposeBag = DisposeBag()
    }
    
    func mediaIsPreparedToPlayDidChange(_ notification: Notification) {
        guard let player = notification.object as? IJKFFMoviePlayerController else { return }
        if player.isPreparedToPlay {
            print("视频准备就绪，可以开始播放")
            delegate?.playbackDidPrepared()
        }
    }
    
    func moviePlayBackStateDidChange(_ notification: Notification) {
        guard let player = notification.object as? IJKFFMoviePlayerController else { return }
        
        switch player.playbackState {
        case .stopped:
            print("播放停止")
            delegate?.playbackStateDidChange(.stopped)
        case .playing:
            print("正在播放")
            delegate?.playbackStateDidChange(.playing)
        case .paused:
            print("播放暂停")
            delegate?.playbackStateDidChange(.paused)
        default:
            break
        }
    }
    
    func moviePlayerDidShutdown(_ notification: Notification) {
        print("播放器已关闭")
        cleanupPlayer()
    }
    
    func moviePlayerFirstVideoFrameDidRender(_ notification: Notification) {
        print("首帧视频已渲染")
    }
}

//MARK: - Protocol Implementation
extension HYEYE: HYEYEProtocol {
    public static func openVideo(url: URL) -> IJKFFMoviePlayerController? {
        return HYEYE.sharedInstance.openVideo(url: url)
    }
    
    private func openVideo(url: URL) -> IJKFFMoviePlayerController? {
        let options = IJKFFOptions.byDefault()
        
        // 播放器基础选项
        options?.setPlayerOptionIntValue(Int64(RtpJpegParsePacketMethodDrop.rawValue), forKey: "rtp-jpeg-parse-packet-method")
        options?.setPlayerOptionIntValue(0, forKey: "videotoolbox")
        options?.setPlayerOptionIntValue(5000 * 1000, forKey: "readtimeout")
        
        // 图像相关配置
        options?.setPlayerOptionIntValue(Int64(PreferredImageTypeJPEG.rawValue), forKey: "preferred-image-type")
        options?.setPlayerOptionIntValue(1, forKey: "image-quality-min")
        options?.setPlayerOptionIntValue(1, forKey: "image-quality-max")
        
        // 视频相关配置
        options?.setPlayerOptionIntValue(Int64(PreferredVideoTypeH264.rawValue), forKey: "preferred-video-type")
        options?.setPlayerOptionIntValue(1, forKey: "video-need-transcoding")
        options?.setPlayerOptionIntValue(Int64(MjpegPixFmtYUVJ420P.rawValue), forKey: "mjpeg-pix-fmt")
        
        // 视频质量设置
        options?.setPlayerOptionIntValue(2, forKey: "video-quality-min")
        options?.setPlayerOptionIntValue(20, forKey: "video-quality-max")
        
        // H264编码配置
        options?.setPlayerOptionIntValue(Int64(X264OptionPresetUltrafast.rawValue), forKey: "x264-option-preset")
        options?.setPlayerOptionIntValue(Int64(X264OptionTuneZerolatency.rawValue), forKey: "x264-option-tune")
        options?.setPlayerOptionIntValue(Int64(X264OptionProfileMain.rawValue), forKey: "x264-option-profile")
        options?.setPlayerOptionValue("crf=23", forKey: "x264-params")
        
        // 自动丢帧和错误处理
        options?.setPlayerOptionIntValue(3, forKey: "auto-drop-record-frame")
        options?.setCodecOptionValue("explode", forKey: "err_detect")
        
        // 创建播放器
        let player = IJKFFMoviePlayerController(contentURL: url, with: options)
        player?.shouldAutoplay = true
        player?.scalingMode = .aspectFit
        player?.shouldShowHudView = true
        
        #if DEBUG
        IJKFFMoviePlayerController.setLogReport(true)
        IJKFFMoviePlayerController.setLogLevel(k_IJK_LOG_INFO)
        #else
        IJKFFMoviePlayerController.setLogReport(false)
        IJKFFMoviePlayerController.setLogLevel(k_IJK_LOG_SILENT)
        #endif
        
        return player
    }
}
