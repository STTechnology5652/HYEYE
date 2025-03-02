//
//  HYPlayVC.swift
//  HYPlayModule
//
//  Created by stephen Li on 2025/2/9.
//

import HYAllBase
import HYEYE

extension HYPlayVC {
    // MARK: - Protocol Methods
    func bindData() {
        print("bindData")
        let input = HYPlayVM.HYPlayVMInput(
            openVideoUrl: openVideoTrigger.asObservable(),
            closeVideo: closeVideoTrigger.asObservable(),
            playerStateChange: playStateChangeTrigger.asObservable(),
            stopTrigger: playeStopTrigger.asObservable(),
            photoTrigger: btnPhoto.rx.tap.asObservable(),
            recordTrigger: recordButton.rx.tap.asObservable()
        )
        
        // 设置按钮事件
        btnPlay.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.playStateChangeTrigger.accept(())
            })
            .disposed(by: disposeBag)
        
        btnRotate.rx.tap
            .bind(onNext: { [weak self] in
                self?.rotateToNextOrientation()
            })
            .disposed(by: disposeBag)
        
        btnControlPan.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }
                self.stSetNavigationBarHidden(false)
                UIView.animate(withDuration: 0.25) {
                    self.btnControlBack.alpha = 1
                }
            })
            .disposed(by: disposeBag)
        
        btnControlBack.rx.tap
            .bind(onNext: { [weak self] in
                self?.playControlsHideTrigger.accept(())
            })
            .disposed(by: disposeBag)
        
        playControlsHideTrigger
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.stSetNavigationBarHidden(true)
                UIView.animate(withDuration: 0.25) {
                    self.btnControlBack.alpha = 0
                }
            })
            .disposed(by: disposeBag)

        let output = viewModel.transformInput(input)
        
        // 处理播放器状态
        output.playStateReplay
            .map { $0.stateDescription.localized() }
            .drive(labPlayStatus.rx.text)
            .disposed(by: disposeBag)

        output.playStateReplay
            .map { $0 == .playing }
            .drive(onNext: { [weak self] isPlaying in
                self?.btnPlay.isSelected = isPlaying
            })
            .disposed(by: disposeBag)
        
        output.playStateReplay
            .map { state in
                (state.isPlayerNormal, state == .playing, state == .loadfailed)
            }
            .drive(onNext: { [weak self] (isEnabled, isPlaying, isPrepareFailed) in
                self?.btnPlay.isEnabled = isEnabled
                if isPrepareFailed {
                    self?.btnPlay.isEnabled = true
                    self?.btnPlay.isSelected = false
                }
                
                self?.btnPhoto.isEnabled = isPlaying
                self?.recordButton.isEnabled = isPlaying
            })
            .disposed(by: disposeBag)
        
        output.takePhotoTracer
            .drive { [weak self] (image: UIImage?) in
                guard let image, let self else { return }
                self.imgPhoto.image = image
            }
            .disposed(by: disposeBag)
        
        // 录制状态绑定
        output.recordVideoTracer
            .map { $0.0 }  // 获取录制状态
            .drive(recordButton.rx.isSelected)
            .disposed(by: disposeBag)
        
        // 录制完成处理
        output.recordVideoTracer
            .compactMap { $0.1 }  // 只保留非空的 URL
            .map { $0.path }      // 获取路径
            .drive(onNext: { [weak self] path in
                self?.showRecordingFinishedAlert(path: path)
            })
            .disposed(by: disposeBag)
        
        output.needPhotoPermisionTracer
            .drive(onNext: { [weak self] needRequest in
                guard let self, needRequest else { return }
                
                let alert = UIAlertController(
                    title: "需要相册权限".stLocalLized,
                    message: "请在设置中允许访问相册，以保存照片和视频".stLocalLized,
                    preferredStyle: .alert
                )
                // 取消按钮
                alert.addAction(UIAlertAction(
                    title: "取消".stLocalLized,
                    style: .cancel
                ))
                
                // 去设置按钮
                alert.addAction(UIAlertAction(
                    title: "去设置".stLocalLized,
                    style: .default,
                    handler: { _ in
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                              UIApplication.shared.canOpenURL(settingsUrl) else {
                            return
                        }
                        UIApplication.shared.open(settingsUrl)
                    }
                ))
                
                self.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
        
        output.firstFrameRenderedTracer
            .drive(onNext: { [weak self] isFirstResponder in
                if isFirstResponder {
                    self?.playControlsHideTrigger.accept(())
                }
            })
            .disposed(by: disposeBag)
    }
    
    func setUpUI() {
        hideBackIconImage(true) //隐藏页面默认的 app logo
        hyBackImg = nil //隐藏页面默认背景图
        view.backgroundColor = .c_theme_back
        
        view.addSubview(playerContainerView)
        view.addSubview(btnControlPan)
        view.addSubview(btnControlBack)
        btnControlBack.addSubview(controlsView)
        btnControlBack.addSubview(labPlayStatus)
        btnControlBack.addSubview(imgPhoto)
        
        btnControlPan.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        btnControlBack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playerContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        controlsView.snp.makeConstraints { make in
            make.bottom.equalTo(btnControlBack.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.width.lessThanOrEqualToSuperview().offset(-40)
            make.centerX.equalToSuperview()
        }
        
        imgPhoto.snp.makeConstraints { make in
            make.left.equalTo(btnControlBack.safeAreaLayoutGuide.snp.left).offset(20)
            make.bottom.equalTo(controlsView.snp.top).offset(-10)
            make.size.equalTo(CGSize(width: 80, height: 80))
        }
        
        labPlayStatus.snp.makeConstraints { make in
            make.bottom.equalTo(imgPhoto.snp.bottom)
            make.centerX.equalTo(controlsView)
            make.left.greaterThanOrEqualTo(imgPhoto.snp.right).offset(5)
            make.right.lessThanOrEqualTo(btnControlBack.snp.right).offset(-20)
        }
    }
}

class HYPlayVC: HYBaseViewControllerMVVM {
    // MARK: - Protocol Conformance
    var viewModel: ViewModelType { return vm }
    
    // MARK: - Properties
    internal var vm: HYPlayVM = HYPlayVM()
    internal var disposeBag = DisposeBag()
    
    private let playUrl: String?
    // 触发器
    private let openVideoTrigger = PublishRelay<(String?, UIView)>()
    private let closeVideoTrigger = PublishRelay<Void>()
    private let playStateChangeTrigger = PublishRelay<Void>()
    private let playeStopTrigger = PublishRelay<Void>()
    private let playControlsHideTrigger = PublishRelay<Void>()
    
    private var currentOrientation: UIInterfaceOrientation = .portrait
    
    // MARK: - UI Components
    private lazy var playerContainerView: UIView = {
        UIView()
    }()
    
    private lazy var controlsView: UIStackView = {
        let controlBtnArr = [btnPlay, btnPhoto, recordButton, btnRotate]
        let stack = UIStackView(arrangedSubviews: controlBtnArr)
        stack.axis = .horizontal
        stack.spacing = 10
        
        controlBtnArr.forEach { button in
            button.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 40, height: 40))
            }
        }
        
        return stack
    }()
    
    private lazy var labPlayStatus: UILabel = {
        UILabel().then {
            $0.textColor = .c_text_warning
            $0.font = .systemFont(ofSize: 15)
            $0.textAlignment = .center
        }
    }()
    
    private lazy var imgPhoto: UIImageView = {
        UIImageView().then {
            $0.layer.cornerRadius = 5
            $0.backgroundColor = .lightGray
        }
    }()
    
    private lazy var btnPlay = UIButton(type: .custom).then {
        $0.setBackgroundImage(UIImage.hyImage(name: "ico_play")?.applyingAlpha(0.5), for: .disabled)
        $0.setBackgroundImage(UIImage.hyImage(name: "ico_play"), for: .normal)
        $0.setBackgroundImage(UIImage.hyImage(name: "ico_stop"), for: .selected)
        $0.backgroundColor = .darkGray
        $0.layer.cornerRadius = 5
        $0.layer.masksToBounds = true
    }
    
    private lazy var btnPhoto = UIButton(type: .custom).then {
        $0.setBackgroundImage(UIImage.hyImage(name: "ico_photo"), for: .normal)
        $0.setBackgroundImage(UIImage.hyImage(name: "ico_photo")?.applyingAlpha(0.5), for: .disabled)
        $0.backgroundColor = .darkGray
        $0.layer.cornerRadius = 5
    }
    
    private lazy var recordButton = UIButton(type: .custom).then {
        $0.setBackgroundImage(UIImage.hyImage(name: "ico_video"), for: .normal)
        $0.setBackgroundImage(UIImage.hyImage(name: "ico_video")?.applyingAlpha(0.5), for: .disabled)
        $0.setBackgroundImage(UIImage.hyImage(name: "ico_video_taped"), for: .selected)
        $0.backgroundColor = .darkGray
        $0.layer.cornerRadius = 5
    }
    
    private lazy var btnRotate = UIButton(type: .custom).then {
        $0.setImage(UIImage.hyImage(name: "ico_phone_rotate"), for: .normal)
        $0.backgroundColor = .darkGray
        $0.layer.cornerRadius = 5
    }
    
    private lazy var btnControlPan: UIButton = {
        UIButton().then {
            $0.backgroundColor = .clear
        }
    }()
    
    private lazy var btnControlBack: UIButton = {
        UIButton().then {
            $0.backgroundColor = .clear
        }
    }()
    
    // MARK: - Lifecycle
    init(playUrl: String?) {
        self.playUrl = playUrl
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        title = "视频预览".stLocalLized
            
        openVideoTrigger.accept((playUrl, playerContainerView))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            closeVideoTrigger.accept(())
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .landscapeLeft, .landscapeRight]
    }
    
    deinit {
        print("HYPlayVC deinit")
    }
    
    private func stopPlayback() {
        playeStopTrigger.accept(())
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(
            title: "错误".stLocalLized,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定".stLocalLized, style: .default))
        present(alert, animated: true)
    }
    
    private func showRecordingFinishedAlert(path: String) {
        let alert = UIAlertController(
            title: "Recording Finished",
            message: "Video saved to:\n\(path)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func rotateToNextOrientation() {
        let nextOrientation: UIInterfaceOrientation
        
        switch currentOrientation {
        case .portrait:
            nextOrientation = .landscapeRight
        case .landscapeRight:
            nextOrientation = .landscapeLeft
        case .landscapeLeft:
            nextOrientation = .portrait
        default:
            nextOrientation = .portrait
        }
        
        currentOrientation = nextOrientation
        
        if #available(iOS 16.0, *) {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let orientation: UIInterfaceOrientationMask = switch nextOrientation {
                case .portrait: .portrait
                case .landscapeLeft: .landscapeLeft
                case .landscapeRight: .landscapeRight
                default: .portrait
            }
            windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
        } else {
            UIDevice.current.setValue(nextOrientation.rawValue, forKey: "orientation")
        }
    }
}
