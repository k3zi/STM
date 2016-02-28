//
//  STMComment.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import Gloss

struct STMComment: Decodable {

    let id: Int?
    let user: STMUser?
    let text: String?
    let date: NSDate?

    // MARK: - Deserialization

    init?(json: JSON) {
        self.id = "id" <~~ json
        self.user = "user" <~~ json
        self.text = "text" <~~ json
        self.date = Decoder.decodeUnixTimestamp("date", json: json)
    }
}

extension Decoder {
    static func decodeUnixTimestamp(key: String, json: JSON) -> NSDate? {

        if let dateInt = json.valueForKeyPath(key) as? Int {
            return NSDate(timeIntervalSince1970: NSTimeInterval(dateInt))
        }

        return nil
    }
}
