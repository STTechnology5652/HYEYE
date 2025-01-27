//
//  UIColor+Resource.swift
//  HYResource
//
//  Created by Macintosh HD on 2025/1/27.
//

import UIKit


public extension UIColor {
    public static let c_1F2937 = colorWithName("c_1F2937")
    
    public static let c_333333 = colorWithName("c_333333")
    
    public static var c_B45309 = colorWithName("c_B45309")
    
    public static var c_main = colorWithName("c_main")
    
    public static var c_theme_back = colorWithName("c_theme_back")
    
    public static var c_text = colorWithName("c_text")
    
    public static var c_text_warning = colorWithName("c_text_warning")
}

private extension UIColor {
    private static func colorWithName(_ name: String, defaultColor: UIColor = .red) -> UIColor {
        if #available(iOS 11.0, *) {
            let result = UIColor(named: name, in: HYResource.resourceBundle, compatibleWith: nil)
            
            return result ?? defaultColor
        } else {
            return defaultColor
        }
    }
    
}
