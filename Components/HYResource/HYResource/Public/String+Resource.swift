//
//  String+Resource.swift
//  HYResource
//
//  Created by Macintosh HD on 2025/1/27.
//

import Foundation

public extension String {
    public var stLocalLized: String {
        return self.localized(using: HYResource.languageTableName, in: HYResource.resourceBundle)
    }

}
