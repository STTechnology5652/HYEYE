//
//  HYSettingVM.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/2/9.
//

import HYBaseUI

struct HYSettingVM: STViewModelProtocol {
    var disposeBag: DisposeBag = DisposeBag()
    
    struct Input {
        let settingDidEndTrigger: Observable<Void>
        let settingChangedTrigger: Observable<(key: String, value: Any)>
    }
    
    struct OutPut {
        let shouldDismiss: Observable<Void>
        let settingUpdateResult: Observable<Bool>
    }

    func transformInput(_ input: Input) -> OutPut {
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
            
        return OutPut(
            shouldDismiss: input.settingDidEndTrigger,
            settingUpdateResult: settingUpdateResult
        )
    }
}
