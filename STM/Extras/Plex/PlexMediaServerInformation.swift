//
//  PlexAPI.swift
//  STM
//
//  Created by KZ on 2018/03/26.
//  Copyright © 2018年 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import UIKit
import SWXMLHash

let httpTimeout = DispatchTime(uptimeNanoseconds: UInt64(10.0 * Double(NSEC_PER_SEC)))
var plexUserInformation = PlexUserInformation()

// global pms variable to store pms related data, including local and remote connection
var plexMediaServerInformation: [String: PlexMediaServerInformation] = [:]

class PlexMediaServerInformation {
    private var attributes: [String: String] = [:]

    private var xmlPms: XMLIndexer?  // store for debugging - XML data this PMS was set up with
    private var fastestConnection: Int?

    init(attributes: [String: String]) {
        self.attributes = attributes
        self.xmlPms = nil
    }

    init(xmlPms: XMLIndexer) {
        guard let element = xmlPms.element else {
            return
        }

        self.xmlPms = xmlPms
        var newDictionary = [String: String]()
        for (key, value) in element.allAttributes {
            newDictionary[key] = value.text
        }
        self.attributes = newDictionary

        // check server - fire at every connection. fastest response wins
        // multiple threads - wait for one finisher
        // todo: honor publicAddressMatches to double check local vs remote addresses only
        self.fastestConnection = nil
        let dsptch = DispatchSemaphore(value: 0)
        for (ix, con) in xmlPms["Connection"].all.enumerated() {
            DispatchQueue.global(qos: .default).async {
                guard let element = con.element else {
                    return
                }

                let session = URLSession(configuration: URLSessionConfiguration.default)
                let url = URL(string: (element.allAttributes["uri"]?.text)! + "?X-Plex-Token=" + self.attributes["accessToken"]!)
                let request = URLRequest(url: url!)

                let task = session.dataTask(with: request) {
                    (data, response, error) -> Void in
                    if let httpResp = response as? HTTPURLResponse {
                        //print(String(data: data!, encoding: NSUTF8StringEncoding))
                        if self.fastestConnection == nil {  // todo: thread safe?
                            self.fastestConnection = ix
                        }
                        dsptch.signal()
                    }
                }
                task.resume()
            }
        }
        dsptch.wait(timeout: DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + httpTimeout.uptimeNanoseconds))

        // add connection details of fastest response to top level attributes
        if let fastestConnection = self.fastestConnection {
            for (key, value) in xmlPms["Connection"][fastestConnection].element!.allAttributes {
                self.attributes[key] = value.text
            }
        }

        print(self.attributes)
    }

    func getAttribute(key: String) -> String {
        if let attribute = attributes[key] {
            return attribute
        }
        return ""
    }
}
