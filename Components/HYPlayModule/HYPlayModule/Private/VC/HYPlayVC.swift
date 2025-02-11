//
//  HYPlayVC.swift
//  HYPlayModule
//
//  Created by stephen Li on 2025/2/9.
//

import HYAllBase

class HYPlayVC: HYBaseViewControllerMVVM {
    var vm: HYPlayVM = HYPlayVM()
    var disposeBag = DisposeBag()
    
    let playUrl: String?
    init(playUrl: String?) {
        self.playUrl = playUrl
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: input Replay
    private let openVideoTrigger: BehaviorRelay<(Bool, URL?)> = BehaviorRelay<(Bool, URL?)>(value: (false, nil))
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "HYPlayVC".stLocalLized
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let playUrl, let url = URL(string: playUrl) else { //toast
            return
        }
        
        openVideoTrigger.accept((true, url))
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        openVideoTrigger.accept((false, nil))
    }
    
    func setUpUI() {
        view.addSubview(btnPlay)
    }
    
    func bindData() {
        guard let input = createInput() else {
            
            return
        }
        
        let output = vm.transformInput(input)
        subscribeOutput(output)
    }
    
    // MARK: lazy properties
    private lazy var labPlayStatus: UILabel = {
        UILabel().then {
            $0.textColor = .black
            $0.font = .systemFont(ofSize: 14)
        }
    }()
    
    private lazy var btnPlay: UIButton = {
        UIButton(type: .custom).then {
            $0.setTitle("Play".stLocalLized, for: .normal)
            $0.setTitleColor(.black, for: .normal)
        }
    }()
}

// MARK: - MVVM methods
extension HYPlayVC {
    private func createInput() -> HYPlayVM.Input? {
        guard let url = URL(string: "https://www.baidu.com") else {
            return nil
        }
        
        btnPlay.rx.tap
            .bind(onNext: { [weak self] in
                let playing = self?.btnPlay.isSelected ?? true
                self?.openVideoTrigger.accept((playing == false, url))
            })
            .disposed(by: disposeBag)
        
        return HYPlayVM.Input(
            openVideoTrigger: openVideoTrigger
        )
    }
    
    private func subscribeOutput(_ outPut: HYPlayVM.Output) {
        outPut.videoCreate
            .drive(onNext: { [weak self] (playView) in
                guard let self, let playView else { return }
                view.insertSubview(playView, at: 0)
                playView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            })
            .disposed(by: disposeBag)
                
        
    }
}


// MARK: - UI methods
extension HYPlayVC {
    
}
