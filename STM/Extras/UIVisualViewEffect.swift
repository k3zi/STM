//
//  UIVisualViewEffect.swift
//  STM
//
//  Created by KZ on 10/8/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

private typealias ObjcRawUIVisualEffectViewSelCGRect =
    @convention(c) (UIVisualEffectView, Selector, CGRect) -> Void

private var cornerRadiusKey =
"com.WeZZard.Waxing.UIVisualEffectView-CornerRadius.cornerRadius"

private var needsUpdateMaskLayerKey =
"com.WeZZard.Waxing.UIVisualEffectView-CornerRadius.needsUpdateMaskLayer"

extension UIVisualEffectView {
    public var cornerRadius: CGFloat {
        get {
            if let storedValue = objc_getAssociatedObject(self, &cornerRadiusKey) as? CGFloat {
                return storedValue
            }

            return 0
        }
        set {
            if cornerRadius != newValue {
                objc_setAssociatedObject(self, &cornerRadiusKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                setNeedsUpdateMaskLayer()
            }
        }
    }

    private var needsUpdateMaskLayer: Bool {
        get {
            if let storedValue = objc_getAssociatedObject(self, &needsUpdateMaskLayerKey) as? Bool {
                return storedValue
            }

            return false
        }
        set {
            objc_setAssociatedObject(self, &needsUpdateMaskLayerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    struct Static {
        static let onceToken = NSUUID().uuidString
    }

    @objc public static func swizzle_setBounds() {
        DispatchQueue.once(token: Static.onceToken) {
            let selector: Selector = #selector(setter: CALayer.bounds)

            let method = class_getInstanceMethod(self, selector)

            let imp_original = method_getImplementation(method!)

            before_setBounds = unsafeBitCast(imp_original, to: ObjcRawUIVisualEffectViewSelCGRect.self)

            class_replaceMethod(self, selector, unsafeBitCast(after_setBounds, to: IMP.self), "@:{_struct=CGRect}")
        }
    }

    public func setNeedsUpdateMaskLayer() {
        needsUpdateMaskLayer = true
        weak var weakSelf = self
        OperationQueue.main.addOperation {
            weakSelf?.updateMaskLayerIfNeeded()
        }
    }

    private func updateMaskLayerIfNeeded() {
        if needsUpdateMaskLayer {
            updateMaskLayer()
            needsUpdateMaskLayer = false
        }
    }

    private func updateMaskLayer() {
        var filterViewFound = false
        for each in subviews {
            if type(of: each).description().contains("Filter") {
                filterViewFound = true
                let newPath = UIBezierPath(roundedRect: each.bounds, cornerRadius: self.cornerRadius).cgPath
                if let existedMask = each.layer.mask as? CAShapeLayer {
                    existedMask.path = newPath
                } else {
                    let shapeLayer = CAShapeLayer()
                    shapeLayer.path = newPath
                    each.layer.mask = shapeLayer
                }
            } else {
                setNeedsUpdateMaskLayer()
            }
        }

        // assert(filterViewFound == true, "Filter view was not found! Check your hacking!")
    }
}

private var before_setBounds: ObjcRawUIVisualEffectViewSelCGRect = { _, _, _  in
    fatalError("No implementation found")
}

private let after_setBounds: ObjcRawUIVisualEffectViewSelCGRect = {
    (aSelf, selector, bounds) -> Void in

    let oldBounds = aSelf.bounds

    before_setBounds(aSelf, selector, bounds)

    if oldBounds.size != bounds.size {
        aSelf.setNeedsUpdateMaskLayer()
    }
}

public extension DispatchQueue {

    private static var _onceTracker = [String]()

    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.

     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    public class func once(token: String, block: () -> Void) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }

        if _onceTracker.contains(token) {
            return
        }

        _onceTracker.append(token)
        block()
    }
}
