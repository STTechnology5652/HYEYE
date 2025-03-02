//
//  HYAlbumVC.swift
//  HYPlayModule
//
//  Created by stephen Li on 2025/3/2.
//

/*
 1. 打开 HY-Cam 相簿
 2. 夺取照片数组 PHAsset， 并用 collectionView 加载照片
 3. 点击一张图的时候， 弹出一个全屏的视图， 并显示大图
 */

import HYAllBase
import Photos
import AVFoundation

class HYAlbumVC: HYBaseViewControllerMVVM {
    var vm = HYAlbumVM()
    var disposeBag: DisposeBag = DisposeBag()
    
    // MARK: - Properties
    private let loadTrigger = PublishRelay<Void>()
    private let selectPhotoTrigger = PublishRelay<PHAsset>()
    
    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let itemWidth = (UIScreen.main.bounds.width - 4) / 3
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.register(HYAlbumCell.self, forCellWithReuseIdentifier: "HYAlbumCell")
        return collection
    }()
    
    private lazy var previewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.isHidden = true
        return view
    }()
    
    private lazy var previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "ico_close"), for: .normal)
        button.backgroundColor = .black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        return button
    }()
    
    // 添加视频播放器
    private lazy var playerView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    private var orientationObserver: NSObjectProtocol?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadTrigger.accept(())
    }
    
    override func updateBackgroundForOrientation() {
        super.updateBackgroundForOrientation()
        handleOrientationChange()
    }
    
    private func handleOrientationChange() {
        // 更新 collection view 布局
        updateCollectionViewLayout()
        
        // 更新预览视图布局
        if !previewContainer.isHidden {
            playerLayer?.frame = playerView.bounds
        }
    }
    
    private func updateCollectionViewLayout() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let isLandscape = screenWidth > screenHeight
        
        // 根据屏幕方向计算 item 大小
        let spacing: CGFloat = 1
        let columns: CGFloat = isLandscape ? 5 : 3
        let itemWidth = (screenWidth - (columns + 1) * spacing) / columns
        
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        
        // 强制布局更新
        layout.invalidateLayout()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { [weak self] _ in
            self?.handleOrientationChange()
        }
    }
    
    func setUpUI() {
        title = "相册".stLocalLized
        view.backgroundColor = .c_theme_back
        
        view.addSubview(collectionView)
        view.addSubview(previewContainer)
        previewContainer.addSubview(previewImageView)
        previewContainer.addSubview(playerView)  // 添加播放器视图
        previewContainer.addSubview(closeButton)
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        previewContainer.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        previewImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.right.equalTo(view.safeAreaLayoutGuide).offset(-16)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        // 添加手势
        let tapGesture = UITapGestureRecognizer()
        previewContainer.addGestureRecognizer(tapGesture)
        
        // 绑定关闭事件
        Observable.merge([
            tapGesture.rx.event.map { _ in () },
            closeButton.rx.tap.asObservable()
        ])
        .subscribe(onNext: { [weak self] in
            self?.hidePreview()
        })
        .disposed(by: disposeBag)
        
        // 初始化时设置布局
        updateCollectionViewLayout()
    }
    
    func bindData() {
        let input = HYAlbumVM.Input(
            loadTrigger: loadTrigger.asObservable(),
            selectPhotoTrigger: selectPhotoTrigger.asObservable()
        )
        
        let output = vm.transformInput(input)
        
        // 绑定相册名称到标题
        output.albumNameDriver
            .drive(onNext: { [weak self] name in
                self?.title = name
            })
            .disposed(by: disposeBag)
        
        // 绑定数据源
        output.assetsDriver
            .drive(collectionView.rx.items(cellIdentifier: "HYAlbumCell", cellType: HYAlbumCell.self)) { [weak self] (index, asset: PHAsset, cell: HYAlbumCell) in
                cell.configure(with: asset)
                
                // 绑定点击事件
                cell.tapSubject
                    .map { asset }
                    .bind(to: self?.selectPhotoTrigger ?? PublishRelay<PHAsset>())
                    .disposed(by: cell.disposeBag)
            }
            .disposed(by: disposeBag)
        
        // 处理照片选择
        output.selectedAssetDriver
            .drive(onNext: { [weak self] asset in
                self?.showPreview(with: asset)
            })
            .disposed(by: disposeBag)
    }
    
    private func showPreview(with asset: PHAsset) {
        previewContainer.isHidden = false
        previewContainer.alpha = 0
        
        if asset.mediaType == .video {
            // 显示视频
            showVideo(asset)
        } else {
            // 显示图片
            showImage(asset)
        }
        
        UIView.animate(withDuration: 0.25) {
            self.previewContainer.alpha = 1
        }
    }
    
    private func showVideo(_ asset: PHAsset) {
        previewImageView.isHidden = true
        playerView.isHidden = false
        
        // 请求视频资源
        PHImageManager.default().requestAVAsset(
            forVideo: asset,
            options: nil
        ) { [weak self] (avAsset, _, _) in
            DispatchQueue.main.async {
                guard let self = self,
                      let avAsset = avAsset else { return }
                
                // 创建播放器
                self.player = AVPlayer(playerItem: AVPlayerItem(asset: avAsset))
                
                // 创建播放器图层
                let playerLayer = AVPlayerLayer(player: self.player)
                playerLayer.videoGravity = .resizeAspect
                playerLayer.frame = self.playerView.bounds
                
                // 移除旧的图层
                self.playerLayer?.removeFromSuperlayer()
                self.playerLayer = playerLayer
                
                // 添加新的图层
                self.playerView.layer.addSublayer(playerLayer)
                
                // 开始播放
                self.player?.play()
            }
        }
    }
    
    private func showImage(_ asset: PHAsset) {
        previewImageView.isHidden = false
        playerView.isHidden = true
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, _ in
            guard let self = self, let image = image else { return }
            self.previewImageView.image = image
        }
    }
    
    private func hidePreview() {
        UIView.animate(withDuration: 0.25, animations: {
            self.previewContainer.alpha = 0
        }) { [weak self] _ in
            guard let self = self else { return }
            self.previewContainer.isHidden = true
            self.previewImageView.image = nil
            
            // 停止并清理播放器
            self.player?.pause()
            self.player = nil
            self.playerLayer?.removeFromSuperlayer()
            self.playerLayer = nil
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 更新播放器图层大小
        playerLayer?.frame = playerView.bounds
    }
}

