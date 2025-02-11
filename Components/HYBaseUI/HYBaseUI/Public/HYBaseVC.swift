//
//  HYBaseVC.swift
//  HYBaseUI
//
//  Created by Macintosh HD on 2025/1/27.
//

import UIKit
import CYLTabBarController
import HYResource

public typealias HYBaseViewControllerMVVM = HYBaseVC & STMvvmProtocol & HYBaseVC_RxProtocol

public protocol HYBaseVC_RxProtocol {
    var disposeBag: DisposeBag { get set}
    
    func setUpUI()
}

open class HYBaseVC: CYLBaseViewController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.c_main
        hidesBottomBarWhenPushed = true
        
        let btnBack = UIButton(type: .custom)
        btnBack.setBackgroundImage(UIImage.hyImage(name: "ico_back"), for: .normal)
        btnBack.addTarget(self, action: #selector(actionBact), for: .touchUpInside)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btnBack)
        
        if navigationController?.viewControllers.count ?? 0 < 2 {
            cyl_navigationBarHidden = true
        }
        
        if let `self` = self as? HYBaseVC_RxProtocol {
            self.setUpUI()
        }
        
        if let `self` = self as? (any STMvvmProtocol) {
            self.bindData()
        }
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @objc private func actionBact() {
        navigationController?.popViewController(animated: true)
    }
    
}


