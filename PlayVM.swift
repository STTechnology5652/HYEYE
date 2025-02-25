import Photos
import RxSwift
import RxCocoa

class PlayVM {
    private let disposeBag = DisposeBag()
    
    init() {
        // 订阅截图信号
        HYEYE.sharedInstance.capturedImage
            .subscribe(onNext: { [weak self] image in
                self?.saveImageToAlbum(image)
            })
            .disposed(by: disposeBag)
    }
    
    private func saveImageToAlbum(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("需要相册权限来保存图片")
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                request.creationDate = Date()
            }) { success, error in
                if success {
                    print("图片保存成功")
                } else if let error = error {
                    print("图片保存失败: \(error.localizedDescription)")
                }
            }
        }
    }
} 