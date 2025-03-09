//
//  HYSettingVC.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/2/9.
//

import UIKit

import HYAllBase
import InAppSettingsKit

// MARK: - MVVM methods
extension HYSettingVC: STMvvmProtocol, HYBaseVC_RxProtocol {
    func setUpUI() {
    }
    
    func bindData() {
        let settingDidEndSubject = PublishSubject<Void>()
        let settingChangedSubject = PublishSubject<(key: String, value: Any)>()
        
        let input = HYSettingVM.Input(
            settingDidEndTrigger: settingDidEndSubject.asObservable(),
            settingChangedTrigger: settingChangedSubject.asObservable()
        )
        
        let output = vm.transformInput(input)
        
        output.shouldDismiss
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
            
        output.settingUpdateResult
            .subscribe(onNext: { success in
                if !success {
                    print("设置更新失败")
                }
            })
            .disposed(by: disposeBag)
        
        self.settingDidEndSubject = settingDidEndSubject
        self.settingChangedSubject = settingChangedSubject
    }
    
    @objc private func backButtonTapped() {
        settingDidEndSubject?.onNext(())
    }
}

// MARK: - IASKSettingsDelegate methods
extension HYSettingVC: IASKSettingsDelegate {
    @objc public
    func settingsViewController(_ sender: IASKAppSettingsViewController!, tableView: UITableView!, cellForSpecifier specifier: IASKSpecifier!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCell(withIdentifier: specifier.key())
        
//        // 自定义cell样式
//        cell.backgroundColor = .white
//        cell.textLabel?.textColor = UIColor(hex: "#333333")
//        
//        // 自定义开关样式
//        if let switchView = cell.accessoryView as? UISwitch {
//            switchView.onTintColor = UIColor(hex: "#FF6D3F")
//        }
//        
//        // 自定义滑块样式
//        if let slider = cell.contentView.subviews.first(where: { $0 is UISlider }) as? UISlider {
//            slider.tintColor = UIColor(hex: "#4A90E2")
//        }
        
        return cell
    }
    
    @objc public
    func settingsViewController(_ settingsViewController: (any IASKViewController)!, tableView: UITableView!, viewForHeaderForSection section: Int) -> UIView! {
        return section == 0 ? UIView() : nil
    }
    
    @objc public
    func settingsViewController(_ sender: IASKAppSettingsViewController!, tableView: UITableView!, heightForHeaderForSection section: Int) -> CGFloat {
        return section == 0 ? 0.1 : UITableView.automaticDimension
    }
    
    func settingsViewController(_ settingsViewController: (any IASKViewController)!, tableView: UITableView!, viewForFooterForSection section: Int) -> UIView! {
        return UIView()
    }
    
    @objc public
    func settingsViewController(_ sender: IASKAppSettingsViewController!, tableView: UITableView!, heightForFooterForSection section: Int) -> CGFloat {
        return 0.1
    }
    
    @objc public
    func settingsViewController(_ sender: IASKAppSettingsViewController!, buttonTappedFor specifier: IASKSpecifier!) {
        settingChangedSubject?.onNext((key: specifier.key(), value: specifier.defaultValue()))
    }
    
    @objc public
    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {
        settingDidEndSubject?.onNext(())
    }
}

@objc
class HYSettingVC: IASKAppSettingsViewController {
    var vm = HYSettingVM()
    var disposeBag = DisposeBag()
    
    private var settingDidEndSubject: PublishSubject<Void>?
    private var settingChangedSubject: PublishSubject<(key: String, value: Any)>?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "设置".stLocalLized
        view.backgroundColor = UIColor.c_main
        tableView.tintColor = UIColor.c_text
        view.tintColor = UIColor.c_text
        delegate = self
        showCreditsFooter = false
        settingsReader = createSettingReader()
        
        setUpUI()
        bindData()
    }
    
    private func createSettingReader() -> IASKSettingsReader {
        let moduleBundle: Bundle = Bundle(for: HYSettingVC.self)
        let reader: IASKSettingsReader = IASKSettingsReader(settingsFileNamed: "Root", applicationBundle: moduleBundle)
        return reader
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

