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
        case .aboutUs:
            aboutUs()
        case .userPrivacy:
            userPrivacy()
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
    
    private func aboutUs() {
        let req = STRouterUrlRequest.instance { builder in
            builder.urlToOpen = HYRouterServiceDefine.kRouterAbout
            builder.fromVC = self
        }
        
        stRouterOpenUrlRequest(req) {_ in }
    }
    
    private func userPrivacy() {
        let req = STRouterUrlRequest.instance { builder in
            builder.urlToOpen = HYRouterServiceDefine.kRouterWeb
            builder.parameter = [
                HYRouterServiceDefine.kRouterPara_WebUrl: "https://cv-mc.com/mark/yszc.html",
                HYRouterServiceDefine.kRouterPara_WebTitle: "隐私政策".stLocalLized 
            ]
            builder.fromVC = self
        }
        
        stRouterOpenUrlRequest(req) {_ in }
    }
}
