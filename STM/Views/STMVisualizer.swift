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
        
        let barColor = RGB(255, a: 51)
        for var i = 0; i < numbrerOfBars; i++ {
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
    
    func setBarHeight(index: Int, var height: CGFloat) {
        if isnan(height) || isinf(height) {
            height = 1.0
        }
        
        let barConstraint = barConstraints[index]
        barConstraint.constant = height
        bars[index].layoutIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
