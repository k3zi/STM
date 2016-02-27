//
//  KZScrollViewController.swift
//  KZ
//
//  Created by Kesi Maduka on 1/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

public class KZScrollViewController: KZViewController {
    public var scrollView = UIScrollView()
    public var contentView = UIView()

    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
    }

    public override func setupConstraints() {
        super.setupConstraints()
        
        scrollView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        contentView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        contentView.autoMatchDimension(.Width, toDimension: .Width, ofView: view)
    }
}