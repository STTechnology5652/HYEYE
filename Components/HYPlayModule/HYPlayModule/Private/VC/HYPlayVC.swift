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
                self?.btnControlBack.isHidden = false
                self?.stSetNavigationBarHidden(false)
            })
            .disposed(by: disposeBag)
        
        btnControlBack.rx.tap
            .bind(onNext: { [weak self] in
                self?.playControlsHideTrigger.accept(())
            })
            .disposed(by: disposeBag)
        
        playControlsHideTrigger
            .subscribe(onNext: { [weak self] in
                self?.btnControlBack.isHidden = true
                self?.stSetNavigationBarHidden(true)
            })
            .disposed(by: disposeBag)

        let output = viewModel.transformInput(input)
        
        // 处理播放器状态
        output.playStateReplay
            .map { $0.stateDescription }
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
                (state.isPlayerNormal, state == .loadfailed)
            }
            .drive(onNext: { [weak self] (isEnabled, shouldRetry) in
                self?.btnPlay.isEnabled = isEnabled
                if shouldRetry {
                    self?.btnPlay.isEnabled = true
                    self?.btnPlay.isSelected = false
                }
                self?.btnPhoto.isEnabled = isEnabled
                self?.recordButton.isEnabled = isEnabled
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
    }
    
    func setUpUI() {
        view.backgroundColor = .black
        
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
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(120)
        }
        
        imgPhoto.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.bottom.equalToSuperview().offset(-20)
            make.size.equalTo(CGSize(width: 80, height: 80))
        }
        
        labPlayStatus.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
            make.left.equalTo(imgPhoto.snp.right).offset(5)
            make.right.equalTo(-20)
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
        let stack = UIStackView(arrangedSubviews: [btnPlay, btnPhoto, recordButton, btnRotate])
        stack.axis = .vertical
        stack.spacing = 20
        stack.distribution = .fillEqually
        
        [btnPlay, btnPhoto, recordButton].forEach { button in
            button.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 100, height: 30))
            }
        }
        
        return stack
    }()
    
    private lazy var labPlayStatus: UILabel = {
        UILabel().then {
            $0.textColor = .red
            $0.font = .systemFont(ofSize: 14)
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
        $0.setTitle("Prepare ...", for: .disabled)
        $0.setTitle( "Play", for: .normal)
        $0.setTitle( "Stop", for: .selected)
        $0.setBackgroundImage(UIImage(color: .green), for: .normal)
        $0.setBackgroundImage(UIImage(color: .green.withAlphaComponent(0.5)), for: .disabled)
        $0.backgroundColor = .darkGray
        $0.layer.cornerRadius = 5
        $0.layer.masksToBounds = true
    }
    
    private lazy var btnPhoto = UIButton(type: .custom).then {
        $0.setTitle("Photo", for: .normal)
        $0.setBackgroundImage(UIImage(color: .green.withAlphaComponent(0.5)), for: .disabled)
        $0.backgroundColor = .darkGray
        $0.layer.cornerRadius = 5
    }
    
    private lazy var recordButton = UIButton(type: .custom).then {
        $0.setTitle("Record", for: .normal)
        $0.setTitle("Recording...", for: .selected)
        $0.setBackgroundImage(UIImage(color: .green.withAlphaComponent(0.5)), for: .disabled)
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
        hyBackImg = nil
        title = "视频预览".localized()
            
        openVideoTrigger.accept((playUrl, playerContainerView))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in //1s后自动隐藏控制面板
            guard let self else { return }
            self.playControlsHideTrigger.accept(())
        }
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
