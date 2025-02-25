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
    private let openVideoTrigger = PublishRelay<String?>()
    private let closeVideoTrigger = PublishRelay<Void>()
    private let playTrigger = PublishRelay<Void>()
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
        setUpUI()
        bindData()
        
        // 设置按钮事件
        btnPlay.rx.tap
            .subscribe(onNext: { [weak self] in
                if self?.player?.isPlaying() == true {
                    self?.stopTrigger.accept(())
                    self?.player?.stop()
                } else {
                    self?.playTrigger.accept(())
                    self?.player?.play()
                }
            })
            .disposed(by: disposeBag)
        
        btnPhoto.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.photoTrigger.accept(())
                if let image = self?.player?.thumbnailImageAtCurrentTime() {
                    HYEYE.sharedInstance.capturedImage.accept(image)
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if player == nil {
            openVideoTrigger.accept(playUrl)
        }
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
        output.player
            .drive(onNext: { [weak self] player in
                guard let self = self,
                      let player = player else { return }
                
                // 清理现有播放器
                if let oldPlayer = self.player {
                    oldPlayer.view.removeFromSuperview()
                    oldPlayer.shutdown()
                    self.playerContainerView?.removeFromSuperview()
                }
                
                // 创建容器视图
                let containerView = UIView()
                containerView.backgroundColor = .black
                self.view.insertSubview(containerView, at: 0)
                self.playerContainerView = containerView
                
                // 设置容器视图约束
                containerView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                
                // 添加播放器视图
                containerView.addSubview(player.view)
                player.view.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                
                self.player = player
                self.playTrigger.accept(())
                
                // 延迟准备播放
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    player.prepareToPlay()
                }
            })
            .disposed(by: disposeBag)
        
        output.videoPlaying
            .drive(btnPlay.rx.isSelected)
            .disposed(by: disposeBag)
        
        output.playStatus
            .drive(labPlayStatus.rx.text)
            .disposed(by: disposeBag)
        
        output.error
            .drive(onNext: { [weak self] errorMessage in
                self?.showErrorAlert(errorMessage)
            })
            .disposed(by: disposeBag)
        
        output.shouldPlay
            .drive(onNext: { [weak self] in
                self?.player?.play()
            })
            .disposed(by: disposeBag)
        
        output.isRecording
            .drive(recordButton.rx.isSelected)
            .disposed(by: disposeBag)
        
        output.recordingPath
            .drive(onNext: { [weak self] path in
                guard let path = path else { return }
                self?.showRecordingFinishedAlert(path: path)
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
    
    // MARK: - Private Methods
    private func startPlayback() {
        guard let playUrl = playUrl,
              let url = URL(string: playUrl) else { 
            print("HYEYE: 无效的播放URL")
            return 
        }
        
        // 清理现有播放器
        if let player = player {
            player.view.removeFromSuperview()
            player.shutdown()
            playerContainerView?.removeFromSuperview()
        }
        
        // 创建新的播放器
        if let newPlayer = HYEYE.openVideo(url: url) {
            // 创建容器视图
            let containerView = UIView()
            containerView.backgroundColor = .black
            view.insertSubview(containerView, at: 0) // 插入到最底层
            playerContainerView = containerView
            
            // 设置容器视图约束
            containerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            // 添加播放器视图
            containerView.addSubview(newPlayer.view)
            newPlayer.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            player = newPlayer
            playTrigger.accept(())
            
            // 延迟准备播放，确保视图已经布局完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.player?.prepareToPlay()
            }
        } else {
            print("HYEYE: 创建播放器失败")
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

// MARK: - UI methods
extension HYPlayVC {
    
}
