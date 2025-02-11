//
//  HYCommonConfig.swift
//  HYEYE_Pro
//
//  Created by stephen Li on 2025/2/11.
//

import Foundation

/*
 /* 远程主机 */

 #define REMOTE_HOST     @"192.168.1.1"
 #define REMOTE_PORT     7070

 // ----------------------------------------------------------------------------
 /* RTSP路径 */

 // RTSP文件路径
 #define RTSP_PATH(FILE) [NSString stringWithFormat:@"rtsp://%@:%d/%@", REMOTE_HOST, REMOTE_PORT, FILE]

 // ----------------------------------------------------------------------------
 /* 预览 */

 // 视频预览地址
 #define PREVIEW_ADDRESS    RTSP_PATH(@"webcam")
 */
fileprivate let kFilename: String = "webcam"
fileprivate let kHost: String = "192.168.1.1"
fileprivate let kPort: Int = 7070

struct HYCommonConfig {
    static let kPlayUrl = "rtsp://\(kHost):\(kPort)/\(kFilename)"
}
