//
//  HYAlbumVM.swift
//  HYPlayModule
//
//  Created by stephen Li on 2025/3/2.
//

import HYAllBase
import Photos

final class HYAlbumVM: STViewModelProtocol {
    var disposeBag: RxSwift.DisposeBag = DisposeBag()
    private let albumService: HYAlbumServiceInterface
    
    init(albumService: HYAlbumServiceInterface = HYAlbumService()) {
        self.albumService = albumService
    }
    
    struct Input {
        /// 页面加载触发器
        let loadTrigger: Observable<Void>
        /// 选中照片触发器
        let selectPhotoTrigger: Observable<PHAsset>
    }
    
    struct Output {
        /// 相册资源数组
        let assetsDriver: Driver<[PHAsset]>
        /// 选中的照片数据
        let selectedAssetDriver: Driver<PHAsset>
        /// 相册名称
        let albumNameDriver: Driver<String>
    }
    
    func transformInput(_ input: HYAlbumVM.Input) -> HYAlbumVM.Output {
        // 处理加载相册数据
        let assetsDriver = input.loadTrigger
            .flatMapLatest { [weak self] _ -> Observable<[PHAsset]> in
                guard let self = self else { return .empty() }
                return self.albumService.fetchPhotosFromAlbum()
                    .asObservable()
                    .catch { error in
                        print("加载相册失败: \(error.localizedDescription)")
                        return .just([])
                    }
            }
            .asDriver(onErrorJustReturn: [])
        
        // 处理选中的照片
        let selectedAssetDriver = input.selectPhotoTrigger
            .asDriver(onErrorJustReturn: PHAsset())
        
        // 获取相册名称
        let albumNameDriver = assetsDriver
            .map { assets -> String in
                return assets.isEmpty ? "相册".stLocalLized : "HY-Cam"
            }
            .asDriver(onErrorJustReturn: "相册".stLocalLized)
        
        return Output(
            assetsDriver: assetsDriver,
            selectedAssetDriver: selectedAssetDriver,
            albumNameDriver: albumNameDriver
        )
    }
}
