//
//  HYPlayModuleRegisterService.swift
//  HYPlayModule
//
//  Created by defualt_author on 2025/02/09.
//
import STModuleServiceSwift

private class HYPlayModuleRegisterService: NSObject, STModuleServiceRegisterProtocol {
    static func stModuleServiceRegistAction() {
        //注册服务 NSObject --> NSObjectProtocol   NSObjectProtocol为 swift 协议
//         STModuleService().stRegistModule(HYPlayModuleRegisterService.self, protocol: NSObjectProtocol.self, err: nil)
    }
}

// extension HYPlayModuleRegisterService: XXXXProtocol {
// static mehtod for XXXXProtocol
//     static func xxxxx() -> xxxxxObjc {
//         return XXXXX()
//     }
// }
