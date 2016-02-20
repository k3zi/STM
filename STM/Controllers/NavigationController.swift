//
//  NavigationController.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()

        //Edit NavBar
        self.navigationBar.translucent = false
        self.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.navigationBar.setBackgroundImage(imageLayerForGradientBackground(), forBarMetrics: .Default)
    }

    //MARK: Styling
    func imageLayerForGradientBackground() -> UIImage {
        var updatedFrame = self.navigationBar.bounds
        updatedFrame.size.height += 20

        let layer = CAGradientLayer()
        layer.colors = [RGB(110, g: 74, b: 217, a: 255).CGColor, RGB(122, g: 86, b: 229, a: 255).CGColor]
        layer.frame = updatedFrame

        UIGraphicsBeginImageContext(CGSize(width: updatedFrame.width, height: updatedFrame.height))
        layer.renderInContext(UIGraphicsGetCurrentContext()!)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
