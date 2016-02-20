//
//  STMUser.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import Gloss

struct STMStream: Decodable {

    let id: Int?
    let isPrivate: Bool?
    let name: String?
    let description: String?
    let passcode: String?
    let securityHash: String?

    // MARK: - Deserialization

    init?(json: JSON) {
        self.id = "id" <~~ json
        self.isPrivate = "private" <~~ json
        self.name = "name" <~~ json
        self.description = "description" <~~ json
        self.passcode = "passcode" <~~ json
        self.securityHash = "securityHash" <~~ json
    }

    func alphaID() -> String {
        if let id = self.id {
            return Constants.Config.hashids.encode(id) ?? ""
        }

        return ""
    }
}
