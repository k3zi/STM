//
//  TriangleView.swift
//  STM
//
//  Created by Kesi Maduka on 3/1/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class TriangleView: UIView {
    var color = UIColor.whiteColor()

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(rect: CGRect) {
        guard let superview = self.superview else {
            return
        }

        let trianglePath = UIBezierPath()
        if self.frame.origin.x < 0 {
            trianglePath.moveToPoint(CGPoint(x: rect.width/2, y: rect.height))
        } else {
            trianglePath.moveToPoint(CGPoint(x: 0, y: rect.height))
        }

        let distanceToRight = superview.frame.width - (self.frame.origin.x + self.frame.width)

        if distanceToRight < 20 {
            trianglePath.addLineToPoint(CGPoint(x: rect.width/2, y: rect.height))
        } else {
            trianglePath.addLineToPoint(CGPoint(x: rect.width, y: rect.height))
        }

        trianglePath.addLineToPoint(CGPoint(x: rect.width/2, y: 0))
        trianglePath.closePath()

        color.setFill()
        trianglePath.fill()
    }
}
