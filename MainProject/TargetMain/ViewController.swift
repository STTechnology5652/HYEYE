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
    
    private weak var defaultLaunchImage = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imgLaunchView = UIImageView(image: UIImage(named: "launch_image"))
        view.addSubview(imgLaunchView)
        defaultLaunchImage = imgLaunchView
        imgLaunchView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let defaultLaunchImage {
            self.defaultLaunchImage = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                defaultLaunchImage.removeFromSuperview()
            }
        }
    }
    
    func setUpUI() {
    }
    
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
        let req = STRouterUrlRequest.instance { builder in
            builder.urlToOpen = HYRouterServiceDefine.kRouterSetting
            builder.fromVC = self
        }
        
        stRouterOpenUrlRequest(req) {_ in }
    }
    
    private func openPlayVC() {
        let req = STRouterUrlRequest.instance { builder in
            builder.urlToOpen = HYRouterServiceDefine.kRouterPlay
            builder.fromVC = self
            builder.parameter = [
                HYRouterServiceDefine.kRouterPara_url : HYCommonConfig.kPlayUrl
            ]
        }
        
        stRouterOpenUrlRequest(req) {_ in }
    }
}
