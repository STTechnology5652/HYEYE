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
    private var retryCount: Int = 0
    private let maxRetryCount: Int = 3
    
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
        guard let input = createInput() else {
            return
        }
        
        let output = vm.transformInput(input)
        subscribeOutput(output)
    }
    
    // MARK: - Private Methods
    private func startPlayback() {
        guard let playUrl = playUrl, 
              let url = URL(string: playUrl),
              player == nil else { return }
        
        if let newPlayer = HYEYE.openVideo(url: url) {
            // 1. 先设置视图
            let containerView = UIView(frame: view.bounds)
            containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            containerView.backgroundColor = .black
            view.insertSubview(containerView, at: 0)
            
            newPlayer.view.frame = containerView.bounds
            newPlayer.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            containerView.addSubview(newPlayer.view)
            
            // 2. 设置播放器和代理
            player = newPlayer
            HYEYE.sharedInstance.delegate = self
            
            // 3. 等待视图准备好再开始播放
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.player?.prepareToPlay()
            }
        }
    }
    
    private func stopPlayback() {
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

// MARK: - MVVM Methods
extension HYPlayVC {
    private func createInput() -> HYPlayVM.Input? {
        btnPlay.rx.tap
            .bind(onNext: { [weak self] in
                let playing = self?.btnPlay.isSelected ?? false
                if playing {
                    self?.stopPlayback()
                } else {
                    self?.startPlayback()
                }
            })
            .disposed(by: disposeBag)
        
        return HYPlayVM.Input(
            openVideoTrigger: vm.openVideoTrigger
        )
    }
    
    private func subscribeOutput(_ output: HYPlayVM.Output) {
        // 视频视图创建
        output.videoCreate
            .drive(onNext: { [weak self] playView in
                guard let self, let playView else { return }
                self.view.insertSubview(playView, at: 0)
                // 使用 frame 而不是约束
                playView.frame = self.view.bounds
                playView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            })
            .disposed(by: disposeBag)
        
        // 播放状态
        output.videoPlaying
            .drive(onNext: { [weak self] playing in
                self?.btnPlay.isSelected = playing
                self?.btnPlay.setTitle(playing ? "Stop".stLocalLized : "Play".stLocalLized, 
                                     for: .normal)
            })
            .disposed(by: disposeBag)
        
        // 播放开始状态
        output.videoPlayStart
            .drive(onNext: { [weak self] success in
                self?.labPlayStatus.text = success ? "Playing".stLocalLized : "Failed".stLocalLized
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UI methods
extension HYPlayVC {
    
}

// MARK: - HYEYEDelegate
extension HYPlayVC: HYEYEDelegate {
    func playbackStateDidChange(_ state: IJKMPMoviePlaybackState) {
        switch state {
        case .playing:
            btnPlay.isSelected = true
            labPlayStatus.text = "Playing".stLocalLized
        case .stopped:
            btnPlay.isSelected = false
            labPlayStatus.text = "Stopped".stLocalLized
        case .paused:
            btnPlay.isSelected = false
            labPlayStatus.text = "Paused".stLocalLized
        default:
            break
        }
    }
    
    func playbackDidFinishWithError(_ error: HYEYE.PlaybackError) {
        showError(error.description)
        retryCount += 1
        if retryCount < maxRetryCount {
            let delay = Double(retryCount) * 3.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.doReconnect()
            }
        }
    }
    
    func playbackDidPrepared() {
        player?.play()
    }
}
