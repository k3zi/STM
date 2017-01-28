//
//  UIToolbarStyles.swift
//  STM
//
//  Created by Kesi Maduka on 4/18/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

extension UIToolbar {

    class func styleWithButtons(_ vc: UIViewController) -> UIToolbar {
        let toolBar = UIToolbar()
        toolBar.barStyle = .black

        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: vc, action: #selector(UIViewController.donePressed))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: vc, action: #selector(UIViewController.cancelPressed))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.sizeToFit()
        return toolBar
    }

}
