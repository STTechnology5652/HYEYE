//
//  HYResource.swift
//  Pod
//
//  Created by stephenchen on 2025/01/27.
//
// @_exported import XXXXXX //这个是为了对外暴露下层依赖的Pod

import Localize_Swift

public class HYResource: NSObject {}

extension HYResource {
    public enum HYLanguage: String, CaseIterable {
        case zhHans = "zh-Hans"
        case zh = "zh-Hant"
        case en = "en"
        
        public func displayName() -> String {
            return Localize.displayNameForLanguage(rawValue)
        }
        
        public func lanName() -> String {
            return rawValue.stLocalLized
        }
    }
    
    public static func loadDefaultLanguage() {
        if Localize_Swift.Localize.currentLanguage() == nil {
            setLanguage(.zh)
        }
    }
    
    public static func setLanguage(_ lan: HYLanguage? = nil) {
        if let lan {
            print("set language: \(lan.rawValue)")
            print("available language: \(Localize_Swift.Localize.availableLanguages())")
            Localize_Swift.Localize.setCurrentLanguage(lan.rawValue)
        }
        else {
            let defaultLan = Localize_Swift.Localize.defaultLanguage()
            Localize_Swift.Localize.setCurrentLanguage(defaultLan)
        }
    }
    
    public static func curLanguage() -> HYLanguage? {
        let currentLan = Localize_Swift.Localize.currentLanguage()
        return HYLanguage(rawValue: currentLan)
    }
    
    public static func appName() -> String {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "App"
    }
    
    public static func appVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    public static func appBuildVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    public static func appIcon() -> UIImage? {
        // 1. 从 Assets 获取
        if let image = UIImage(named: "AppIcon", in: Bundle.main, compatibleWith: nil) {
            return image
        }
        
        // 2. 尝试获取实际运行时的图标
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any] {
            
            // 2.1 尝试从 IconFiles 获取
            if let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
               let iconName = iconFiles.first,
               let image = UIImage(named: iconName, in: Bundle.main, compatibleWith: nil) {
                return image
            }
            
            // 2.2 尝试从 IconName 获取
            if let iconName = primaryIcon["CFBundleIconName"] as? String,
               let image = UIImage(named: iconName, in: Bundle.main, compatibleWith: nil) {
                return image
            }
        }
        
        // 3. 尝试直接从应用包获取
        if let iconsDictionary = Bundle.main.infoDictionary,
           let iconFiles = iconsDictionary["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon, in: Bundle.main, compatibleWith: nil)
        }
        
        return nil
    }
}

extension HYResource {
    static let languageTableName: String = "STLan"
    
    private static let cur_bundle = {
        let bundle = Bundle(for: HYResource.self)
        let result = bundle
        
        return result
    }()
    
    
    private static let resoutceBundleName = "HYResource"
    static let resourceBundle: Bundle = {
        guard let lanPath = cur_bundle.path(forResource: resoutceBundleName, ofType: "bundle"),
              let lanBundle = Bundle(path: lanPath)
        else {
            return Bundle.main
        }
        
        return lanBundle
    }()
}
