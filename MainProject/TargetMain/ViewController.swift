//
//  ViewController.swift
//  HYEYE_Pro
//
//  Created by stephenchen on 2025/01/27.
//

import UIKit
import HYAllBase

extension ViewController {
    func setUpUI() {
        view.addSubview(btnOpenSetting)
        view.addSubview(btnPlay)
        
        let imgLaunchView = UIImageView(image: UIImage(named: "launch_image"))
        view.addSubview(imgLaunchView)
        defaultLaunchImage = imgLaunchView
        imgLaunchView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        btnOpenSetting.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 40))
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.right.equalTo(-20)
        }
        
        let btnBottomList = [btnPlay, btnAlbum]
        let controlStack = UIStackView(arrangedSubviews: btnBottomList)
        controlStack.axis = .horizontal
        controlStack.spacing = 10
        view.addSubview(controlStack)
        controlStack.snp.makeConstraints { make in
            make.width.lessThanOrEqualToSuperview().offset(-40)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
        
        btnBottomList.forEach {
            $0.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 40, height: 40))
            }
        }
    }
    
    func bindData() {
        let input: STViewControllerVM.Input = .init(
            openSetting: btnOpenSetting.rx.tap.asDriver(),
            openPlay: btnPlay.rx.tap.asDriver(),
            openAlbum: btnAlbum.rx.tap.asDriver()
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
        
        output.openAlbumCommand.drive(onNext: { [weak self] in
            self?.openAlbumVC()
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
    
    private func openAlbumVC() {
        let req = STRouterUrlRequest.instance { builder in
            builder.urlToOpen = HYRouterServiceDefine.kRouterAlbum
            builder.fromVC = self
        }
        
        stRouterOpenUrlRequest(req) {_ in }
    }
}

class ViewController: HYBaseViewControllerMVVM {
    private lazy var btnOpenSetting: UIButton = {
        UIButton(type: .custom).then {
            $0.setBackgroundImage(UIImage.hyImage(name: "ico_setting"), for: .normal)
        }
    }()
    
    private lazy var btnPlay: UIButton = {
        UIButton(type: .custom).then {
            $0.setBackgroundImage(UIImage.hyImage(name: "ico_photo"), for: .normal)
        }
    }()
    
    private lazy var btnAlbum: UIButton = {
        UIButton(type: .custom).then {
            $0.setBackgroundImage(UIImage.hyImage(name: "ico_album"), for: .normal)
        }
    }()

    private weak var defaultLaunchImage: UIImageView?
    var vm = STViewControllerVM()
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
}
