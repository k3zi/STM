//
//  STMUser.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import Gloss

struct STMUser: Decodable {
    
    let id: Int?
    let username: String?
    let displayName: String?
    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        self.id = "id" <~~ json
        self.username = "username" <~~ json
        self.displayName = "displayName" <~~ json
    }
    
}
