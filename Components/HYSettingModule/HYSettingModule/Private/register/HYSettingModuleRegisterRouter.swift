//
//  HYSettingModuleRegisterRouter.swift
//  HYSettingModule
//
//  Created by defualt_author on 2025/02/09.
//

import STComponentTools.STRouter
import HYRouterServiceDefine
import MTCategoryComponent.MTUIViewControllerExtensionHeader
import HYBaseUI

private class HYSettingModuleRegisterRouter: NSObject, STRouterRegisterProtocol {
    public static func stRouterRegisterExecute() {
        stRouterRegisterUrlParttern(HYRouterServiceDefine.kRouterSetting, nil) { (req: STRouterUrlRequest, com: STRouterUrlCompletion?) in
            let topVC = req.fromVC ?? UIViewController.mt_top()
            let vc = HYSettingVC()
            topVC.navigationController?.pushViewController(vc, animated: true)
         }
    }
}

