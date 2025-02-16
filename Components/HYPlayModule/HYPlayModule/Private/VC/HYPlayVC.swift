//
//  HYPlayVC.swift
//  HYPlayModule
//
//  Created by stephen Li on 2025/2/9.
//

import HYAllBase
import HYEYE

class HYPlayVC: HYBaseViewControllerMVVM {
    // MARK: - Protocol Properties
    internal var vm: HYPlayVM = HYPlayVM()
    internal var disposeBag = DisposeBag()
    
    // MARK: - Private Properties
    private let playUrl: String?
    private var player: IJKFFMoviePlayerController?
    private var playerContainerView: UIView?
    
    // MARK: - Initialization
    init(playUrl: String?) {
        self.playUrl = playUrl
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "HYPlayVC".stLocalLized
        setUpUI()
        bindData()
    }
    
    override func viewDidLayoutSubviews() {
        player?.view.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if player == nil {
            startPlayback()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            stopPlayback()
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
    internal func setUpUI() {
        view.backgroundColor = .black
        view.addSubview(btnPlay)
        view.addSubview(labPlayStatus)
        
        btnPlay.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        labPlayStatus.snp.makeConstraints { make in
            make.top.equalTo(btnPlay.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
    }
    
    internal func bindData() {
        guard let input = createInput() else { return }
        let output = vm.transformInput(input)
        subscribeOutput(output)
    }
    
    private func createInput() -> HYPlayVM.Input? {
        // 播放按钮点击事件
        btnPlay.rx.tap
            .bind(onNext: { [weak self] in
                if self?.btnPlay.isSelected == true {
                    self?.stopPlayback()
                } else {
                    self?.startPlayback()
                }
            })
            .disposed(by: disposeBag)
        
        return HYPlayVM.Input(
            openVideoTrigger: vm.openVideoTrigger,
            playTrigger: vm.playTrigger,
            stopTrigger: vm.stopTrigger
        )
    }
    
    private func subscribeOutput(_ output: HYPlayVM.Output) {
        // 播放状态
        output.videoPlaying
            .drive(onNext: { [weak self] playing in
                self?.btnPlay.isSelected = playing
                self?.btnPlay.setTitle(playing ? "Stop".stLocalLized : "Play".stLocalLized, 
                                     for: .normal)
            })
            .disposed(by: disposeBag)
        
        // 播放状态文本
        output.playStatus
            .drive(labPlayStatus.rx.text)
            .disposed(by: disposeBag)
        
        // 错误处理
        output.error
            .drive(labPlayStatus.rx.text)
            .disposed(by: disposeBag)
        
        // 监听是否应该开始播放
        output.shouldPlay
            .drive(onNext: { [weak self] in
                self?.player?.play()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    private func startPlayback() {
        guard let playUrl = playUrl,
                let url = URL(string: playUrl) else {
            return
        }
        
        if let player {
            player.view.removeFromSuperview()
            player.shutdown()
            playerContainerView?.removeFromSuperview()
        }
        
        if let newPlayer = HYEYE.openVideo(url: url) {
            // 1. 先设置视图
            let containerView = UIView()
            containerView.backgroundColor = .black
            view.insertSubview(containerView, at: 0)
            playerContainerView = containerView
            containerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            // 设置播放器视图
            containerView.addSubview(newPlayer.view)
            newPlayer.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            // 2. 设置播放器
            player = newPlayer
            
            // 3. 触发播放事件
            vm.playTrigger.accept(())
            
            // 4. 等待视图准备好再开始播放
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.player?.prepareToPlay()
            }
        }
    }
    
    private func stopPlayback() {
        // 触发停止事件
        vm.stopTrigger.accept(())
        
        // 先移除通知监听
        NotificationCenter.default.removeObserver(self)
        
        // 停止播放
        player?.stop()
        
        // 移除视图 - 先获取父视图
        let containerView = player?.view.superview
        player?.view.removeFromSuperview()
        containerView?.removeFromSuperview()
        
        // 关闭播放器
        player?.shutdown()
        player = nil
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.labPlayStatus.text = message
            self?.btnPlay.isSelected = false
        }
    }
    
    private func doReconnect() {
        DispatchQueue.main.async { [weak self] in
            self?.stopPlayback()
            self?.startPlayback()
        }
    }
    
    // MARK: - Lazy Properties
    private lazy var labPlayStatus: UILabel = {
        UILabel().then {
            $0.textColor = .white
            $0.font = .systemFont(ofSize: 14)
            $0.textAlignment = .center
        }
    }()
    
    private lazy var btnPlay: UIButton = {
        UIButton(type: .custom).then {
            $0.setTitle("Play".stLocalLized, for: .normal)
            $0.setTitleColor(.white, for: .normal)
            $0.backgroundColor = .darkGray
            $0.layer.cornerRadius = 5
            $0.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        }
    }()
}

// MARK: - UI methods
extension HYPlayVC {
    
}
