//
//  HYPlayVM.swift
//  HYPlayModule
//
//  Created by stephen Li on 2025/2/9.
//

import HYAllBase

import HYEYE

class HYPlayVM: STViewModelProtocol {
    struct Input {
        let openVideoTrigger: BehaviorRelay<(Bool, URL?)>
    }
    
    struct Output {
        let videoPlaying: Driver<Bool>
        let videoPlayStart: Driver<Bool>
        let videoCreate: Driver<UIView?>
    }
    
    var disposeBag: DisposeBag = .init()
    var player: IJKFFMoviePlayerController?
    var playingURL: URL?
    
    // MARK: output relay
    private let videoPlayingRelay: BehaviorRelay<Bool> = .init(value: false)
    private let videoPlayStartRelay: BehaviorRelay<Bool> = .init(value: false)
    private let videoCreateRelay: BehaviorRelay<UIView?> = .init(value: nil)
    
    deinit {
        player?.stop()
        player?.view?.removeFromSuperview()
        player = nil
    }
    
    func transformInput(_ input: Input) -> Output {
        input.openVideoTrigger
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isOpen, url: URL?) in
                guard let url else {
                    return
                }
                self?.openVideo(isOpen, url: url)
            })
            .disposed(by: disposeBag)
        
        return Output(
            videoPlaying: videoPlayingRelay.asDriver(),
            videoPlayStart: videoPlayStartRelay.asDriver(),
            videoCreate: videoCreateRelay.asDriver()
        )
    }
}

extension HYPlayVM {
    private func openVideo(_ open: Bool, url: URL) {
        guard open else { //停止播放
            videoPlayingRelay.accept(false)
            playingURL = nil
            return
        }
        
        if let player, let playingURL, playingURL == url { // 正在播放相同的url
            return
        }
        
        player?.stop() // 停止原来的player
        
        if let playerNew = HYEYE.openVideo(url: url) {
            videoCreateRelay.accept(playerNew.view)
            
            player = playerNew
            playerNew.prepareToPlay()
        } else {
            videoPlayStartRelay.accept(false)
        }
    }
}
