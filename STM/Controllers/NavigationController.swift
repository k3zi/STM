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
        self.navigationBar.tintColor = UIColor.white
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.setBackgroundImage(imageLayerForGradientBackground(), for: .default)
        self.navigationBar.isTranslucent = true
        self.navigationBar.backgroundColor = UIColor.clear

        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        visualEffectView.isUserInteractionEnabled = false
        visualEffectView.frame = self.navigationBar.bounds
        visualEffectView.frame = view.bounds

        self.navigationBar.addSubview(visualEffectView)
        visualEffectView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        visualEffectView.autoPinEdge(toSuperviewEdge: .top, withInset: -20)
    }

    // MARK: Styling
    func imageLayerForGradientBackground() -> UIImage {
        var updatedFrame = self.navigationBar.bounds
        updatedFrame.size.height += 20

        let layer = CAGradientLayer()
        layer.colors = [RGB(172, g: 193, b: 255).withAlphaComponent(0.5).cgColor, RGB(172, g: 193, b: 255).withAlphaComponent(0.5).cgColor]
        layer.frame = updatedFrame

        UIGraphicsBeginImageContext(CGSize(width: updatedFrame.width, height: updatedFrame.height))
        layer.render(in: UIGraphicsGetCurrentContext()!)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}
