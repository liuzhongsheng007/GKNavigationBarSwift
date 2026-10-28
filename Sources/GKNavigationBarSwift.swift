//
//  GKNavigationBarSwift.swift
//  GKNavigationBarSwift
//
//  Created by QuintGao on 2020/3/25.
//  Copyright © 2020 QuintGao. All rights reserved.
//  Custom navigation bar

import UIKit

open class GKNavigationBar: UINavigationBar {

    /// 导航栏所在的控制器
    public weak var viewController: UIViewController?
    
    /// 当前所在的控制器是否隐藏状态栏
    public var gk_statusBarHidden: Bool = false
    
    /// 导航栏透明度
    public var gk_navBarBackgroundAlpha: CGFloat = 1 {
        willSet {
            for obj in self.subviews {
                if let cls = NSClassFromString("_UIBarBackground") {
                    if #available(iOS 10.0, *), obj.isKind(of: cls) {
                        DispatchQueue.main.async {
                            if obj.alpha != newValue {
                                obj.alpha = newValue
                            }
                        }
                    }else {
                        if let navBarBackgroundCls = NSClassFromString("_UINavigationBarBackground") {
                            if obj.isKind(of: navBarBackgroundCls) {
                                DispatchQueue.main.async {
                                    if obj.alpha != newValue {
                                        obj.alpha = newValue
                                    }
                                }
                            }
                        }
                    }
                }
            }
            let isClipsToBounds = (newValue == 0.0)
            if self.clipsToBounds != isClipsToBounds {
                self.clipsToBounds = isClipsToBounds
            }
        }
    }
    
    /// 导航栏分割线是否隐藏
    public var gk_navLineHidden: Bool = false
    
    /// 是否是非全屏控制器
    public var gk_nonFullScreen: Bool = false

    public override init(frame: CGRect) {
        super.init(frame:frame)
        self.gk_navBarBackgroundAlpha = 1.0
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Query UIKit on every layout, using this bar's traits and its container width.
    func gk_contentHeight(for size: CGSize) -> CGFloat {
        return sizeThatFits(CGSize(width: size.width, height: 0)).height
    }

    static func horizontalContentBounds(in view: UIView) -> CGRect {
        guard let window = view.window else { return view.bounds }
        if #available(iOS 11.0, *) {
            let safe = window.bounds.inset(by: window.safeAreaInsets)
            let converted = view.convert(safe, from: window)
            let left = min(view.bounds.maxX, max(view.bounds.minX, converted.minX))
            let right = max(left, min(view.bounds.maxX, converted.maxX))
            return CGRect(x: left, y: view.bounds.minY, width: right - left, height: view.bounds.height)
        }
        return view.bounds
    }

    func gk_layoutFrame(in view: UIView) -> CGRect {
        let content = Self.horizontalContentBounds(in: view)
        return CGRect(x: content.minX, y: view.bounds.minY,
                      width: content.width,
                      height: Self.topInset(in: view) + gk_contentHeight(for: content.size))
    }

    open override var isHidden: Bool {
        didSet { viewController?.gk_updateContainerBar() }
    }

    static func topInset(in view: UIView) -> CGFloat {
        guard let window = view.window else { return 0 }
        if #available(iOS 11.0, *) {
            let safeTop = window.convert(CGPoint(x: 0, y: window.bounds.minY + window.safeAreaInsets.top), to: view).y
            return min(view.bounds.height, max(0, safeTop - view.bounds.minY))
        }
        let status = window.convert(UIApplication.shared.statusBarFrame, from: nil)
        return max(0, view.convert(status, from: window).maxY - view.bounds.minY)
    }

    @available(iOS 11.0, *)
    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        viewController?.view.setNeedsLayout()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        
        /// 适配iOS11及以上，遍历所有子控件，向下移动状态栏高度
        if #available(iOS 11.0, *) {
            for obj in self.subviews {
                if let cls = NSClassFromString("_UIBarBackground") {
                    if obj.isKind(of: cls) {
                        var frame = obj.frame
                        frame.size.height = self.frame.size.height
                        obj.frame = frame
                    }else {
                        let navBarH = gk_contentHeight(for: viewController?.view.bounds.size ?? bounds.size)

                        var frame = obj.frame
                        frame.origin.y = self.frame.size.height - navBarH
                        obj.frame = frame
                    }
                }
            }
        }
        
        // 重新设置透明度
        let alpha = self.gk_navBarBackgroundAlpha
        self.gk_navBarBackgroundAlpha = alpha
        
        // 分割线处理
        self.gk_navLineHideOrShow()
    }
    
    fileprivate func gk_navLineHideOrShow() {
        guard let backgroundView = self.subviews.first else { return }
        
        for view in backgroundView.subviews {
            if view.frame.size.height > 0 && view.frame.size.height <= 1.0 {
                view.isHidden = self.gk_navLineHidden
            }
        }
    }
}

// 实现touches方法，防止其实现父试图的touches方法
extension GKNavigationBar {
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
}

