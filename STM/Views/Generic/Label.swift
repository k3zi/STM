//
//  Button.swift
//  Warp
//
//  Created by Kesi Maduka on 1/18/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class Label: UILabel {
    var topInset = CGFloat(0.0), bottomInset = CGFloat(0.0), leftInset = CGFloat(0.0), rightInset = CGFloat(0.0)
    
    func setContentEdgeInsets(insets: UIEdgeInsets) {
        topInset = insets.top
        bottomInset = insets.bottom
        leftInset = insets.left
        rightInset = insets.right
        self.invalidateIntrinsicContentSize()
    }
    
    override func drawTextInRect(rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override func intrinsicContentSize() -> CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize()
        intrinsicSuperViewContentSize.height += topInset + bottomInset
        intrinsicSuperViewContentSize.width += leftInset + rightInset
        return intrinsicSuperViewContentSize
    }

}
