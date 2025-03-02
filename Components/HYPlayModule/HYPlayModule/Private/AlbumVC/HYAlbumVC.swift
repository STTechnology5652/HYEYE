//
//  HYAlbumVC.swift
//  HYPlayModule
//
//  Created by stephen Li on 2025/3/2.
//

import HYAllBase

class HYAlbumVC: HYBaseViewControllerMVVM {
    var vm = HYAlbumVM()
    var disposeBag: DisposeBag = DisposeBag()
    
    func setUpUI() {
        title = "相册".stLocalLized
        
    }
    
    func bindData() {
        
    }
}
