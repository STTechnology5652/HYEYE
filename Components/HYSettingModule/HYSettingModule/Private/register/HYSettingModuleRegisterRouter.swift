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
import WebKit

private class HYSettingModuleRegisterRouter: NSObject, STRouterRegisterProtocol {
    public static func stRouterRegisterExecute() {
        stRouterRegisterUrlParttern(HYRouterServiceDefine.kRouterSetting, nil) { (req: STRouterUrlRequest, com: STRouterUrlCompletion?) in
            let topVC = req.fromVC ?? UIViewController.mt_top()
            let vc = HYSettingVC()
            topVC.navigationController?.pushViewController(vc, animated: true)
         }
        
        stRouterRegisterUrlParttern(HYRouterServiceDefine.kRouterLanguage, nil) { (req: STRouterUrlRequest, com: STRouterUrlCompletion?) in
            let topVC = req.fromVC ?? UIViewController.mt_top()
            let vc = HYLanguageVC()
            topVC.navigationController?.pushViewController(vc, animated: true)
         }
        
        stRouterRegisterUrlParttern(HYRouterServiceDefine.kRouterAbout, nil) { (req: STRouterUrlRequest, com: STRouterUrlCompletion?) in
            let topVC = req.fromVC ?? UIViewController.mt_top()
            let vc = HYAboutVC()
            topVC.navigationController?.pushViewController(vc, animated: true)
         }
        
        
        stRouterRegisterUrlParttern(HYRouterServiceDefine.kRouterWeb, nil) { (req: STRouterUrlRequest, com: STRouterUrlCompletion?) in
            guard let urlStr = req.parameter[HYRouterServiceDefine.kRouterPara_WebUrl] as? String,
                  let url: URL = URL(string: urlStr) else {
                return
            }
            
            let vc = HYWebVC(url: url)
            if let title = req.parameter[HYRouterServiceDefine.kRouterPara_WebTitle] as? String, title.isEmpty == false {
                vc.title = title
            }
            
            let topVC = req.fromVC ?? UIViewController.mt_top()
            topVC.navigationController?.pushViewController(vc, animated: true)
         }
    }
}

