//
//  HYPlayModuleRegisterRouter.swift
//  HYPlayModule
//
//  Created by defualt_author on 2025/02/09.
//

import HYAllBase

private class HYPlayModuleRegisterRouter: NSObject, STRouterRegisterProtocol {
    public static func stRouterRegisterExecute() {
        stRouterRegisterUrlParttern(HYRouterServiceDefine.kRouterPlay, nil) { (req: STRouterUrlRequest, com: STRouterUrlCompletion?) in
            var topVC: UIViewController? = req.fromVC ?? UIViewController.mt_top()
            let url: String? = req.parameter[HYRouterServiceDefine.kRouterPara_url] as? String
            let vc = HYPlayVC(playUrl: url)
            
            if let topVC, topVC.supportedInterfaceOrientations != vc.supportedInterfaceOrientations {
                vc.cyl_disablePopGestureRecognizer = true
            }
            
            if let topVC {
                topVC.navigationController?.pushViewController(vc, animated: true)
            } else {
                print("\(#file)[\(#line)] [\(#function)] topVC is nil)")
            }
        }
        
        
        stRouterRegisterUrlParttern(HYRouterServiceDefine.kRouterAlbum, nil) { (req: STRouterUrlRequest, com: STRouterUrlCompletion?) in
            var topVC: UIViewController? = req.fromVC ?? UIViewController.mt_top()
            let url: String? = req.parameter[HYRouterServiceDefine.kRouterPara_url] as? String
            let vc = HYAlbumVC()
            
//            if let topVC, topVC.supportedInterfaceOrientations != vc.supportedInterfaceOrientations {
//                vc.cyl_disablePopGestureRecognizer = true
//            }
            
            if let topVC {
                topVC.navigationController?.pushViewController(vc, animated: true)
            } else {
                print("\(#file)[\(#line)] [\(#function)] topVC is nil)")
            }
        }
    }
}

