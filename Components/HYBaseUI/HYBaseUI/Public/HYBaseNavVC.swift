//
//  HYBaseNavVC.swift
//  HYBaseUI
//
//  Created by stephen Li on 2025/2/9.
//

import UIKit
import CYLTabBarController

public class HYBaseNavVC: CYLBaseNavigationController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .red
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            
        } else {
            navigationBar.barTintColor = .red
        }
    }
}
