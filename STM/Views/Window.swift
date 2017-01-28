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

    override func addSubview(_ view: UIView) {
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
        self.splashView.backgroundColor = Constants.UI.Color.tint2

        self.splashView.addSubview(imageView)
        imageView.autoCenterInSuperview()

        self.addSubview(self.splashView)
        self.splashView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)
        self.splashView.autoCenterInSuperview()

        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async { () -> Void in
            while !self.screenIsReady {
                RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date.distantFuture)
            }

            DispatchQueue.main.async { () -> Void in
                let lScale = 1.5*((AppDelegate.del().window?.frame.size.width)!/imageView.frame.size.width)
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    imageView.transform = CGAffineTransform.identity.scaledBy(x: 0.5, y: 0.5)
                    }, completion: { (complete) -> Void in
                        UIView.animate(withDuration: 0.5, animations: { () -> Void in
                            imageView.transform = CGAffineTransform.identity.scaledBy(x: lScale, y: lScale)
                            self.splashView.alpha = 0.0
                            }, completion: { (complete) -> Void in
                                self.splashView.removeFromSuperview()
                                self.hasHidden = true
                        })
                })
            }
        }
    }
}
