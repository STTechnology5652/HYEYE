//
//  HYSettingVC.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/2/9.
//

import UIKit
import RxDataSources

import HYAllBase

// MARK: - MVVM methods
extension HYSettingVC {
    func bindData() {
        let settingDidEndSubject = PublishSubject<Void>()
        let settingChangedSubject = PublishSubject<(key: String, value: Any)>()
        
        let input = HYSettingVM.Input(
            reloadDataTrigger: reloadDataSubject,
            settingDidEndTrigger: settingDidEndSubject.asObservable(),
            settingChangedTrigger: settingChangedSubject.asObservable()
        )
        
        let output = vm.transformInput(input)
        
        output.sections
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
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
    }
}

@objc
class HYSettingVC: HYBaseViewControllerMVVM, HYBaseListViewInterface {
    func setUpUI() {
        setupUI()
    }
    
    // MARK: - Properties
    var vm = HYSettingVM()
    var disposeBag = DisposeBag()
    
    // 数据
    private var reloadDataSubject = PublishSubject<Void>()
    
    // MARK: - DataSource
    private lazy var dataSource: RxTableViewSectionedReloadDataSource<SettingSectionModel> = {
        return RxTableViewSectionedReloadDataSource<SettingSectionModel>(
            configureCell: { [weak self] (dataSource, tableView, indexPath, item: HYBaseCellModelInterface) -> UITableViewCell in
                guard let cell = item.cellForIndexpath(listView: tableView, indexPath: indexPath) else {
                    return UITableViewCell(style: .default, reuseIdentifier: "DefaultCell")
                }
                return cell
            })
    }()

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hyBackImg = nil
        title = "设置".stLocalLized
        
        setupUI()
        bindData()
        reloadDataSubject.onNext(())
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 注册 cell
        let cellTypeList: [(UITableViewCell & HYBaseCellInterface).Type] = [
            HYSetCellSwitch.self,
            HYSettingCellCustom.self
        ]
        cellTypeList.forEach { (oneType: (UITableViewCell & HYBaseCellInterface).Type) in
            registerCell(tableView, cellType: oneType)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 60
        table.sectionHeaderHeight = 0
        table.sectionFooterHeight = 0
        table.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        table.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        return table
    }()
}
