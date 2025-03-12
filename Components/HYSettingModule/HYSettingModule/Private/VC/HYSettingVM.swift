//
//  HYSettingVM.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/2/9.
//

import RxDataSources
import HYBaseUI

// 修改 Section 模型定义
struct SettingSectionModel {
    var header: String = ""  // 空字符串
    var items: [HYBaseCellModelInterface]
}

// 扩展 Section 以符合 SectionModelType
extension SettingSectionModel: SectionModelType {
    typealias Item = HYBaseCellModelInterface
    
    init(original: SettingSectionModel, items: [Item]) {
        self = original
        self.items = items
    }
}

final class HYSettingVM: STViewModelProtocol {
    var disposeBag: DisposeBag = DisposeBag()
    
    // 数据源
    private let sectionsRelay = PublishSubject<[SettingSectionModel]>()
    
    struct Input {
        let reloadDataTrigger: Observable<Void>
        let settingDidEndTrigger: Observable<Void>
        let settingChangedTrigger: Observable<(key: String, value: Any)>
    }
    
    struct Output {
        let shouldDismiss: Observable<Void>
        let settingUpdateResult: Observable<Bool>
        let sections: Observable<[SettingSectionModel]>
    }
    
    private func reloadData() {
        var items: [HYBaseCellModelInterface] = [ ]
        do {
            let icon = HYSettingCellModelCustom(title: "隐私设置".localized(), subTitle: "打开隐私设置".localized() )
            items.append(icon)
        }
        
        let section = SettingSectionModel(items: items)
        sectionsRelay.onNext([section])
    }
    
    func transformInput(_ input: Input) -> Output {
        input.reloadDataTrigger
            .subscribe { [weak self] itemList in
                self?.reloadData()
            }
            .disposed(by: disposeBag)
        
        // 处理设置变更
        let settingUpdateResult = input.settingChangedTrigger
            .map { setting -> Bool in
                do {
                    UserDefaults.standard.set(setting.value, forKey: setting.key)
                    UserDefaults.standard.synchronize()
                    
                    NotificationCenter.default.post(
                        name: Notification.Name("SettingChanged"),
                        object: nil,
                        userInfo: ["key": setting.key, "value": setting.value]
                    )
                    return true
                } catch {
                    print("Setting update failed: \(error.localizedDescription)")
                    return false
                }
            }
        
        return Output(
            shouldDismiss: input.settingDidEndTrigger,
            settingUpdateResult: settingUpdateResult,
            sections: sectionsRelay.asObservable()
        )
    }
}
