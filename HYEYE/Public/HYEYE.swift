//
//  HYEYE.swift
//  Pod
//
//  Created by stephenchen on 2025/01/27.
//

@_exported import IJKMediaFramework
import IJKMediaFramework.IJKFFOptions
import Photos
import AVFoundation
import RxSwift
import RxCocoa


// MARK: - Public Methods
extension HYEYE: HYEYEInterface {
    public static func create() -> HYEYE {
        return HYEYE()
    }
    
    public func play() {
        guard let player else {
            print("HYEYE Error: player is nil")
            return
        }
        
        player.play()
    }
    
    public func stop() {
        guard let player else {
            print("HYEYE Error: player is nil")
            return
        }
        
        player.stop()
    }
    
    public func shutdown() {
        guard let player else { return }
        print("HYEYE: shutting down player")
        player.shutdown()
        self.player = nil
    }
    
    public func openVideo(url: URL, backView: UIView) {
        player?.shutdown()
        
        let newPlayer = HYPlayer(displayView: backView, url: url)
        self.player = newPlayer
        newPlayer.output.playerStateTtacer
            .subscribe { [weak self] state in
                self?.delegate?.playerStateDidChange(state)
            }
            .disposed(by: disposeBag)
        newPlayer.output.firstFrameRendered
            .subscribe { [weak self] in
                self?.delegate?.firstFrameRendered()
            }
            .disposed(by: disposeBag)
        
        newPlayer.output.recordVideoFinishTracker
            .subscribe { [weak self] (fileUrl: URL?) in
                guard let self else { return }
                self.delegate?.finishRecordVideo(isRecording: player?.isRecordingVodeo() ?? false, videoUrl: fileUrl)
            }
            .disposed(by: disposeBag)
    }
    
    public func playerState() -> HYEyePlayerState {
        guard let player else {
            return .shutdown
        }
        
        return player.output.playerStateTtacer.value ?? .shutdown
    }

    public func takePhoto() -> UIImage? {
        player?.takePhoto()
    }
    
    public var isRecordingVideo: Bool {
        guard let player else {
            print("HYEYE Error: player is nil")
            return false
        }
        
        return player.isRecordingVodeo()
    }
    
    public func recordVideo() -> Bool {
        guard let player else {
            print("HYEYE Error: player is nil")
            return false
        }
        
        if player.isRecordingVodeo() {
            return true
        }
        
        return player.recordVideo()
    }
    
    public func stopRecordVideo() {
        guard let player else {
            print("HYEYE Error: player is nil")
            return
        }
        
        player.stopRecordVideo()
    }
    
    public static func allVideoURLs() -> [URL] {
        return HYPlayer.allRecordedVideos()
    }
    
    public func showDebugView(show: Bool) {
        player?.showDebugView(show: show)
    }
}

public class HYEYE: NSObject {
    // MARK: - Interface
    public weak var delegate: HYEYEDelegate?
    
    // MARK: - Properties
    private var player: HYPlayer?
    private var disposeBag: DisposeBag = DisposeBag()
    
    // 添加状态信号
    public let playerStateRelay = BehaviorRelay<HYEyePlayerState>(value: .shutdown)
    
    // 更新 delegate 方法中的状态
    public func playerStateDidChange(_ state: HYEyePlayerState) {
        playerStateRelay.accept(state)
    }
}
