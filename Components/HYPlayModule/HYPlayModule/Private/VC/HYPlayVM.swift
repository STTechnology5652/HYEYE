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
    
    // MARK: - Input & Output
    struct HYPlayVMInput {
        let openVideoUrl: Observable<String?>
        let closeVideo: Observable<Void>
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
        let player: Driver<IJKFFMoviePlayerController?>
    }
    
    // MARK: - Transform
    func transformInput(_ input: HYPlayVMInput) -> HYPlayVMOutput {
        let playStatusRelay = BehaviorRelay<String>(value: "")
        let errorRelay = PublishRelay<String>()
        let shouldPlayRelay = PublishRelay<Void>()
        let playingRelay = BehaviorRelay<Bool>(value: false)
        let playerRelay = PublishRelay<IJKFFMoviePlayerController?>()
        
        // 处理开始播放
        input.openVideoUrl
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] url in
                guard let url = URL(string: url) else { return }
                if let player = HYEYE.openVideo(url: url) {
                    playerRelay.accept(player)
                }
            })
            .disposed(by: disposeBag)
        
        // 处理停止播放
        input.closeVideo
            .subscribe(onNext: { [weak self] in
                self?.handleStopPlayback()
            })
            .disposed(by: disposeBag)
        
        // 监听播放状态
        HYEYE.sharedInstance.playbackState
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .playing:
                    self.stateRelay.accept(.playing)
                    playStatusRelay.accept("Playing".stLocalLized)
                    playingRelay.accept(true)
                case .stopped:
                    self.stateRelay.accept(.stopped)
                    playStatusRelay.accept("Stopped".stLocalLized)
                    playingRelay.accept(false)
                case .paused:
                    self.stateRelay.accept(.paused)
                    playStatusRelay.accept("Paused".stLocalLized)
                    playingRelay.accept(false)
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
        
        // 监听错误
        HYEYE.sharedInstance.playbackError
            .subscribe(onNext: { [weak self] error in
                guard let self = self else { return }
                errorRelay.accept(error.description)
                self.handlePlaybackError()
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
            player: playerRelay.asDriver(onErrorJustReturn: nil)
        )
    }
    
    // MARK: - Private Methods
    private func handleStartPlayback(url: String) {
        guard let url = URL(string: url) else { return }
        _ = HYEYE.openVideo(url: url)
    }
    
    private func handleStopPlayback() {
        HYEYE.sharedInstance.stop()
        HYEYE.sharedInstance.shutdown()
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

