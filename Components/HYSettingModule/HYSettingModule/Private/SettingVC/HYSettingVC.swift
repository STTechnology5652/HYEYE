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
        // cell 点击事件
        let cellSelectedTrigger = tableView.rx.modelSelected(HYSettingItem.self)
            .do(onNext: { [weak self] item in
                if let indexPath = self?.tableView.indexPathForSelectedRow {
                    self?.tableView.deselectRow(at: indexPath, animated: true)
                }
            })
            .share(replay: 1, scope: .whileConnected)  // 使用 share 来避免重复订阅
        
        let input = HYSettingVM.Input(
            reloadDataTrigger: reloadDataSubject,
            cellSelectedTrigger: cellSelectedTrigger
        )
        
        let output = vm.transformInput(input)
        
        // 绑定数据源
        output.sections
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        // 处理点击事件
        output.cellAction
            .subscribe(onNext: { [weak self] action in
                self?.deathCellAction(action)
            })
            .disposed(by: disposeBag)
    }
    
}

@objc
class HYSettingVC: HYBaseViewControllerMVVM, HYBaseListViewInterface {
    // MARK: - Properties
    var vm = HYSettingVM()
    var disposeBag = DisposeBag()
    
    // 数据
    private var reloadDataSubject = PublishSubject<Void>()
    
    // MARK: - DataSource
    private lazy var dataSource: RxTableViewSectionedReloadDataSource<SettingSectionModel> = {
        return RxTableViewSectionedReloadDataSource<SettingSectionModel<HYSettingItem>>(
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
        setUpUI()
        bindData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "设置".stLocalLized
        reloadDataSubject.onNext(())
    }
    
    // MARK: - Setup
    func setUpUI() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 注册 cell
        let cellTypeList: [(UITableViewCell & HYBaseCellInterface).Type] = [
            HYSettingCellCustom.self
        ]
        cellTypeList.forEach { (oneType: (UITableViewCell & HYBaseCellInterface).Type) in
            registerCell(tableView, cellType: oneType)
        }
    }
    
    private lazy var tableView: UITableView = {
        UITableView(frame: .zero, style: .plain).then {
            $0.separatorStyle = .none
            $0.rowHeight = UITableView.automaticDimension
            $0.estimatedRowHeight = 60
            $0.sectionHeaderHeight = 0
            $0.sectionFooterHeight = 0
            $0.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
            $0.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        }
    }()
}