// MARK: - Collection View Cell
class HYAlbumCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let videoIcon = UIImageView()
    private let videoDuration = UILabel()
    let tapSubject = PublishSubject<Void>()
    var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(videoIcon)
        contentView.addSubview(videoDuration)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        videoIcon.snp.makeConstraints { make in
            make.left.bottom.equalToSuperview().inset(5)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        
        videoDuration.snp.makeConstraints { make in
            make.left.equalTo(videoIcon.snp.right).offset(5)
            make.centerY.equalTo(videoIcon)
        }
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        videoIcon.image = UIImage(named: "ico_video_play")
        videoIcon.isHidden = true
        
        videoDuration.textColor = .white
        videoDuration.font = .systemFont(ofSize: 12)
        videoDuration.isHidden = true
        
        // 设置手势
        let tapGesture = UITapGestureRecognizer()
        contentView.addGestureRecognizer(tapGesture)
        
        tapGesture.rx.event
            .map { _ in () }
            .bind(to: tapSubject)
            .disposed(by: disposeBag)
    }
    
    func configure(with asset: PHAsset) {
        // 请求图片
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, _ in
            self?.imageView.image = image
        }
        
        // 显示视频信息
        if asset.mediaType == .video {
            videoIcon.isHidden = false
            videoDuration.isHidden = false
            videoDuration.text = formatDuration(asset.duration)
            
            // 设置视频图标和时长的位置
            videoIcon.snp.remakeConstraints { make in
                make.right.bottom.equalToSuperview().inset(5)
                make.size.equalTo(CGSize(width: 20, height: 20))
            }
            
            videoDuration.snp.remakeConstraints { make in
                make.right.equalTo(videoIcon.snp.left).offset(-5)
                make.centerY.equalTo(videoIcon)
            }
        } else {
            videoIcon.isHidden = true
            videoDuration.isHidden = true
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
