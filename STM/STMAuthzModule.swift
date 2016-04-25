//
//  STMAuthzModule.swift
//  STM
//
//  Created by Kesi Maduka on 4/23/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

class STMAuthzModule: AuthzModule {

    func requestAccess(completionHandler: (AnyObject?, NSError?) -> Void) {
        completionHandler(nil, nil)
    }

    func requestAuthorizationCode(completionHandler: (AnyObject?, NSError?) -> Void) {
        completionHandler(nil, nil)
    }

    func exchangeAuthorizationCodeForAccessToken(code: String, completionHandler: (AnyObject?, NSError?) -> Void) {
        completionHandler(nil, nil)
    }

    func refreshAccessToken(completionHandler: (AnyObject?, NSError?) -> Void) {
        completionHandler(nil, nil)
    }

    func revokeAccess(completionHandler: (AnyObject?, NSError?) -> Void) {
        completionHandler(nil, nil)
    }

    func authorizationFields() -> [String : String]? {
        guard let user = Constants.Settings.secretObjectForKey("user") as? [String: AnyObject] else {
            return nil
        }

        guard let username = user["username"] as? String else {
            return nil
        }

        guard let password = user["password"] as? String else {
            return nil
        }

        return ["username": username, "password": password]
    }

    func isAuthorized() -> Bool {
        return true
    }


}
