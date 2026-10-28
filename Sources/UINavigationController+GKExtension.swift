//
//  UINavigationController+GKExtension.swift
//  GKNavigationBarSwift
//
//  Created by QuintGao on 2020/3/25.
//  Copyright © 2020 QuintGao. All rights reserved.
//

import UIKit

extension UINavigationController: GKChildAwakeProtocol {
    // MARK: - 重新系统方法
    private static let onceToken = UUID().uuidString
    public static func gkChildAwake() {
        DispatchQueue.once(token: onceToken) {
            gk_swizzled_instanceMethod("gkNav", oldClass: self, oldSelector: "pushViewController:animated:", newClass: self)
        }
    }
    
    @objc func gkNav_pushViewController(_ viewController: UIViewController, animated: Bool) {
        if self.gk_openSystemNavHandle && !self.gk_usesSystemNavigationBar {
            self.isNavigationBarHidden = true
        }
        gkNav_pushViewController(viewController, animated: animated)
    }
}

extension UINavigationController {
    fileprivate struct AssociatedKeys {
        static var gkUsesSystemNavigationBar: Void?
        static var gkOpenSystemNavHandle: Void?
        static var gkHideNavigationBar: Void?
    }
    
    /// Use container-managed bars so UIKit can place controls on either axis.
    /// Defaults to true on iOS 27.1+. Set before configuring/pushing controllers.
    /// Set false only for an explicitly horizontal custom-bar presentation.
    public var gk_usesSystemNavigationBar: Bool {
        get {
            if let value = gk_getAssociatedObject(self, &AssociatedKeys.gkUsesSystemNavigationBar) as? Bool {
                return value
            }
            if #available(iOS 27.1, *) { return true }
            return false
        }
        set {
            gk_setAssociatedObject(self, &AssociatedKeys.gkUsesSystemNavigationBar, newValue)
            topViewController?.viewIfLoaded?.setNeedsLayout()
        }
    }

    public var gk_openSystemNavHandle: Bool {
        get {
            guard let obj = gk_getAssociatedObject(self, &AssociatedKeys.gkOpenSystemNavHandle) as? Bool else { return false }
            return obj
        }
        set {
            gk_setAssociatedObject(self, &AssociatedKeys.gkOpenSystemNavHandle, newValue)
        }
    }
    
    public var gk_hideNavigationBar: Bool {
        get {
            guard let obj = gk_getAssociatedObject(self, &AssociatedKeys.gkHideNavigationBar) as? Bool else { return false }
            return obj
        }
        set {
            gk_setAssociatedObject(self, &AssociatedKeys.gkHideNavigationBar, newValue)
        }
    }
}
