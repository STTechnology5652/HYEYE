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
    
    private var eye: any HYEYEInterface = HYEYE.create()
    
    // 状态相关
    private let playStateRelay = BehaviorRelay<HYEyePlayerState>(value: .shutdown)
    private let recordVideoTrigger: BehaviorRelay<(Bool, URL?)> = BehaviorRelay(value: (false, nil))
    
    deinit {
        disposeBag = DisposeBag()
        eye.delegate = nil
        eye.shutdown()
    }
    
    init() {
        // 设置 delegate
        eye.delegate = self
    }
    
    // MARK: - Input & Output
    struct HYPlayVMInput {
        let openVideoUrl: Observable<(String?, UIView)>
        let closeVideo: Observable<Void>
        let playerStateChange: Observable<Void>
        let stopTrigger: Observable<Void>
        let photoTrigger: Observable<Void>
        let recordTrigger: Observable<Void>
    }
    
    struct HYPlayVMOutput {
        let playStateReplay: Driver<HYEyePlayerState>
        let takePhotoTracer: Driver<UIImage?>
        let recordVideoTracer: Driver<(Bool, URL?)>
    }
    
    // MARK: - Transform
    func transformInput(_ input: HYPlayVMInput) -> HYPlayVMOutput {
        print("transformInput")
        // 处理开始播放
        input.openVideoUrl
            .compactMap { (urlStr, view) -> (URL, UIView)? in
                guard let urlStr = urlStr,  // 首先确保 urlStr 不为空
                      let url = URL(string: urlStr) else {
                    print("HYEYE Error: Invalid URL string")
                    return nil
                }
                return (url, view)
            }
            .subscribe(onNext: { [weak self] (url: URL, view: UIView) in
                print("openVideoUrl execute: \(url)")
                self?.eye.openVideo(url: url, backView: view)// url 已经确定不为空
            })
            .disposed(by: disposeBag)
        
        input.playerStateChange
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)  // 防止快速重复触发
            .subscribe(onNext: { [weak self] in
                print("start player")
                guard let eye = self?.eye else { return }
                
                if eye.playerState() == .playing {
                    eye.stop()
                } else {
                    eye.play()
                }
                
            })
            .disposed(by: disposeBag)
        
        input.stopTrigger
            .subscribe(onNext: { [weak self] in
                self?.eye.stop()
            })
            .disposed(by: disposeBag)
        
        let photoTrigger: BehaviorRelay<UIImage?> = .init(value: nil)
        input.photoTrigger
            .subscribe(onNext: { [weak self] in
                let image: UIImage? = self?.eye.takePhoto()
                photoTrigger.accept(image)
            })
            .disposed(by: disposeBag)
        
        // 处理停止播放
        input.closeVideo
            .subscribe(onNext: { [weak self] in
                self?.eye.shutdown()
            })
            .disposed(by: disposeBag)
        
        input.recordTrigger
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                if eye.isRecordingVideo {
                    eye.stopRecordVideo()
                } else {
                    let result = eye.recordVideo()
                    recordVideoTrigger.accept((result, nil))
                }
            })
            .disposed(by: disposeBag)
        
        return HYPlayVMOutput(
            playStateReplay: playStateRelay.asDriver(),
            takePhotoTracer: photoTrigger.asDriver(),
            recordVideoTracer: recordVideoTrigger.asDriver()
        )
    }
}

// 添加 delegate 实现
extension HYPlayVM: HYEYEDelegate {
    func playerStateDidChange(_ state: HYEyePlayerState) {
        playStateRelay.accept(state)
    }
    
    func firstFrameRendered() {
        
    }
    
    func finishRecordVideo(isRecording: Bool, videoUrl: URL?) {
        print(#function + " \(isRecording): \(videoUrl)")
        recordVideoTrigger.accept((isRecording, videoUrl))
    }
}

