//
//  TabBarController.swift
//  STM
//
//  Created by KZ on 10/7/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {

    let buttonBlur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    let middleLogo = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBar.shadowImage = UIImage()
        self.tabBar.backgroundImage = imageLayerForGradientBackground()
        self.tabBar.isTranslucent = true
        self.tabBar.backgroundColor = UIColor.clear
        self.tabBar.clipsToBounds = false

        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        visualEffectView.frame = self.tabBar.bounds

        self.tabBar.addSubview(visualEffectView)
        visualEffectView.autoPinEdgesToSuperviewEdges()

        buttonBlur.clipsToBounds = true
        self.tabBar.addSubview(buttonBlur)
        buttonBlur.autoAlignAxis(toSuperviewAxis: .vertical)
        buttonBlur.autoPinEdge(toSuperviewEdge: .bottom)
        buttonBlur.autoMatch(.height, to: .height, of: self.tabBar, withMultiplier: 1.224)
        buttonBlur.autoMatch(.width, to: .height, of: buttonBlur)

        middleLogo.clipsToBounds = true
        middleLogo.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        middleLogo.setBackgroundColor(RGB(76, g: 81, b: 89).withAlphaComponent(1.0), forState: .normal)
        middleLogo.setImage(UIImage(named: "launchLogo"), for: .normal)
        middleLogo.setImage(UIImage(named: "launchLogo")?.withRenderingMode(.alwaysTemplate), for: .selected)
        middleLogo.tintColor = Constants.UI.Color.tint2
        buttonBlur.contentView.addSubview(middleLogo)
        middleLogo.autoPinEdgesToSuperviewEdges()
    }

    func imageLayerForGradientBackground() -> UIImage {
        let updatedFrame = self.tabBar.bounds

        let layer = CAGradientLayer()
        layer.colors = [RGB(172, g: 193, b: 255).withAlphaComponent(0.5).cgColor, RGB(172, g: 193, b: 255).withAlphaComponent(0.5).cgColor]
        layer.frame = updatedFrame

        UIGraphicsBeginImageContext(CGSize(width: updatedFrame.width, height: updatedFrame.height))
        layer.render(in: UIGraphicsGetCurrentContext()!)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        buttonBlur.cornerRadius = (tabBar.frame.height*1.224) / 2
        buttonBlur.layer.cornerRadius = (tabBar.frame.height*1.224) / 2

        middleLogo.layer.cornerRadius = (tabBar.frame.height*1.224) / 2
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        middleLogo.isSelected = item.tag == 3
    }

}
