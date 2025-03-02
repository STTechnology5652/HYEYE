//
//  HYAlbumService.swift
//  HYPlayModule
//
//  Created by stephen Li on 2025/3/2.
//

import HYAllBase
import Photos
import RxSwift

protocol HYAlbumServiceInterface {
    /// 保存照片到相册
    func savePhoto(_ image: UIImage) -> Single<Bool>
    /// 保存照片到相册
    func savePhoto(_ photo: URL) -> Single<Bool>
    /// 获取相册中的照片
    func fetchPhotosFromAlbum() -> Single<[PHAsset]>
    /// 保存视频到相册
    func saveVideo(_ fileUrl: URL) -> Single<Bool>
}

final class HYAlbumService {
    // 相册名称
    private let albumName = "HY-Cam"
    private let disposeBag = DisposeBag()
    
    /// 请求相册权限
    private func requestPhotoLibraryAuthorization() -> Single<Bool> {
        return Single.create { single in
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    single(.success(true))
                } else {
                    single(.success(false))
                    print("相册权限未授权，当前状态: \(status)")
                }
            }
            return Disposables.create()
        }
    }
}

extension HYAlbumService: HYAlbumServiceInterface {
    func savePhoto(_ image: UIImage) -> Single<Bool> {
        return requestPhotoLibraryAuthorization()
            .flatMap { [weak self] authorized -> Single<Bool> in
                guard let self = self else {
                    return .error(NSError(domain: "PhotoLibraryError",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "self 已释放"]))
                }
                
                guard authorized else {
                    return .error(NSError(domain: "PhotoLibraryError",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "未获得相册权限"]))
                }
                
                return self.createAlbumIfNeeded()
                    .flatMap { album -> Single<Bool> in
                        return Single.create { single in
                            PHPhotoLibrary.shared().performChanges {
                                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                                guard let assetPlaceholder = request.placeholderForCreatedAsset,
                                      let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else {
                                    print("创建照片资源请求失败")
                                    single(.success(false))
                                    return
                                }
                                
                                albumChangeRequest.addAssets([assetPlaceholder] as NSFastEnumeration)
                            } completionHandler: { success, error in
                                if success {
                                    print("照片已成功保存到相册: \(self.albumName)")
                                    single(.success(true))
                                } else {
                                    print("保存照片失败: \(error?.localizedDescription ?? "未知错误")")
                                    single(.success(false))
                                }
                            }
                            return Disposables.create()
                        }
                    }
            }
    }
    
    func savePhoto(_ photo: URL) -> Single<Bool> {
        return requestPhotoLibraryAuthorization()
            .flatMap { [weak self] authorized -> Single<Bool> in
                guard let self = self else {
                    return .error(NSError(domain: "PhotoLibraryError",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "self 已释放"]))
                }
                
                guard authorized else {
                    return .error(NSError(domain: "PhotoLibraryError",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "未获得相册权限"]))
                }
                
                return self.createAlbumIfNeeded()
                    .flatMap { album -> Single<Bool> in
                        return Single.create { single in
                            PHPhotoLibrary.shared().performChanges {
                                guard let request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: photo),
                                      let assetPlaceholder = request.placeholderForCreatedAsset,
                                      let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else {
                                    print("创建照片资源请求失败")
                                    single(.success(false))
                                    return
                                }
                                
                                albumChangeRequest.addAssets([assetPlaceholder] as NSFastEnumeration)
                            } completionHandler: { success, error in
                                if success {
                                    print("照片已成功保存到相册: \(self.albumName)")
                                    single(.success(true))
                                } else {
                                    print("保存照片失败: \(error?.localizedDescription ?? "未知错误")")
                                    single(.success(false))
                                }
                            }
                            return Disposables.create()
                        }
                    }
            }
    }
    
    func createAlbumIfNeeded() -> Single<PHAssetCollection> {
        return Single.create { [weak self] single in
            guard let self = self else {
                return Disposables.create()
            }
            
            // 查找是否已存在相册
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", self.albumName)
            let collections = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                      subtype: .any,
                                                                      options: fetchOptions)
            
            if let existingCollection = collections.firstObject {
                print("找到已存在的相册: \(self.albumName)")
                single(.success(existingCollection))
            } else {
                // 创建新相册
                var collectionIdentifier: String?
                
                PHPhotoLibrary.shared().performChanges {
                    let createRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumName)
                    collectionIdentifier = createRequest.placeholderForCreatedAssetCollection.localIdentifier
                } completionHandler: { success, error in
                    if success, let identifier = collectionIdentifier {
                        let collection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier],
                                                                                 options: nil).firstObject
                        if let collection = collection {
                            print("成功创建新相册: \(self.albumName)")
                            single(.success(collection))
                        } else {
                            let error = NSError(domain: "AlbumError",
                                                code: -1,
                                                userInfo: [NSLocalizedDescriptionKey: "创建相册失败"])
                            print("创建相册失败: 无法获取新创建的相册")
                            single(.failure(error))
                        }
                    } else {
                        let finalError = error ?? NSError(domain: "AlbumError",
                                                          code: -1,
                                                          userInfo: [NSLocalizedDescriptionKey: "创建相册失败"])
                        print("创建相册失败: \(finalError.localizedDescription)")
                        single(.failure(finalError))
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func fetchPhotosFromAlbum() -> Single<[PHAsset]> {
        return createAlbumIfNeeded()
            .map { album -> [PHAsset] in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                
                let assetsFetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
                var assets: [PHAsset] = []
                
                assetsFetchResult.enumerateObjects { (asset, _, _) in
                    assets.append(asset)
                }
                
                print("从相册 \(self.albumName) 获取到 \(assets.count) 张照片")
                return assets
            }
    }
    
    func saveVideo(_ fileUrl: URL) -> Single<Bool> {
        return requestPhotoLibraryAuthorization()
            .flatMap { [weak self] authorized -> Single<Bool> in
                guard let self = self else {
                    return .error(NSError(domain: "PhotoLibraryError",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "self 已释放"]))
                }
                
                guard authorized else {
                    return .error(NSError(domain: "PhotoLibraryError",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "未获得相册权限"]))
                }
                
                return self.createAlbumIfNeeded()
                    .flatMap { album -> Single<Bool> in
                        return Single.create { single in
                            PHPhotoLibrary.shared().performChanges {
                                guard let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileUrl),
                                      let assetPlaceholder = request.placeholderForCreatedAsset,
                                      let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else {
                                    print("创建视频资源请求失败")
                                    single(.success(false))
                                    return
                                }
                                
                                albumChangeRequest.addAssets([assetPlaceholder] as NSFastEnumeration)
                            } completionHandler: { success, error in
                                if success {
                                    print("视频已成功保存到相册: \(self.albumName)")
                                    single(.success(true))
                                } else {
                                    print("保存视频失败: \(error?.localizedDescription ?? "未知错误")")
                                    single(.success(false))
                                }
                            }
                            return Disposables.create()
                        }
                    }
            }
    }
}
