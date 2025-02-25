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
    private let playStateRelay = BehaviorRelay<HYEyePlayerState>(value: .shutdown)
    
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
        let openVideoUrl: Observable<(String?, UIView)>
        let closeVideo: Observable<Void>
        let playTrigger: Observable<Void>
        let stopTrigger: Observable<Void>
        let photoTrigger: Observable<Void>
        let recordTrigger: Observable<Void>
    }
    
    struct HYPlayVMOutput {
        let playStateReplay: Driver<HYEyePlayerState>
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
                let eyeIns = HYEYE.sharedInstance
                eyeIns.openVideo(url: url, backView: view)// url 已经确定不为空
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
                HYEYE.sharedInstance.shutdown()
            })
            .disposed(by: disposeBag)
        
        return HYPlayVMOutput(
            playStateReplay: playStateRelay.asDriver()
        )
    }
    
}

// 添加 delegate 实现
extension HYPlayVM: HYEYEDelegate {
    func playerStateDidChange(_ state: HYEyePlayerState) {
    }
    
    func playerLoadFinished(success: Bool) {
        
    }
}

