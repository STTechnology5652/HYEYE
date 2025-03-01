//
//  UIViewController+STNavBar.swift
//  HYBaseUI
//
//  Created by stephen Li on 2025/3/1.
//

import CYLTabBarController.UIViewController_CYLNavigationControllerExtention

extension UIViewController {
    public func stSetNavigationBarHidden(_ hidden: Bool, animated: Bool = true) {
        if hidden {
            self.cyl_navigationBarHidden = true
            self.cyl_setNavigationBarHiddenIfNeeded(animated)
        } else {
            self.cyl_setNavigationBarVisibleIfNeeded(animated)
        }
    }
}

