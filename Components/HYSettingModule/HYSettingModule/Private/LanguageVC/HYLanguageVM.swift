//
//  HYLanguageVM.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/3/13.
//

import HYAllBase

final class HYLanguageVM: STViewModelProtocol {
    var disposeBag: RxSwift.DisposeBag = DisposeBag()
    
    struct Input {
        let reloadDataTrigger: PublishSubject<Void>
        let selectLanguageTrigger: Observable<HYLanguageCellModel>
    }
    
    struct Output {
        let dataSource: Observable<[SettingSectionModel<HYLanguageCellModel>]>
    }
    
    private let datasourceSubject = PublishSubject<[SettingSectionModel<HYLanguageCellModel>]>()
    
    func transformInput(_ input: Input) -> Output {
        input.reloadDataTrigger
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] _ in
                print(#function + " reload data")
                self?.createDataSource()
            }
            .disposed(by: disposeBag)
        
        // 处理语言选择
        input.selectLanguageTrigger
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe { weakSelf, selectedModel in
                HYResource.setLanguage(selectedModel.language)
                weakSelf.createDataSource()
            }
            .disposed(by: disposeBag)
        
        return Output(
            dataSource: datasourceSubject.asObservable()
        )
    }
    
    private func createDataSource() {
        let items: [HYLanguageCellModel] = HYResource.HYLanguage.allCases.map{ HYLanguageCellModel(language: $0) }
        let sectionModel = SettingSectionModel(items: items)
        datasourceSubject.onNext([sectionModel])
    }
}
