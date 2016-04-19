//
//  STMVisualizer.swift
//  STM
//
//  Created by Kesi Maduka on 2/18/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class STMVisualizer: UIView {
    var numbrerOfBars: Int = 40
    var bars = [UIView]()
    var barConstraints = [NSLayoutConstraint]()

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    convenience init(numbrerOfBars: Int) {
        self.init(frame: CGRect.zero)

        self.numbrerOfBars = numbrerOfBars
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let barColor = RGB(255, a: 0.2)
        for i in 0 ..< numbrerOfBars {
            let bar = UIView()
            bar.backgroundColor = barColor
            self.addSubview(bar)

            if i == 0 {
                bar.autoPinEdgeToSuperviewEdge(.Left)
            } else {
                let lastBar = bars[i-1]
                bar.autoPinEdge(.Left, toEdge: .Right, ofView: lastBar)
                bar.autoMatchDimension(.Width, toDimension: .Width, ofView: lastBar)
            }

            bar.autoAlignAxisToSuperviewAxis(.Horizontal)
            barConstraints.append(bar.autoSetDimension(.Height, toSize: 1.0))

            if i == (numbrerOfBars - 1) {
                bar.autoPinEdgeToSuperviewEdge(.Right)
            }

            bars.append(bar)
        }
    }

    func setBarHeight(index: Int, height: CGFloat) {
        guard index < barConstraints.count else {
            return
        }

        let height = (isnan(height) || isinf(height)) ? 1.0 : height

        let barConstraint = barConstraints[index]
        UIView.animateWithDuration(1.0, delay: 0.0, options: .BeginFromCurrentState, animations: { () -> Void in
            barConstraint.constant = height
            self.bars[index].layoutIfNeeded()
            }, completion: nil)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
