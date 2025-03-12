//
//  HYAboutVC.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/3/13.
//

import HYAllBase

class HYAboutVC: HYBaseVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        bindData()
    }
    
    func setUpUI() {
        title = "关于".stLocalLized
        hyBackImg = nil
        
        view.addSubview(imgIcon)
        view.addSubview(labVersion)
        
        imgIcon.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50)
            make.size.equalTo(CGSize(width: 100, height: 100))
            make.centerX.equalToSuperview()
        }
        
        labVersion.snp.makeConstraints { make in
            make.top.equalTo(imgIcon.snp_bottom).offset(10)
            make.width.equalToSuperview().offset(-40)
            make.centerX.equalToSuperview()
        }
    }
    
    func bindData() {
        imgIcon.image = HYResource.appIcon()
        labVersion.text = HYResource.appName() + " " + HYResource.appVersion() + "(" + HYResource.appBuildVersion() + ")"
    }
    
    private lazy var imgIcon: UIImageView = {
        UIImageView().then{
            $0.contentMode = .scaleAspectFit
            $0.layer.cornerRadius = 20
            $0.layer.masksToBounds = true
        }
    }()
    
    private lazy var labVersion: UILabel = {
        UILabel().then {
            $0.textColor = .c_text
            $0.numberOfLines = 0
            $0.font = UIFont.systemFont(ofSize: 20)
            $0.textAlignment = .center
        }
    }()
}
