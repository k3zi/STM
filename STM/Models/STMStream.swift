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

    let id: Int
    let isPrivate: Bool?
    let name: String?
    let description: String?
    let passcode: String?
    let securityHash: String?
    let live: Bool

    // MARK: - Deserialization

    init?(json: JSON) {
        guard let id: Int = "id" <~~ json else {
            return nil
        }

        self.id = id
        self.isPrivate = "private" <~~ json
        self.name = "name" <~~ json
        self.description = "description" <~~ json
        self.passcode = "passcode" <~~ json
        self.securityHash = "securityHash" <~~ json
        self.live = ("live" <~~ json) ?? false
    }

    func alphaID() -> String {
        return Constants.Config.hashids.encode(id) ?? ""
    }
}
