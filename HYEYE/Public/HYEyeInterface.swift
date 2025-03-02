//
//  HYEyeState.swift
//  HYEYE
//
//  Created by stephen Li on 2025/3/1.
//

import Foundation

public protocol HYEYEInterface {
    associatedtype T
    static func create() -> T
    var delegate: HYEYEDelegate? { get set }
    
    func openVideo(url: URL, backView: UIView)
    func playerState() -> HYEyePlayerState
    func play()
    func stop()
    func shutdown()
    
    func takePhoto() -> UIImage?
    
    var isRecordingVideo: Bool { get }
    func recordVideo() -> Bool
    func stopRecordVideo()
    static func allVideoURLs() -> [URL]
    
    func showDebugView(show: Bool)
}

public protocol HYEYEDelegate: AnyObject {
    func playerStateDidChange(_ state: HYEyePlayerState)
    func firstFrameRendered()
    func finishRecordVideo(isRecording: Bool, videoUrl: URL?)
}

public enum HYEyePlayerState {
    case loading //默认占位
    case loadfailed
    case loaded
    case playing
    case stopped
    case paused
    case shutdown
    
    public var isPlayerNormal: Bool {
        switch self {
        case .loading, .loadfailed, .shutdown:
            return false
        default:
            return true
        }
    }
    
    public var stateDescription: String {
        switch self {
        case .loading:
            return "Loading ..."
        case .loadfailed:
            return "Load failed"
        case .loaded:
            return "Load success"
        case .playing:
            return "Playing"
        case .stopped:
            return "Stopped"
        case .paused:
            return "Stopped"
        case .shutdown:
            return "Closed"
        }
    }
}
