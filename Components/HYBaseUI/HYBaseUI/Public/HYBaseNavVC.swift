//
//  HYBaseNavVC.swift
//  HYBaseUI
//
//  Created by stephen Li on 2025/2/9.
//

import UIKit
import CYLTabBarController
import HYResource

public class HYBaseNavVC: CYLBaseNavigationController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = UIColor.c_main
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            
        } else {
            navigationBar.barTintColor = .red
        }
    }
}
