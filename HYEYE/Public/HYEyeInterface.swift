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
    func firstFrameRendered(_ first: Bool)
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
            return "加载中..."
        case .loadfailed:
            return "加载失败"
        case .loaded:
            return "加载成功"
        case .playing:
            return "播放中..."
        case .stopped:
            return "已暂停"
        case .paused:
            return "已暂停"
        case .shutdown:
            return "已关闭"
        }
    }
}
