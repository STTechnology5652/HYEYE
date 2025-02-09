//
//  HYPlayVM.swift
//  HYPlayModule
//
//  Created by stephen Li on 2025/2/9.
//

import HYAllBase

import HYEYE

struct HYPlayVM: STViewModelProtocol {
    var disposeBag: DisposeBag = .init()
    
    struct Input {
    }
    
    struct Output {
    }
    
    func transformInput(_ input: Input) -> Output {
        return Output()
    }
}
