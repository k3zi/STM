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
    var colorHex: String?

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
        self.colorHex = "colorHex" <~~ json
    }

    func alphaID() -> String {
        return Constants.Config.hashids.encode(id) ?? ""
    }

    func url() -> NSURL {
        return NSURL(string: Constants.Config.siteBaseURL + "/s/" + alphaID()) ?? NSURL()
    }

    func pictureURL() -> NSURL {
        return NSURL(string: Constants.Config.apiBaseURL + "/stream/\(id)/picture") ?? NSURL()
    }

    func color() -> UIColor {
        guard let colorHex = colorHex else {
            return Constants.UI.Color.tint
        }

        guard colorHex.characters.count == 6 else {
            return Constants.UI.Color.tint
        }

        return HEX(colorHex)
    }

}

enum STMStreamStatus: Int {
    case Offline = 0
    case Online = 1
    case RecentlyOnline = 2
}

enum STMStreamType: Int {
    case Radio = 0
    case Podcast = 1
    case Live = 2
}
