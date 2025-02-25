//
//  HYPlayVM.swift
//  HYPlayModule
//
//  Created by stephen Li on 2025/2/9.
//

import HYAllBase

import HYEYE

class HYPlayVM: STViewModelProtocol {
    // MARK: - Properties
    var disposeBag = DisposeBag()
    
    // 状态相关
    private let stateRelay = BehaviorRelay<PlaybackState>(value: .idle)
    private let recordingState = BehaviorRelay<Bool>(value: false)
    private let recordingPathRelay = PublishRelay<String?>()
    
    // 重试相关
    private var retryCount: Int = 0
    private let maxRetryCount: Int = 3
    
    private let playStatusRelay = BehaviorRelay<String>(value: "")
    private let errorRelay = PublishRelay<String>()
    private let playingRelay = BehaviorRelay<Bool>(value: false)
    
    private let preparedToPlayRelay = PublishRelay<Void>()
    
    deinit {
        disposeBag = DisposeBag()
        HYEYE.sharedInstance.shutdown()
    }
    
    init() {
        // 设置 delegate
        HYEYE.sharedInstance.delegate = self
    }
    
    // MARK: - Input & Output
    struct HYPlayVMInput {
        let openVideoUrl: Observable<String?>
        let closeVideo: Observable<Void>
        let prepareToPlayTrigger: Observable<Void>
        let playTrigger: Observable<Void>
        let stopTrigger: Observable<Void>
        let photoTrigger: Observable<Void>
        let recordTrigger: Observable<Void>
    }
    
    struct HYPlayVMOutput {
        let videoPlaying: Driver<Bool>
        let playStatus: Driver<String>
        let error: Driver<String>
        let shouldPlay: Driver<Void>
        let isRecording: Driver<Bool>
        let recordingPath: Driver<String?>
        let playerCreated: Driver<IJKFFMoviePlayerController?>
    }
    
    // MARK: - Transform
    func transformInput(_ input: HYPlayVMInput) -> HYPlayVMOutput {
        print("transformInput")
        
        let shouldPlayRelay = PublishRelay<Void>()
        let playerRelay = PublishRelay<IJKFFMoviePlayerController?>()
        
        // 处理准备播放
        input.prepareToPlayTrigger
            .subscribe(onNext: {
                print("prepareToPlay execute")
                HYEYE.sharedInstance.prepareToPlay()
            })
            .disposed(by: disposeBag)
        
        // 监听准备完成状态
        preparedToPlayRelay
            .subscribe(onNext: {
                print("prepared to play, starting playback")
                HYEYE.sharedInstance.play()
            })
            .disposed(by: disposeBag)
        
        // 处理开始播放
        input.openVideoUrl
            .compactMap { urlStr -> URL? in
                guard let urlStr = urlStr,  // 首先确保 urlStr 不为空
                      let url = URL(string: urlStr) else {
                    print("HYEYE Error: Invalid URL string")
                    return nil
                }
                return url
            }
            .subscribe(onNext: { [weak self] url in
                print("openVideoUrl execute: \(url)")
                let eyeIns = HYEYE.sharedInstance
                if let player = eyeIns.openVideo(url: url) {  // url 已经确定不为空
                    playerRelay.accept(player)
                }
            })
            .disposed(by: disposeBag)
        
        input.stopTrigger
            .subscribe(onNext: { [weak self] in
                print("stopTrigger execute")
                HYEYE.sharedInstance.pause()
            })
            .disposed(by: disposeBag)
        
        input.playTrigger
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)  // 防止快速重复触发
            .subscribe(onNext: { [weak self] in
                print("start player")
                HYEYE.sharedInstance.play()
            })
            .disposed(by: disposeBag)
        
        // 处理停止播放
        input.closeVideo
            .subscribe(onNext: { [weak self] in
                self?.handleStopPlayback()
            })
            .disposed(by: disposeBag)
        
        // 处理录制触发
        input.recordTrigger
            .withLatestFrom(recordingState)
            .subscribe(onNext: { [weak self] isRecording in
                self?.handleRecordingTrigger(isRecording: isRecording)
            })
            .disposed(by: disposeBag)
        
        return HYPlayVMOutput(
            videoPlaying: playingRelay.asDriver(),
            playStatus: playStatusRelay.asDriver(),
            error: errorRelay.asDriver(onErrorJustReturn: ""),
            shouldPlay: shouldPlayRelay.asDriver(onErrorJustReturn: ()),
            isRecording: recordingState.asDriver(),
            recordingPath: recordingPathRelay.asDriver(onErrorJustReturn: nil),
            playerCreated: playerRelay.asDriver(onErrorJustReturn: nil)
        )
    }
    
    // MARK: - Private Methods
    private func handleStartPlayback(url: String) {
        guard let url = URL(string: url) else { return }
        _ = HYEYE.sharedInstance.openVideo(url: url)
    }
    
    private func handleStopPlayback() {
        HYEYE.sharedInstance.pause()
    }
    
    private func handleRecordingTrigger(isRecording: Bool) {
        if isRecording {
            HYEYE.sharedInstance.stopRecording()
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yy-MM-dd-HH-mm-ss"
            let fileName = dateFormatter.string(from: Date()) + ".mp4"
            HYEYE.sharedInstance.startRecording(fileName: fileName)
        }
    }
    
    private func handlePlaybackError() {
        retryCount += 1
        if retryCount < maxRetryCount {
            let delay = Double(retryCount) * 3.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                if let url = HYEYE.sharedInstance.currentPlaybackUrl()?.absoluteString {
                    self?.handleStartPlayback(url: url)
                }
            }
        }
    }
}

// MARK: - Supporting Types
enum PlaybackState: Equatable {
    case idle
    case preparing
    case playing
    case paused
    case stopped
    case error(String)
    
    static func == (lhs: PlaybackState, rhs: PlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.preparing, .preparing),
             (.playing, .playing),
             (.paused, .paused),
             (.stopped, .stopped):
            return true
        case let (.error(e1), .error(e2)):
            return e1 == e2
        default:
            return false
        }
    }
}

// 添加 delegate 实现
extension HYPlayVM: HYEYEDelegate {
    func playbackStateDidChange(_ state: IJKMPMoviePlaybackState) {
        print("HYEYE: Playback state changed to: \(state.rawValue)")
        
        switch state {
        case .playing:
            stateRelay.accept(.playing)
            playStatusRelay.accept("Playing".stLocalLized)
            playingRelay.accept(true)
            retryCount = 0  // 重置重试计数
        case .stopped:
            stateRelay.accept(.stopped)
            playStatusRelay.accept("Stopped".stLocalLized)
            playingRelay.accept(false)
        case .paused:
            stateRelay.accept(.paused)
            playStatusRelay.accept("Paused".stLocalLized)
            playingRelay.accept(false)
        case .interrupted:
            print("HYEYE Error: Playback interrupted")
            handlePlaybackError()
        default:
            break
        }
    }
    
    func playbackDidFinishWithError(_ error: HYEYE.PlaybackError) {
        print("HYEYE Error: Playback finished with error - \(error.description)")
        errorRelay.accept(error.description)
        handlePlaybackError()
    }
    
    func playbackDidPrepared() {
        print("HYEYE: Playback prepared, triggering play")
        HYEYE.sharedInstance.play()
    }
    
    func playbackFirstFrameRendered() {}
    func recordingStateDidChange(isRecording: Bool, path: String?) {}
    func didCaptureImage(_ image: UIImage) {}
    func captureProgressDidUpdate(current: Int, total: Int) {}
}

