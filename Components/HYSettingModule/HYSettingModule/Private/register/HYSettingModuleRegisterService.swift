//
//  HYSettingModuleRegisterService.swift
//  HYSettingModule
//
//  Created by defualt_author on 2025/02/09.
//
import STModuleServiceSwift

private class HYSettingModuleRegisterService: NSObject, STModuleServiceRegisterProtocol {
    static func stModuleServiceRegistAction() {
        //注册服务 NSObject --> NSObjectProtocol   NSObjectProtocol为 swift 协议
//         STModuleService().stRegistModule(HYSettingModuleRegisterService.self, protocol: NSObjectProtocol.self, err: nil)
    }
}

// extension HYSettingModuleRegisterService: XXXXProtocol {
// static mehtod for XXXXProtocol
//     static func xxxxx() -> xxxxxObjc {
//         return XXXXX()
//     }
// }
