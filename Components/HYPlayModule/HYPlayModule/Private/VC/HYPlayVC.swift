//
//  HYPlayVC.swift
//  HYPlayModule
//
//  Created by stephen Li on 2025/2/9.
//

import HYAllBase

class HYPlayVC: HYBaseViewControllerMVVM {
    var vm: HYPlayVM = HYPlayVM()
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "HYPlayVC".stLocalLized
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    func bindData() {
        let input: HYPlayVM.Input = .init()
        let _ = vm.transformInput(input)
    }
    
}
