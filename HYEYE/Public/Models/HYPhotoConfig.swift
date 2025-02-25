public struct HYPhotoConfig {
    /// 每隔多少帧存储一次
    public let frameInterval: Int
    /// 需要存储的总帧数
    public let targetFrameCount: Int
    /// 存储路径，nil 则存储到相册
    public let savePath: String?
    /// 图片质量 (0.0-1.0)
    public let imageQuality: Float
    /// 是否保存原始数据
    public let saveOriginalData: Bool
    
    public init(frameInterval: Int = 5,
                targetFrameCount: Int = 100,
                savePath: String? = nil,
                imageQuality: Float = 1.0,
                saveOriginalData: Bool = false) {
        self.frameInterval = max(1, frameInterval)  // 最小间隔1帧
        self.targetFrameCount = max(1, targetFrameCount)  // 最少1帧
        self.savePath = savePath
        self.imageQuality = min(1.0, max(0.0, imageQuality))  // 限制在0.0-1.0之间
        self.saveOriginalData = saveOriginalData
    }
} 
