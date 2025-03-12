//
//  HYLanguageVC.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/3/13.
//

import HYAllBase

class HYLanguageVC: HYBaseViewControllerMVVM, HYBaseListViewInterface {
    var disposeBag: DisposeBag = DisposeBag()
    var vm = HYLanguageVM()
    
    private var reloadDataTrigger = PublishSubject<Void>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "语言".localized()
        
        setUpUI()
        bindData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadDataTrigger.onNext(())
        reloadDataTrigger.onNext(())
    }
    
    private func updatedLanguage() {
        title = "语言".localized()
    }
    
    private lazy var tableView: UITableView = {
        UITableView(frame: .zero, style: .plain).then {
            $0.separatorStyle = .none
            $0.rowHeight = UITableView.automaticDimension
            $0.estimatedRowHeight = 20
            $0.backgroundColor = .cyan
            $0.sectionHeaderHeight = 0
            $0.sectionFooterHeight = 0
            $0.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
            $0.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        }
    }()
}

extension HYLanguageVC {
    func setUpUI() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        registerCell(tableView, cellType: HYLanguageCell.self)
    }
    
    func bindData() {
        let input = HYLanguageVM.Input(
            reloadDataTrigger: reloadDataTrigger,
            selectLanguageTrigger: tableView.rx.modelSelected(HYLanguageCellModel.self).asObservable()
        )
        
        let output = vm.transformInput(input)
        output.dataSource
            .bind(to: tableView.rx.items(dataSource: createDataSource()))
            .disposed(by: disposeBag)
    }
    
    
    private func createDataSource() -> RxTableViewSectionedReloadDataSource<SettingSectionModel<HYLanguageCellModel>> {
        return RxTableViewSectionedReloadDataSource<SettingSectionModel<HYLanguageCellModel>>(
            configureCell: { (section, tableView, indexPath, item) in
                guard let cell = item.cellForIndexpath(listView: tableView, indexPath: indexPath) else {
                    return UITableViewCell(style: .default, reuseIdentifier: "DEFAULT_LANGUAGE_CELL")
                }
                return cell
            }
        )
    }
}
