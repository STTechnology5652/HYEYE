//
//  HYWebVC.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/3/13.
//

import WebKit
import HYAllBase

class HYWebVC: HYBaseVC {
    private let url: URL
    private var webView: WKWebView!
    private var progressView: UIProgressView!
    private var observation: NSKeyValueObservation?
    
    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupProgressView()
        loadWebContent()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        view.addSubview(webView)
        
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 观察加载进度
        observation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, _ in
            self?.progressView.progress = Float(self?.webView.estimatedProgress ?? 0)
        }
    }
    
    private func setupProgressView() {
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = .blue
        view.addSubview(progressView)
        
        progressView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(2)
        }
    }
    
    private func loadWebContent() {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    deinit {
        observation?.invalidate()
    }
}

// MARK: - WKNavigationDelegate
extension HYWebVC: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
        // 是否需要我添加错误处理的 log？
    }
}
