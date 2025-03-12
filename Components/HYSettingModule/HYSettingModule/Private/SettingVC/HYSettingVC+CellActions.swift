//
//  HYSettingVC+CellActions.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/3/13.
//  处理cell事件

import HYAllBase

extension HYSettingVC {
    func deathCellAction(_ action: HYSettingAction) {
        switch action {
        case .systemPrivacy:
            openSystemSetting()
        case .setLanguage:
            setLanguage()
        }
    }
}

extension HYSettingVC {
    private func openSystemSetting() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
    
    private func setLanguage() {
        let req = STRouterUrlRequest.instance { builder in
            builder.urlToOpen = HYRouterServiceDefine.kRouterLanguage
            builder.fromVC = self
        }
        
        stRouterOpenUrlRequest(req) {_ in }
    }
}
