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
    public enum HYLanguage: String {
        case zh = "zh-Hans"
        case en = "en"
    }
    
    public static func setLanguage(_ lan: HYLanguage? = nil) {
        if let lan {
            Localize_Swift.Localize.setCurrentLanguage(lan.rawValue)
        }
        else {
            let defaultLan = Localize_Swift.Localize.defaultLanguage()
            Localize_Swift.Localize.setCurrentLanguage(defaultLan)
        }
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
