//
//  UINavigationItem+GKExtension.swift
//  GKNavigationBarSwift
//
//  Created by QuintGao on 2020/3/25.
//  Copyright © 2020 QuintGao. All rights reserved.
//

import UIKit

extension UINavigationItem: GKAwakeProtocol {
    @objc public static func gkAwake() {
        // UIKit owns spacing on systems where an item has no owning-view context.
    }
}

extension NSObject: GKObjectAwakeProtocol {
    // MARK: - 重新系统方法
    private static let onceToken = UUID().uuidString
    public static func gkObjectAwake() {
        // New container-managed bars own their layout. Do not swizzle their internals.
        if #available(iOS 27.1, *) { return }
        DispatchQueue.once(token: onceToken) {
            if #available(iOS 11.0, *) {
                let oriSels = ["_UINavigationBarContentView": "layoutSubviews", "_UINavigationBarContentViewLayout": "_updateMarginConstraints"]
                for (cls, sel) in oriSels {
                    gk_swizzled_instanceMethod("gk", oldClass: NSClassFromString(cls), oldSelector: sel, newClass: NSObject.self)
                }
            }
        }
    }
    
    @objc func gk_layoutSubviews() {
        gk_layoutSubviews()
        if GKConfigure.fixNavItemSpaceDisabled() { return }
        
        if let cls = NSClassFromString("_UINavigationBarContentView") {
            if !self.isMember(of: cls) { return }
            
            guard let layout = self.value(forKey: "_layout") as? NSObject else { return }
            
            let selector = NSSelectorFromString("_updateMarginConstraints")

            if layout.responds(to: selector) {
                layout.perform(selector)
            }
        }
    }
    
    @objc func gk__updateMarginConstraints() {
        gk__updateMarginConstraints()
        if GKConfigure.fixNavItemSpaceDisabled() { return }
        
        if let cls = NSClassFromString("_UINavigationBarContentViewLayout") {
            if !self.isMember(of: cls) { return }
            
            gk_adjustLeadingBarConstraints()
            gk_adjustTrailingBarConstraints()
        }
    }
    
    private func gk_owningBar(for constraints: [NSLayoutConstraint]) -> UINavigationBar? {
        for constraint in constraints {
            for item in [constraint.firstItem, constraint.secondItem] {
                var view = item as? UIView
                while let current = view {
                    if let bar = current as? UINavigationBar { return bar }
                    view = current.superview
                }
            }
        }
        return nil
    }

    fileprivate func gk_adjustLeadingBarConstraints() {
        if GKConfigure.fixNavItemSpaceDisabled() { return }
        
        let leadingBarConstrainst: [NSLayoutConstraint]? = self.value(forKey: "_leadingBarConstraints") as? [NSLayoutConstraint]
        if leadingBarConstrainst == nil { return }
        
        guard let bar = gk_owningBar(for: leadingBarConstrainst!) else { return }
        let constant = GKConfigure.gk_navItemLeftSpace - GKConfigure.gk_fixedSpace(in: bar)
        
        for constraint in leadingBarConstrainst! {
            if constraint.firstAttribute == .leading && constraint.secondAttribute == .leading {
                constraint.constant = constant
            }
        }
    }
    
    fileprivate func gk_adjustTrailingBarConstraints() {
        if GKConfigure.fixNavItemSpaceDisabled() { return }
        
        let trailingBarConstraints: [NSLayoutConstraint]? = self.value(forKey: "_trailingBarConstraints") as? [NSLayoutConstraint]
        if trailingBarConstraints == nil { return }
        
        guard let bar = gk_owningBar(for: trailingBarConstraints!) else { return }
        let constant = GKConfigure.gk_fixedSpace(in: bar, trailing: true) - GKConfigure.gk_navItemRightSpace
        
        for constraint in trailingBarConstraints! {
            if constraint.firstAttribute == .trailing && constraint.secondAttribute == .trailing {
                constraint.constant = constant
            }
        }
    }
}
