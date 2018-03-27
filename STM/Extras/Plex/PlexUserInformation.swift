//
//  PlexUserInformation.swift
//  STM
//
//  Created by KZ on 2018/03/26.
//  Copyright © 2018年 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import SWXMLHash

class PlexUserInformation {
    private let storage = UserDefaults.standard
    private var attributes: [String: String] = [:]

    /*
     private var _name: String
     private var _email: String
     private var _token: String
     */
    private var xmlUser: XMLIndexer?  // store for debugging - XML data this PMS was set up with
    private var xmlHomeUser: XMLIndexer?

    init() {
        xmlUser = nil
        xmlHomeUser = nil
        attributes = ["adminname": "", "name": "", "email": "", "token": "", "id": ""]

        if let name = storage.string(forKey: "adminname") {
            attributes["adminname"] = name
        }
        if let name = storage.string(forKey: "name") {
            attributes["name"] = name
        }
        if let email = storage.string(forKey: "email") {
            attributes["email"] = email
        }
        if let token = storage.string(forKey: "token") {
            attributes["token"] = token
        }
        if let id = storage.string(forKey: "id") {  // todo: store XML and direct access into nodes/attributes
            attributes["id"] = id
        }
    }

    init(xmlUser: XMLIndexer) {
        self.xmlUser = xmlUser
        xmlHomeUser = nil
        attributes = ["adminname": "", "name": "", "email": "", "token": "", "id": ""]

        // todo: check XML and neccessary nodes
        if let name = xmlUser.element?.allAttributes["title"]?.text {
            attributes["adminname"] = name
            attributes["name"] = name
        }
        if let email = xmlUser.element?.allAttributes["email"]?.text {
            attributes["email"] = email
        }
        if let token = xmlUser.element?.allAttributes["authenticationToken"]?.text {
            attributes["token"] = token
        }
        if let id = storage.string(forKey: "id") {
            attributes["id"] = id
        }

        store()
    }

    func loggedIn() -> Bool {
        return xmlUser != nil
    }

    func switchHomeUser(xmlUser: XMLIndexer) {
        xmlHomeUser = xmlUser

        if let name = xmlUser.element?.allAttributes["title"]?.text {
            attributes["name"] = name
        }
        if let email = xmlUser.element?.allAttributes["email"]?.text {
            attributes["email"] = email
        }
        if let token = xmlUser.element?.allAttributes["authenticationToken"]?.text {
            attributes["token"] = token
        }
        if let id = xmlUser.element?.allAttributes["id"]?.text {
            attributes["id"] = id
        }

        store()
    }

    func clear() {
        xmlUser = nil
        xmlHomeUser = nil
        attributes = ["adminname": "", "name": "", "email": "", "token": "", "id": ""]

        store()
    }

    private func store() {
        storage.set(attributes["adminname"], forKey: "adminname")
        storage.set(attributes["name"], forKey: "name")
        storage.set(attributes["email"], forKey: "email")
        storage.set(attributes["token"], forKey: "token")
        storage.set(attributes["id"], forKey: "id")
    }

    func getAttribute(key: String) -> String {
        if let attribute = attributes[key] {
            return attribute
        }
        return ""
    }
}
