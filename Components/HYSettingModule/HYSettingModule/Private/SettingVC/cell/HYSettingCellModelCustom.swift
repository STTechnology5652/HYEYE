//
//  HYSettingCellModelCustom.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/3/9.
//

import HYAllBase
import RxSwift

struct HYSettingCellModelCustom: STViewModelProtocol, HYBaseCellModelInterface,  HYSettingActionInterface {
    let title: String
    let subTitle: String?
    let desText: String?
    let hideArrow: Bool
    
    var cellIdentifier: String = HYSettingCellCustom.cellIdentifier
    
    var settingAction: HYSettingAction = .systemPrivacy

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

    init(title: String, subTitle: String? = nil, desText: String? = nil, hideArrow: Bool = false, settingAction: HYSettingAction = .systemPrivacy) {
        self.title = title
        self.subTitle = subTitle
        self.desText = desText
        self.hideArrow = hideArrow
        self.settingAction = settingAction
    }
}
