//
//  STMDashboardItem.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import Gloss

struct STMTimelineItem: Decodable {
    var message: String?
    var user: STMUser?
    var date: Date

    // MARK: - Deserialization

    init?(json: JSON) {
        self.message = "message" <~~ json
        self.user = "user" <~~ json
        self.date = NSDate() as Date
    }
}
