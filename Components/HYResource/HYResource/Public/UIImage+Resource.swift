//
//  UIImage+Resource.swift
//  HYResource
//
//  Created by Macintosh HD on 2025/1/27.
//

import UIKit

public extension UIImage {
    static func hyImage(name: String) -> UIImage? {
        let result = UIImage(named: name, in: HYResource.resourceBundle, compatibleWith: nil)
        return result
    }
}
