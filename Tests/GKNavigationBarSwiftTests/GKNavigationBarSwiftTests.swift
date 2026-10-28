import XCTest
import UIKit
@testable import GKNavigationBarSwift

final class GKNavigationBarSwiftTests: XCTestCase {
    @available(iOS 11.0, *)
    private final class InsetsWindow: UIWindow {
        var testInsets = UIEdgeInsets.zero
        override var safeAreaInsets: UIEdgeInsets { return testInsets }
    }

    func testWindowResizeAndRotationAreReadAgain() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        for size in [CGSize(width: 390, height: 844), CGSize(width: 844, height: 390),
                     CGSize(width: 700, height: 800), CGSize(width: 320, height: 800)] {
            window.frame.size = size
            view.frame = window.bounds
            XCTAssertEqual(UIDevice.layoutSize(in: view), size)
        }
    }

    @available(iOS 11.0, *)
    func testSafeAreaChangesIncludingZeroAndSideOnlyInsets() {
        let window = InsetsWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 900))
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        for insets in [UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
                       UIEdgeInsets(top: 0, left: 59, bottom: 21, right: 59),
                       UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 62), .zero] {
            window.testInsets = insets
            XCTAssertEqual(GKNavigationBar.topInset(in: view), insets.top)
            XCTAssertEqual(UIDevice.safeAreaInsets(in: window), insets)
        }
        view.frame.origin.y = 100
        window.testInsets.top = 59
        XCTAssertEqual(GKNavigationBar.topInset(in: view), 0)
    }

    @available(iOS 11.0, *)
    func testOwningWindowIsUsedAndDetachedViewDoesNotGuess() {
        let first = InsetsWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let second = InsetsWindow(frame: CGRect(x: 0, y: 0, width: 700, height: 800))
        first.testInsets.top = 59
        second.testInsets.top = 24
        let view = UIView(frame: first.bounds)
        first.addSubview(view)
        XCTAssertEqual(GKNavigationBar.topInset(in: view), 59)
        second.addSubview(view)
        XCTAssertEqual(GKNavigationBar.topInset(in: view), 24)
        view.removeFromSuperview()
        XCTAssertEqual(GKNavigationBar.topInset(in: view), 0)
    }

    @available(iOS 11.0, *)
    func testFullScreenAndSheetUseSameLiveFittingWithoutFixedHeight() {
        final class SizingBar: GKNavigationBar {
            override func sizeThatFits(_ size: CGSize) -> CGSize {
                return CGSize(width: size.width, height: size.width / 10)
            }
        }
        let window = InsetsWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 900))
        window.testInsets.top = 59
        let controller = UIViewController()
        controller.view = UIView(frame: window.bounds)
        window.addSubview(controller.view)
        let bar = SizingBar(frame: .zero)
        controller.view.addSubview(bar)
        for width in [CGFloat(320), 700, 390, 800, 320] {
            controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 800)
            for sheet in [false, true] {
                bar.gk_nonFullScreen = sheet
                let frame = bar.gk_layoutFrame(in: controller.view)
                XCTAssertEqual(frame.width, width)
                XCTAssertEqual(frame.height, 59 + width / 10)
                XCTAssertEqual(UIDevice.navBarHeight(in: controller), width / 10)
                XCTAssertEqual(UIDevice.navBarFullHeight(in: controller), frame.height)
            }
        }
        // A sheet already below the window's safe top must not add it again.
        controller.view.frame.origin.y = 100
        XCTAssertEqual(bar.gk_layoutFrame(in: controller.view).height, 32)
        XCTAssertEqual(UIDevice.navBarFullHeight(in: controller), 32)
    }

    func testContextualHeightDoesNotCreateOrGuessMissingBar() {
        let controller = UIViewController()
        XCTAssertEqual(UIDevice.navBarHeight(in: controller), 0)
        XCTAssertFalse(controller.isViewLoaded)
        controller.view = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        XCTAssertEqual(UIDevice.navBarFullHeight(in: controller), 0)
        XCTAssertTrue(controller.view.subviews.isEmpty)
    }

    @available(iOS 11.0, *)
    func testSideInsetsLimitCustomBarWithoutDoubleApplyingInsets() {
        let window = InsetsWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        let bar = GKNavigationBar(frame: .zero)
        for insets in [UIEdgeInsets(top: 0, left: 62, bottom: 0, right: 0),
                       UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 62),
                       UIEdgeInsets(top: 0, left: 44, bottom: 21, right: 44), .zero] {
            window.testInsets = insets
            view.frame = window.bounds
            let frame = bar.gk_layoutFrame(in: view)
            XCTAssertEqual(frame.minX, insets.left)
            XCTAssertEqual(frame.width, 800 - insets.left - insets.right)
            view.frame = window.bounds.inset(by: insets)
            let alreadySafe = bar.gk_layoutFrame(in: view)
            XCTAssertEqual(alreadySafe.minX, 0)
            XCTAssertEqual(alreadySafe.width, view.bounds.width)
        }
    }

    @available(iOS 13.0, *)
    func testContainerModeMigratesItemsAndRemovesStandaloneBar() {
        let controller = UIViewController()
        controller.loadViewIfNeeded()
        let item = controller.gk_navigationItem
        item.title = "Before attachment"
        let button = UIBarButtonItem(title: "Action", style: .plain, target: nil, action: nil)
        item.rightBarButtonItem = button
        let custom = controller.gk_navigationBar
        let nav = UINavigationController(rootViewController: controller)
        nav.gk_usesSystemNavigationBar = true
        controller.gk_updateContainerBar()
        XCTAssertTrue(controller.gk_navigationItem === controller.navigationItem)
        XCTAssertEqual(controller.navigationItem.title, "Before attachment")
        XCTAssertTrue(controller.navigationItem.rightBarButtonItem === button)
        XCTAssertNil(custom.superview)
        XCTAssertNil(custom.items)
        controller.gk_navTitle = "After attachment"
        XCTAssertEqual(controller.navigationItem.title, "After attachment")
        custom.isHidden = true
        XCTAssertTrue(nav.isNavigationBarHidden)
        custom.isHidden = false
        XCTAssertFalse(nav.isNavigationBarHidden)
        controller.gk_navBackgroundColor = .red
        XCTAssertEqual(controller.navigationItem.standardAppearance?.backgroundColor, .red)
        XCTAssertNil(controller.gk_navigationBar.superview)
    }

    func testContainerModeDoesNotConfigureUnrelatedUIKitScreens() {
        let controller = UIViewController()
        let nav = UINavigationController(rootViewController: controller)
        nav.gk_usesSystemNavigationBar = true
        nav.setNavigationBarHidden(true, animated: false)
        controller.gk_updateContainerBar()
        XCTAssertTrue(nav.isNavigationBarHidden)
        XCTAssertTrue(controller.gk_navigationItem === controller.navigationItem)
    }

    func testItemSpacingReadsOwningViewsCurrentMargins() {
        let first = UIView()
        let second = UIView()
        let configure = GKNavigationBarConfigure()
        first.layoutMargins = UIEdgeInsets(top: 0, left: 13, bottom: 0, right: 29)
        second.layoutMargins = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 31)
        XCTAssertEqual(configure.gk_fixedSpace(in: first), 13)
        XCTAssertEqual(configure.gk_fixedSpace(in: first, trailing: true), 29)
        XCTAssertEqual(configure.gk_fixedSpace(in: second), 7)
        first.layoutMargins.left = 23
        XCTAssertEqual(configure.gk_fixedSpace(in: first), 23)
        XCTAssertEqual(configure.gk_fixedSpace(in: second, trailing: true), 31)
    }

    func testLayoutShapeIgnoresSupportedOrientationsAndUpdatesWithoutRotation() {
        final class LandscapeSupportedController: UIViewController {
            override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .landscape }
        }
        let controller = LandscapeSupportedController()
        XCTAssertFalse(controller.gk_isLandscape())
        XCTAssertFalse(controller.isViewLoaded)
        controller.view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 800))
        XCTAssertFalse(controller.gk_isLandscape())
        for size in [CGSize(width: 800, height: 320), CGSize(width: 400, height: 800), CGSize(width: 500, height: 500)] {
            controller.view.bounds.size = size
            XCTAssertEqual(controller.gk_isLandscape(), size.width > size.height)
            XCTAssertEqual(UIDevice.isLandScape(in: controller.view), size.width > size.height)
        }
    }

    func testBarSizingReadsCurrentContainerWidth() {
        final class SizingBar: GKNavigationBar {
            override func sizeThatFits(_ size: CGSize) -> CGSize {
                return CGSize(width: size.width, height: size.width < 400 ? 32 : 44)
            }
        }
        let bar = SizingBar(frame: .zero)
        XCTAssertEqual(bar.gk_contentHeight(for: CGSize(width: 320, height: 800)), 32)
        XCTAssertEqual(bar.gk_contentHeight(for: CGSize(width: 800, height: 320)), 44)
        XCTAssertEqual(bar.gk_contentHeight(for: CGSize(width: 320, height: 800)), 32)
    }
}
