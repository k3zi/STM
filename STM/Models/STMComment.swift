//
//  STMComment.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import Gloss

class STMComment: Decodable {

    let id: Int
    let user: STMUser?
    var stream: STMStream?
    let text: String?
    let date: NSDate?

    var likes: Int
    var didLike: Bool

    var reposts: Int
    var didRepost: Bool

    // MARK: - Deserialization

    required init?(json: JSON) {
        guard let id: Int = "id" <~~ json else {
            return nil
        }

        self.id = id
        self.user = "user" <~~ json
        self.stream = "stream" <~~ json
        self.text = "text" <~~ json
        self.date = Decoder.decodeUnixTimestamp("date", json: json)
        self.likes = ("likes" <~~ json) ?? 0
        self.didLike = ("didLike" <~~ json) ?? false
        self.reposts = ("reposts" <~~ json) ?? 0
        self.didRepost = ("didRepost" <~~ json) ?? false
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
