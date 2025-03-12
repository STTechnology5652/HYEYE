//
//  AppDelegate.swift
//  HYEYE_Pro
//
//  Created by stephenchen on 2025/01/27.
//

import UIKit
import HYBaseUI
import HYResource
import MTCategoryComponent.UIViewController_MTFindViewController

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        HYResource.loadDefaultLanguage()
        let win = UIWindow.init(frame: UIScreen.main.bounds)
        win.backgroundColor = UIColor.white
        self.window = win
        
        
        let tab = UITabBarController()
        var arr: [UIViewController] = [UIViewController]()
        do{
            let nav = HYBaseNavVC.init(rootViewController: ViewController())
            arr.append(nav)
        }
        
        // 启用设备方向监听
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        tab.viewControllers = arr
        win.rootViewController = tab
        win.makeKeyAndVisible()
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        let topVC = UIViewController.mt_top()
        return topVC.supportedInterfaceOrientations
    }
}

