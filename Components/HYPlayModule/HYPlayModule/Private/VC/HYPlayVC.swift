//
//  HYPlayVC.swift
//  HYPlayModule
//
//  Created by stephen Li on 2025/2/9.
//

import HYAllBase
import HYEYE

class HYPlayVC: HYBaseViewControllerMVVM {
    // MARK: - Protocol Conformance
    var viewModel: ViewModelType { return vm }
    
    // MARK: - Properties
    internal var vm: HYPlayVM = HYPlayVM()
    internal var disposeBag = DisposeBag()
    
    private let playUrl: String?
    private var player: IJKFFMoviePlayerController?
    private var playerContainerView: UIView?
    
    // 触发器
    private let openVideoTrigger = PublishRelay<(String?, UIView)>()
    private let closeVideoTrigger = PublishRelay<Void>()
    private let playTrigger = PublishRelay<Void>()
    private let prepareToPlayTrigger = PublishRelay<Void>()
    private let stopTrigger = PublishRelay<Void>()
    private let photoTrigger = PublishRelay<Void>()
    
    // MARK: - UI Components
    private lazy var controlsView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [btnPlay, btnPhoto, recordButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var labPlayStatus: UILabel = {
        UILabel().then {
            $0.textColor = .white
            $0.font = .systemFont(ofSize: 14)
            $0.textAlignment = .center
        }
    }()
    
    private lazy var btnPlay = UIButton(type: .custom).then {
        $0.setTitle("Play", for: .normal)
        $0.setTitle("Stop", for: .selected)
        $0.backgroundColor = .darkGray
        $0.layer.cornerRadius = 5
    }
    
    private lazy var btnPhoto = UIButton(type: .custom).then {
        $0.setTitle("Photo", for: .normal)
        $0.backgroundColor = .darkGray
        $0.layer.cornerRadius = 5
    }
    
    private lazy var recordButton = UIButton(type: .custom).then {
        $0.setTitle("Record", for: .normal)
        $0.setTitle("Recording...", for: .selected)
        $0.backgroundColor = .darkGray
        $0.layer.cornerRadius = 5
    }
    
    // MARK: - Lifecycle
    init(playUrl: String?) {
        self.playUrl = playUrl
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        
        // 设置按钮事件
        btnPlay.rx.tap
            .subscribe(onNext: { [weak self] in
                if self?.player?.isPlaying() == true {
                    self?.stopTrigger.accept(())
                } else {
                    self?.playTrigger.accept(())
                }
            })
            .disposed(by: disposeBag)
        
        openVideoTrigger.accept((playUrl, view))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playTrigger.accept(())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            closeVideoTrigger.accept(())
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    deinit {
        print("HYPlayVC deinit")
        stopPlayback()
    }
    
    // MARK: - Protocol Methods
    func bindData() {
        print("bindData")
        let input = HYPlayVM.HYPlayVMInput(
            openVideoUrl: openVideoTrigger.asObservable(),
            closeVideo: closeVideoTrigger.asObservable(),
            playTrigger: playTrigger.asObservable(),
            stopTrigger: stopTrigger.asObservable(),
            photoTrigger: photoTrigger.asObservable(),
            recordTrigger: recordButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transformInput(input)
        
        // 处理播放器
        output.playStateReplay
            .drive(onNext: { [weak self] state in
                if state == .playing {
                    
                }
            })
            .disposed(by: disposeBag)
    }
    
    func setUpUI() {
        view.backgroundColor = .black
        
        view.addSubview(controlsView)
        view.addSubview(labPlayStatus)
        
        controlsView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(120)
        }
        
        labPlayStatus.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
            make.centerX.equalToSuperview()
        }
    }
    
    private func stopPlayback() {
        stopTrigger.accept(())
        NotificationCenter.default.removeObserver(self)
        player?.stop()
        
        let containerView = player?.view.superview
        player?.view.removeFromSuperview()
        containerView?.removeFromSuperview()
        
        player?.shutdown()
        player = nil
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
}
