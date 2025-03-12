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
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = UIColor.c_main
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.c_text]
            
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        } else {
            // Fallback on earlier versions
            navigationBar.backgroundColor = UIColor.c_main
            navigationBar.tintColor = UIColor.c_text
            navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.c_text]
        }
    }
}
