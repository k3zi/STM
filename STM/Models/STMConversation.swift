//
//  STMConversation.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import Gloss

class STMConversation: Decodable {

    let id: Int
    let users: [STMUser]?
    let name: String
    let lastMessage: STMMessage?
    let unreadCount: Int

    // MARK: - Deserialization

    required init?(json: JSON) {
        guard let id: Int = "id" <~~ json else {
            return nil
        }

        self.id = id
        self.users = "users" <~~ json
        self.name = ("name" <~~ json) ?? ""
        self.lastMessage = "lastMessage" <~~ json
        self.unreadCount = "unreadCount" <~~ json ?? 0
    }

    func listNames() -> String {
        if let users = users {
            if users.count == 2 {
                for user in users {
                    if user.id != AppDelegate.del().currentUser?.id {
                        return user.displayName ?? ""
                    }
                }
            }

            let userDisplayNames = users.filter({ $0.id != AppDelegate.del().currentUser?.id }).flatMap({ $0.displayName })
            return userDisplayNames.joinWithSeparator(", ")
        }

        return "Conversation"
    }

}
