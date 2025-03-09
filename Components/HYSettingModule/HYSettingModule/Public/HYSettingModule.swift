//
//  HYSettingModule.swift
//  Pod
//
//  Created by defualt_author on 2025/02/09.
//
// @_exported import XXXXXX //这个是为了对外暴露下层依赖的Pod

@_exported import HYAllBase
@_exported import InAppSettingsKit

public class HYSettingModule {
    public static func showSettings(from viewController: UIViewController) {
        let settingVC = HYSettingVC()
        viewController.navigationController?.pushViewController(settingVC, animated: true)
    }
}
