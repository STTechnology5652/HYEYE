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
    let photoTrigger = PublishRelay<Void>()
    private var retryCount: Int = 0
    private let maxRetryCount: Int = 3
    private let frameInterval: Int = 5  // 每5帧存储一次，可以根据需要调整
    
    // 拍照配置
    private let photoConfig = HYPhotoConfig(
        frameInterval: 5,          // 每5帧存储一次
        targetFrameCount: 100,     // 存储100张
        savePath: nil,             // 存储到相册
        imageQuality: 0.8,         // 80%质量
        saveOriginalData: false    // 不保存原始数据
    )
    
    // 拍照状态
    public private(set) var isCapturing = false
    private let photoCountRelay = BehaviorRelay<String>(value: "")
    
    private let stateRelay = BehaviorRelay<PlaybackState>(value: .idle)
    private var photoState = PhotoState(isCapturing: false, currentCount: 0, totalCount: 0)
    
    // MARK: - Input & Output
    struct Input {
        let openVideoTrigger: PublishRelay<Void>
        let playTrigger: PublishRelay<Void>
        let stopTrigger: PublishRelay<Void>
        let photoTrigger: PublishRelay<Void>
    }
    
    struct Output {
        let videoPlaying: Driver<Bool>
        let playStatus: Driver<String>
        let error: Driver<String>
        let shouldPlay: Driver<Void>  // 用于通知 VC 开始播放
        let photoCount: Driver<String>  // 添加照片计数输出
    }
    
    // MARK: - Transform
    func transformInput(_ input: Input) -> Output {
        let playStatusRelay = BehaviorRelay<String>(value: "")
        let errorRelay = PublishRelay<String>()
        let shouldPlayRelay = PublishRelay<Void>()
        let playingRelay = BehaviorRelay<Bool>(value: false)
        
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
                guard let self = self else { return }
                let playbackError: PlaybackError
                // 根据错误类型转换为我们的错误枚举
                if error.description.contains("network") {
                    playbackError = .networkError
                } else if error.description.contains("prepare") {
                    playbackError = .prepareFailed
                } else {
                    playbackError = .unknownError
                }
                self.stateRelay.accept(.error(playbackError))
                errorRelay.accept(error.description)
                self.handlePlaybackError()
            })
            .disposed(by: disposeBag)
        
        // 监听首帧渲染
        HYEYE.sharedInstance.firstFrameRendered
            .subscribe(onNext: {
                playStatusRelay.accept("Playing".stLocalLized)
            })
            .disposed(by: disposeBag)
        
        // 监听拍照触发
        input.photoTrigger
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                if self.photoState.isCapturing {
                    self.photoCountRelay.accept("正在拍照中...")
                    return
                }
                
                self.photoState.isCapturing = true
                self.photoState.currentCount = 0
                self.photoState.totalCount = self.photoConfig.targetFrameCount
                self.photoCountRelay.accept("准备开始拍照...")
                
                HYEYE.sharedInstance.takePhoto(config: self.photoConfig) { [weak self] (count: Int, total: Int) in
                    guard let self = self else { return }
                    
                    self.photoState.currentCount = count
                    if count >= total {
                        self.photoState.isCapturing = false
                        self.photoCountRelay.accept("拍照完成: \(count)/\(total)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                            self?.photoCountRelay.accept("")
                        }
                    } else {
                        self.photoCountRelay.accept("拍照进度: \(count)/\(total)")
                    }
                }
            })
            .disposed(by: disposeBag)
        
        return Output(
            videoPlaying: playingRelay.asDriver(),
            playStatus: playStatusRelay.asDriver(onErrorJustReturn: ""),
            error: errorRelay.asDriver(onErrorJustReturn: ""),
            shouldPlay: shouldPlayRelay.asDriver(onErrorJustReturn: ()),
            photoCount: photoCountRelay.asDriver()
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

// 1. 建议添加播放器状态枚举
enum PlaybackState {
    case idle
    case preparing
    case playing
    case paused
    case stopped
    case error(Error)
}

// 2. 建议添加照片状态管理
private struct PhotoState {
    var isCapturing: Bool
    var currentCount: Int
    var totalCount: Int
}

// 3. 建议添加错误处理枚举
enum PlaybackError: Error {
    case prepareFailed
    case networkError
    case unknownError
}
