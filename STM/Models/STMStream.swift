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

    let meta: STMStreamMeta?
    let user: STMUser?

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
        self.meta = "meta" <~~ json
        self.user = "user" <~~ json
    }

    func alphaID() -> String {
        return Constants.Config.hashids.encode(id) ?? ""
    }

    func shareURL() -> URL? {
        return URL(string: Constants.Config.siteBaseURL + "/s/" + alphaID())
    }

    func pictureURL() -> URL? {
        return URL(string: Constants.Config.apiBaseURL + "/stream/\(id)/picture")
    }

    func color() -> UIColor {
        guard let colorHex = colorHex else {
            return Constants.UI.Color.tint5
        }

        guard colorHex.characters.count == 6 else {
            return Constants.UI.Color.tint5
        }

        return HEX(colorHex)
    }

}

enum STMStreamStatus: Int {
    case offline = 0
    case online = 1
    case recentlyOnline = 2
}

enum STMStreamType: Int {
    case radio = 0
    case podcast = 1
    case live = 2
}
