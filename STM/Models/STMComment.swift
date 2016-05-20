//
//  STMComment.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import Gloss

class STMComment: Decodable, Equatable {

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

    func isEqualTo(other: STMComment) -> Bool {
        return id == other.id && didRepost == other.didRepost && didLike == other.didLike && likes == other.likes && reposts == other.reposts
    }

    func replyPlaceholder() -> String {
        guard var username = user?.username else {
            return ""
        }

        username = "@\(username)"

        guard let text = text else {
            return username + " "
        }

        let reg = "(^|[^@\\w])@(\\w{1,15})\\b"
        let nsString = text as NSString

        do {
            let matches = try NSRegularExpression(pattern: reg, options: NSRegularExpressionOptions()).matchesInString(text, options: NSMatchingOptions(), range: NSRange(location: 0, length: text.characters.count))

            var stringMatches = matches.map({ nsString.substringWithRange($0.range) })
            if !stringMatches.contains(username) {
                stringMatches.append(username)
            }

            if let currentUsername = AppDelegate.del().currentUser?.username {
                stringMatches.removeObject("@" + currentUsername)
            }

            return stringMatches.joinWithSeparator(" ") + " "
        } catch {
            return username + " "
        }
    }

}

func == (rhs: STMComment, lhs: STMComment) -> Bool {
    return rhs.isEqualTo(lhs)
}

extension Decoder {
    static func decodeUnixTimestamp(key: String, json: JSON) -> NSDate? {

        if let dateInt = json.valueForKeyPath(key) as? Int {
            return NSDate(timeIntervalSince1970: NSTimeInterval(dateInt))
        }

        return nil
    }
}
