//
//  HYBaseVC.swift
//  HYBaseUI
//
//  Created by Macintosh HD on 2025/1/27.
//

import UIKit
import CYLTabBarController
import HYResource
import SnapKit
import RxSwift
import RxCocoa

public typealias HYBaseViewControllerMVVM = HYBaseVC & STMvvmProtocol & HYBaseVC_RxProtocol

public protocol HYBaseVC_RxProtocol {
    var disposeBag: DisposeBag { get set}
    
    func setUpUI()
}

private class HYBackImageView : UIView {
    let backImageView: UIImageView = {
        let imgView = UIImageView(image: UIImage.hyImage(name: "img_home_back"))
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    
    let iconTextView: UIImageView = {
        let imgView = UIImageView(image: UIImage.hyImage(name: "icon_text"))
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(backImageView)
        addSubview(iconTextView)
        
        backImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        iconTextView.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.size.equalTo(CGSize(width: 260, height: 60))
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class HYBaseVC: CYLBaseViewController {
    private var disposeBagForDeviceOrientation: DisposeBag = DisposeBag()
    
    private let imgBackView: HYBackImageView = {
        let imgView = HYBackImageView()
        return imgView
    }()
    
    public func hideBackIconImage(_ hide: Bool) {
        self.imgBackView.iconTextView.isHidden = hide
    }
    
    public var hyBackImg: UIImage? = UIImage.hyImage(name: "img_home_back") {
        didSet {
            UIView.animate(withDuration: 0.1) { // 防止闪屏
                self.imgBackView.backImageView.image = self.hyBackImg
            }
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.c_main
        hidesBottomBarWhenPushed = true
        
        view.insertSubview(imgBackView, at: 0)
        imgBackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
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
        
        if let self_mvvm = self as? (any STMvvmProtocol) {
            self_mvvm.bindData()
        }
        
        // 监听屏幕方向变化
        NotificationCenter.default.rx.notification(UIDevice.orientationDidChangeNotification)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateBackgroundForOrientation()
            })
            .disposed(by: self.disposeBagForDeviceOrientation)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 启用设备方向监听
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        updateBackgroundForOrientation()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    open func updateBackgroundForOrientation() {
        if hyBackImg == nil { return }
        let orientation = UIApplication.shared.statusBarOrientation
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            hyBackImg = UIImage.hyImage(name: "img_home_back_landscape")
        case .portrait, .portraitUpsideDown:
            hyBackImg = UIImage.hyImage(name: "img_home_back")
        default:
            break
        }
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @objc private func actionBact() {
        navigationController?.popViewController(animated: true)
    }
    
}


