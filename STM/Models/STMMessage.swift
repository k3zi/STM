//
//  STMMessage.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import Gloss

class STMMessage: Decodable {

    let id: Int
    let user: STMUser?
    let text: String?
    let date: NSDate?

    // MARK: - Deserialization

    required init?(json: JSON) {
        guard let id: Int = "id" <~~ json else {
            return nil
        }

        self.id = id
        self.user = "user" <~~ json
        self.text = "text" <~~ json
        self.date = Decoder.decodeUnixTimestamp("date", json: json)
    }
}
