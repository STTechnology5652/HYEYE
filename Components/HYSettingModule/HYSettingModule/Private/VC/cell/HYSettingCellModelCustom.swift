//
//  HYSettingCellModelCustom.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/3/9.
//

import HYAllBase
import RxSwift

struct HYSettingCellModelCustom: STViewModelProtocol, HYBaseCellModelInterface {
    let title: String
    let subTitle: String
    let desText: String?
    let hideArrow: Bool
    
    var cellIdentifier: String = HYSettingCellCustom.cellIdentifier
    
    struct Input {
        
    }
    
    struct Output {
        
    }
    
    var disposeBag = DisposeBag()
    
    func transformInput(_ input: Input) -> Output {
       
        return Output()
    }
    
    init() {
        self.init(title: "", subTitle: "")
    }

    init(title: String, subTitle: String, desText: String? = nil, hideArrow: Bool = false) {
        self.title = title
        self.subTitle = subTitle
        self.desText = desText
        self.hideArrow = hideArrow
    }
}
