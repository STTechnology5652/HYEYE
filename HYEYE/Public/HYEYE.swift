//
//  HYEYE.swift
//  Pod
//
//  Created by stephenchen on 2025/01/27.
//

@_exported import IJKMediaFramework
//@_exported import IJKMediaFramework.IJKFFMoviePlayerController

public protocol HYEYEProtocol {
    static func openVideo(url: URL) -> IJKFFMoviePlayerController?
}

public class HYEYE {}

extension HYEYE: HYEYEProtocol {
    public static func openVideo(url: URL) -> IJKFFMoviePlayerController? {
        return openVideoExec(url: url)
    }
}

private extension HYEYE {
    private static func openVideoExec(url: URL) -> IJKFFMoviePlayerController? {
        /*
         {
             IJKFFOptions *options = [IJKFFOptions optionsByDefault];
             [options setPlayerOptionIntValue:RtpJpegParsePacketMethodDrop forKey:@"rtp-jpeg-parse-packet-method"];
             [options setPlayerOptionIntValue:0 forKey:@"videotoolbox"];
             [options setPlayerOptionIntValue:5000 * 1000 forKey:@"readtimeout"]; // read packet timeout
             // Image type
             [options setPlayerOptionIntValue:PreferredImageTypeJPEG forKey:@"preferred-image-type"];
             // Image quality, available for lossy format (min and max are both from 1 to 51, 0 < min <= max, smaller is better, default is 2 and 31)
             [options setPlayerOptionIntValue:1 forKey:@"image-quality-min"];
             [options setPlayerOptionIntValue:1 forKey:@"image-quality-max"];
             // video
             [options setPlayerOptionIntValue:PreferredVideoTypeH264     forKey:@"preferred-video-type"];
             [options setPlayerOptionIntValue:1                          forKey:@"video-need-transcoding"];
             [options setPlayerOptionIntValue:MjpegPixFmtYUVJ420P        forKey:@"mjpeg-pix-fmt"];
             // Video quality, for MJPEG and MPEG4
             [options setPlayerOptionIntValue:2                          forKey:@"video-quality-min"];
             [options setPlayerOptionIntValue:20                         forKey:@"video-quality-max"];
             // x264 preset, tune and profile, for H264
             [options setPlayerOptionIntValue:X264OptionPresetUltrafast  forKey:@"x264-option-preset"];
             [options setPlayerOptionIntValue:X264OptionTuneZerolatency  forKey:@"x264-option-tune"];
             [options setPlayerOptionIntValue:X264OptionProfileMain      forKey:@"x264-option-profile"];
             [options setPlayerOptionValue:@"crf=23"                     forKey:@"x264-params"];
             // 录像时自动丢帧
             [options setPlayerOptionIntValue:3 forKey:@"auto-drop-record-frame"];
             // 检测到小错误就停止当前帧解码，避免图像异常
             [options setCodecOptionValue:@"explode" forKey:@"err_detect"];
             
             IJKFFMoviePlayerController *moviePlayerController = [[IJKFFMoviePlayerController alloc] initWithContentURL:self.url withOptions:options];
             moviePlayerController.delegate = self;

             self.player = moviePlayerController;
             self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
             self.player.view.frame = self.view.bounds;
             self.player.scalingMode = IJKMPMovieScalingModeFill;
             self.player.shouldAutoplay = YES;
             
             self.view.autoresizesSubviews = YES;
             [self.view insertSubview:self.player.view aboveSubview:self.backgroundImageView];

             // put log setting here to make it fresh
         #ifdef DEBUG
             [IJKFFMoviePlayerController setLogReport:YES];
             [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
         #else
             [IJKFFMoviePlayerController setLogReport:NO];
             [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_SILENT];
         #endif

             // [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
             // [IJKFFMoviePlayerController checkIfPlayerVersionMatch:YES major:1 minor:0 micro:0];
         }
         */
        var options = IJKFFOptions.byDefault()
        if let options {
            /*
             [options setPlayerOptionIntValue:RtpJpegParsePacketMethodDrop forKey:@"rtp-jpeg-parse-packet-method"];
             [options setPlayerOptionIntValue:0 forKey:@"videotoolbox"];
             [options setPlayerOptionIntValue:5000 * 1000 forKey:@"readtimeout"]; // read packet timeout
             // Image type
             [options setPlayerOptionIntValue:PreferredImageTypeJPEG forKey:@"preferred-image-type"];
             // Image quality, available for lossy format (min and max are both from 1 to 51, 0 < min <= max, smaller is better, default is 2 and 31)
             [options setPlayerOptionIntValue:1 forKey:@"image-quality-min"];
             [options setPlayerOptionIntValue:1 forKey:@"image-quality-max"];
             // video
             [options setPlayerOptionIntValue:PreferredVideoTypeH264     forKey:@"preferred-video-type"];
             [options setPlayerOptionIntValue:1                          forKey:@"video-need-transcoding"];
             [options setPlayerOptionIntValue:MjpegPixFmtYUVJ420P        forKey:@"mjpeg-pix-fmt"];
             // Video quality, for MJPEG and MPEG4
             [options setPlayerOptionIntValue:2                          forKey:@"video-quality-min"];
             [options setPlayerOptionIntValue:20                         forKey:@"video-quality-max"];
             // x264 preset, tune and profile, for H264
             [options setPlayerOptionIntValue:X264OptionPresetUltrafast  forKey:@"x264-option-preset"];
             [options setPlayerOptionIntValue:X264OptionTuneZerolatency  forKey:@"x264-option-tune"];
             [options setPlayerOptionIntValue:X264OptionProfileMain      forKey:@"x264-option-profile"];
             [options setPlayerOptionValue:@"crf=23"                     forKey:@"x264-params"];
             // 录像时自动丢帧
             [options setPlayerOptionIntValue:3 forKey:@"auto-drop-record-frame"];
             // 检测到小错误就停止当前帧解码，避免图像异常
             [options setCodecOptionValue:@"explode" forKey:@"err_detect"];
             */
            
            options.setPlayerOptionIntValue(RtpJpegParsePacketMethodDro.rawValue, forKey: "videotoolbox")
            options.setPlayerOptionIntValue(0, forKey: "videotoolbox")
            options.setPlayerOptionIntValue(5000 * 1000, forKey: "readtimeout")
        }
        let player = IJKFFMoviePlayerController(contentURL: url, with: options)
        return player
    }
}
