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
    let openVideoTrigger = PublishRelay<Void>()
    let playTrigger = PublishRelay<Void>()
    let stopTrigger = PublishRelay<Void>()
    private var retryCount: Int = 0
    private let maxRetryCount: Int = 3
    
    // MARK: - Input & Output
    struct Input {
        let openVideoTrigger: PublishRelay<Void>
        let playTrigger: PublishRelay<Void>
        let stopTrigger: PublishRelay<Void>
    }
    
    struct Output {
        let videoPlaying: Driver<Bool>
        let playStatus: Driver<String>
        let error: Driver<String>
        let shouldPlay: Driver<Void>  // 用于通知 VC 开始播放
    }
    
    // MARK: - Transform
    func transformInput(_ input: Input) -> Output {
        let playStatusRelay = BehaviorRelay<String>(value: "")
        let errorRelay = PublishRelay<String>()
        let shouldPlayRelay = PublishRelay<Void>()
        let playingRelay = BehaviorRelay<Bool>(value: false)
        
        // 监听播放状态
        HYEYE.sharedInstance.playbackState
            .subscribe(onNext: { state in
                switch state {
                case .playing:
                    playStatusRelay.accept("Playing".stLocalLized)
                    playingRelay.accept(true)
                case .stopped, .paused:
                    playStatusRelay.accept(state == .stopped ? "Stopped".stLocalLized : "Paused".stLocalLized)
                    playingRelay.accept(false)
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
        
        // 监听停止事件
        input.stopTrigger
            .do(onNext: { _ in
                playingRelay.accept(false)
                playStatusRelay.accept("Stopped".stLocalLized)
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        // 监听播放事件
        input.playTrigger
            .do(onNext: { _ in
                playStatusRelay.accept("Preparing".stLocalLized)
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        // 监听准备完成
        HYEYE.sharedInstance.isPreparedToPlay
            .filter { $0 }
            .map { _ in () }
            .bind(to: shouldPlayRelay)
            .disposed(by: disposeBag)
        
        // 监听错误
        HYEYE.sharedInstance.playbackError
            .subscribe(onNext: { [weak self] error in
                errorRelay.accept(error.description)
                self?.handlePlaybackError()
            })
            .disposed(by: disposeBag)
        
        // 监听首帧渲染
        HYEYE.sharedInstance.firstFrameRendered
            .subscribe(onNext: {
                playStatusRelay.accept("Playing".stLocalLized)
            })
            .disposed(by: disposeBag)
        
        return Output(
            videoPlaying: playingRelay.asDriver(),
            playStatus: playStatusRelay.asDriver(onErrorJustReturn: ""),
            error: errorRelay.asDriver(onErrorJustReturn: ""),
            shouldPlay: shouldPlayRelay.asDriver(onErrorJustReturn: ())
        )
    }
    
    // MARK: - Private Methods
    private func handlePlaybackError() {
        retryCount += 1
        if retryCount < maxRetryCount {
            let delay = Double(retryCount) * 3.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.retryPlayback()
            }
        }
    }
    
    private func retryPlayback() {
        openVideoTrigger.accept(())
    }
}
