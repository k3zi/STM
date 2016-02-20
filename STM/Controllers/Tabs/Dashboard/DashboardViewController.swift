//
//  DashboardViewController.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class DashboardViewController: KZViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let window = AppDelegate.del().window as? Window {
            window.screenIsReady = true
        }
    }

}
