//
//  UIToolbarStyles.swift
//  STM
//
//  Created by Kesi Maduka on 4/18/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

extension UIToolbar {

    class func styleWithButtons(vc: UIViewController) -> UIToolbar {
        let toolBar = UIToolbar()
        toolBar.barStyle = .Black

        let doneButton = UIBarButtonItem(title: "Done", style: .Done, target: vc, action: #selector(UIViewController.donePressed))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .Plain, target: vc, action: #selector(UIViewController.cancelPressed))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.sizeToFit()
        return toolBar
    }

}
