//
//  HYSettingVC.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/2/9.
//

import UIKit

import HYAllBase
import InAppSettingsKit

class HYSettingVC: IASKAppSettingsViewController {
    var vm = HYSettingVM()
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "设置".stLocalLized
        view.backgroundColor = UIColor.c_main
        delegate = self
        
        self.navigationItem.hidesBackButton = true
        
        bindData()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cyl_setNavigationBarHiddenIfNeeded(animated)
        cyl_viewWillAppearNavigationSetting(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cyl_viewDidAppearNavigationSetting(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cyl_setNavigationBarHiddenIfNeeded(animated)
        cyl_viewWillDisappearNavigationSetting(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cyl_viewDidDisappearNavigationSetting(animated)
    }
}

// MARK: - MVVM methods
extension HYSettingVC: STMvvmProtocol, HYBaseVC_RxProtocol {
    func bindData() {
    }
}

// MARK: - IASKSettingsDelegate methods
extension HYSettingVC: IASKSettingsDelegate {
    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {
        navigationController?.popViewController(animated: true)
    }
}
