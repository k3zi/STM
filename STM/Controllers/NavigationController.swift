//
//  NavigationController.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController, UINavigationControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self

        //Edit NavBar
        self.navigationBar.isTranslucent = false
        self.navigationBar.tintColor = UIColor.white
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        self.navigationBar.setBackgroundImage(imageLayerForGradientBackground(), for: .default)
        self.navigationBar.shadowImage = UIImage()
    }

    //MARK: Styling
    func imageLayerForGradientBackground() -> UIImage {
        var updatedFrame = self.navigationBar.bounds
        updatedFrame.size.height += 20

        let layer = CAGradientLayer()
        layer.colors = [RGB(110, g: 74, b: 217, a: 255).cgColor, RGB(122, g: 86, b: 229, a: 255).cgColor]
        layer.frame = updatedFrame

        UIGraphicsBeginImageContext(CGSize(width: updatedFrame.width, height: updatedFrame.height))
        layer.render(in: UIGraphicsGetCurrentContext()!)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let item = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        viewController.navigationItem.backBarButtonItem = item
    }
}
