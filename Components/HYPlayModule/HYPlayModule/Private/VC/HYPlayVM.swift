//
//  HYPlayVM.swift
//  HYPlayModule
//
//  Created by stephen Li on 2025/2/9.
//

import HYAllBase

import HYEYE

class HYPlayVM: STViewModelProtocol {
    var disposeBag: DisposeBag = .init()
    
    // MARK: - Input/Output
    struct Input {
        let openVideoTrigger: BehaviorRelay<(Bool, URL?)>
    }
    
    struct Output {
        let videoPlaying: Driver<Bool>
        let videoPlayStart: Driver<Bool>
        let videoCreate: Driver<UIView?>
    }
    
    // MARK: - Properties
    let openVideoTrigger: BehaviorRelay<(Bool, URL?)> = .init(value: (false, nil))
    private let videoPlayingRelay: BehaviorRelay<Bool> = .init(value: false)
    private let videoPlayStartRelay: BehaviorRelay<Bool> = .init(value: false)
    private let videoCreateRelay: BehaviorRelay<UIView?> = .init(value: nil)
    
    // MARK: - Transform
    func transformInput(_ input: Input) -> Output {
        return Output(
            videoPlaying: videoPlayingRelay.asDriver(),
            videoPlayStart: videoPlayStartRelay.asDriver(),
            videoCreate: videoCreateRelay.asDriver()
        )
    }
}
