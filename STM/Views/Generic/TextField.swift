//
//  TextField.swift
//  STM
//
//  Created by Kesi Maduka on 4/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

class TextField: UITextField {
    var insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: CGRect.zero)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("not intended for use from a NIB")
    }

    // placeholder position
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return super.textRectForBounds(UIEdgeInsetsInsetRect(bounds, insets))
    }

    // text position
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return super.editingRectForBounds(UIEdgeInsetsInsetRect(bounds, insets))
    }
}
