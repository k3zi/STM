//
//  UITextFieldStyles.swift
//  STM
//
//  Created by Kesi Maduka on 1/29/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

extension UITextField {

    class func styledForLaunchScreen() -> UITextField {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightMedium)
        textField.textColor = RGB(255)
        textField.backgroundColor = RGB(0, a: 0.2)
        textField.clipsToBounds = true
        textField.layer.cornerRadius = 10
        textField.textAlignment = .center

        return textField
    }

    func unstyleField() {
        spellCheckingType = .no
        autocorrectionType = .no
        autocapitalizationType = .none
    }

    func protectField() {
        unstyleField()
        isSecureTextEntry = true
    }

}
