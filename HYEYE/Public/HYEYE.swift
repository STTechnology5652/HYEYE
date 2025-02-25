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

public protocol HYEYEProtocol {
    func openVideo(url: URL, backView: UIView)
}

public enum HYEyePlayerState {
    case loaded
    case playing
    case paused
    case stopped
    case shutdown
}

public protocol HYEYEDelegate: AnyObject {
    func playerStateDidChange(_ state: HYEyePlayerState)
    func playerLoadFinished(success: Bool)
}

public class HYEYE: NSObject, HYEYEProtocol {
    // MARK: - Properties
    public static let sharedInstance = HYEYE()
    public weak var delegate: HYEYEDelegate?
    private var player: HYPlayer?
    
    // MARK: - Public Methods
    public func play() {
        guard let player else {
            print("HYEYE Error: player is nil")
            return
        }
        
        player.play()
        
    }
    
    public func pause() {
        guard let player else { return }
        print("HYEYE: stopping playback")
        
        // 先暂停播放
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
    }
    
    // 截图方法
    public func takeSnapshot() -> UIImage? {
        return UIImage()
    }
}
