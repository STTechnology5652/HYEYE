//
//  STViewControllerVM.swift
//  HYEYE_Pro
//
//  Created by stephen Li on 2025/2/9.
//

import Foundation

import HYAllBase

class STViewControllerVM: STViewModelProtocol {
    var disposeBag: DisposeBag = .init()
    
    struct Input {
        let openSetting: Driver<Void>
        let openPlay: Driver<Void>
        let openAlbum: Driver<Void>
    }
    
    struct Output {
        let openSettingCommand: Driver<Void>
        let openPlayCommand: Driver<Void>
        let openAlbumCommand: Driver<Void>
    }
    
    func transformInput(_ input: Input) -> Output {
        
        return Output(
            openSettingCommand: input.openSetting,
            openPlayCommand: input.openPlay,
            openAlbumCommand: input.openAlbum
        )
    }
}
