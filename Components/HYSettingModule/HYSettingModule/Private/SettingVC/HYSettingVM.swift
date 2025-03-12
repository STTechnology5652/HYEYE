//
//  HYSettingVM.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/2/9.
//

import RxDataSources
import HYBaseUI

// 修改 Section 模型定义

typealias HYSettingItem = HYBaseCellModelInterface & HYSettingActionInterface
struct SettingSectionModel<T> {
    var header: String = ""  // 空字符串
    var items: [T]
}

// 扩展 Section 以符合 SectionModelType
extension SettingSectionModel: SectionModelType {
    typealias Item = T
    
    init(original: SettingSectionModel, items: [Item]) {
        self = original
        self.items = items
    }
}

final class HYSettingVM: STViewModelProtocol {
    var disposeBag: DisposeBag = DisposeBag()
    
    // 数据源
    private let sectionsRelay = PublishSubject<[SettingSectionModel<HYSettingItem>]>()
    
    struct Input {
        let reloadDataTrigger: PublishSubject<Void>
        let cellSelectedTrigger: Observable<HYSettingItem>
    }
    
    struct Output {
        let sections: Observable<[SettingSectionModel<HYSettingItem>]>
        let cellAction: Observable<HYSettingAction>
    }
    
    func transformInput(_ input: Input) -> Output {
        input.reloadDataTrigger
            .subscribe { [weak self] _ in
                self?.reloadData()
            }
            .disposed(by: disposeBag)
        
        // 处理 cell 点击，使用 PublishSubject 来控制事件流
        let actionSubject = PublishSubject<HYSettingAction>()
        
        input.cellSelectedTrigger
            .map { $0.settingAction }
            .bind(to: actionSubject)
            .disposed(by: disposeBag)
        
        return Output(
            sections: sectionsRelay.asObservable(),
            cellAction: actionSubject.asObservable()
        )
    }
    
    private func reloadData() {
        var items: [HYSettingItem] = []
        do {
            let oneCellModel = HYSettingCellModelCustom(title: "隐私设置".stLocalLized, settingAction: .systemPrivacy)
            items.append(oneCellModel)
        }
        
        do {
            let oneCellModel = HYSettingCellModelCustom(title: "语言".stLocalLized, settingAction: .setLanguage)
            items.append(oneCellModel)
        }

        let section = SettingSectionModel(items: items)
        sectionsRelay.onNext([section])
    }
}
