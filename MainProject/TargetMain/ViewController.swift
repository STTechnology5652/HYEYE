//
//  ViewController.swift
//  HYEYE_Pro
//
//  Created by stephenchen on 2025/01/27.
//

import UIKit
import HYAllBase

class ViewController: HYBaseViewControllerMVVM {
    @IBOutlet private weak var btnOpenSetting: UIButton!
    @IBOutlet weak var btnPlay: UIButton!
    
    var vm = STViewControllerVM()
    var disposeBag = DisposeBag()
    
    func bindData() {
        let input: STViewControllerVM.Input = .init(
            openSetting: btnOpenSetting.rx.tap.asDriver(),
            openPlay: btnPlay.rx.tap.asDriver()
        )
        
        let output = vm.transformInput(input)
        output.openSettingCommand.drive(onNext: { [weak self] in
            self?.openSettingVC()
        })
        .disposed(by: disposeBag)
        
        output.openPlayCommand.drive(onNext: { [weak self] in
            self?.openPlayVC()
        })
        .disposed(by: disposeBag)
    }
    
    // MARK: - UIActions
    private func openSettingVC() {
        STRouter.shareInstance().stOpenUrlInstance(HYRouterServiceDefine.kRouterSetting, fromVC: self)
    }
    
    private func openPlayVC() {
        STRouter.shareInstance().stOpenUrlInstance(HYRouterServiceDefine.kRouterPlay, fromVC: self)
    }
}
