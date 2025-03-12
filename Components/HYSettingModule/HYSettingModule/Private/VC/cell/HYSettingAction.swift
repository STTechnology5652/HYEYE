//
//  HYSettingAction.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/3/12.
//

import Foundation

protocol HYSettingActionInterface {
   func getSettingAction() -> HYSettingAction
}

enum HYSettingAction {
    case systemPrivacy
}
