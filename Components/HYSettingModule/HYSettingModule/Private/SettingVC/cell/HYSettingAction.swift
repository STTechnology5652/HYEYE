//
//  HYSettingAction.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/3/12.
//

import Foundation

protocol HYSettingActionInterface {
    var settingAction: HYSettingAction { get }
}

enum HYSettingAction {
    case systemPrivacy
    case setLanguage
}
