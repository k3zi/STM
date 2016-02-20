//
//  Window.swift
//  Dawgtown
//
//  Created by Kesi Maduka on 10/2/15.
//  Copyright © 2015 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class Window: UIWindow {
    var hasHidden = false
    let splashView = UIView()
    var screenIsReady = false

    override func addSubview(view: UIView) {
        if !hasHidden {
            self.insertSubview(view, belowSubview: splashView)
        } else {
            super.addSubview(view)
        }
    }

    override func makeKeyAndVisible() {
        showSplash()
        super.makeKeyAndVisible()
    }

    func showSplash() {
        let imageView = UIImageView(image: UIImage(named: "launchLogo"))

        self.backgroundColor = RGB(255)
        self.splashView.backgroundColor = RGB(89, g: 68, b: 205)

        self.splashView.addSubview(imageView)
        imageView.autoCenterInSuperview()

        self.addSubview(self.splashView)
        self.splashView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        self.splashView.autoCenterInSuperview()

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            while !self.screenIsReady {
                NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
            }

            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                let lScale = 1.5*((AppDelegate.del().window?.frame.size.width)!/imageView.frame.size.width)
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    imageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5)
                    }) { (complete) -> Void in
                        UIView.animateWithDuration(0.5, animations: { () -> Void in
                            imageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, lScale, lScale)
                            self.splashView.alpha = 0.0
                            }) { (complete) -> Void in
                                self.splashView.removeFromSuperview()
                                self.hasHidden = true
                        }
                }
            }
        }
    }
}
