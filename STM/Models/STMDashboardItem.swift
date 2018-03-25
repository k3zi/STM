//
//  STMDashboardItem.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import Gloss

struct STMDashboardItem: JSONDecodable {
    var name: String?
    var items: [STMStream]?

    // MARK: - Deserialization

    init?(json: JSON) {
        self.name = "name" <~~ json
        self.items = "items" <~~ json
    }
}
