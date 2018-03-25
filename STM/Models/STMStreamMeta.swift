//
//  STMStreamMeta.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import Gloss

struct STMStreamMeta: JSONDecodable {

    let artist: String?
    let title: String
    let album: String?
    let image: UIImage?
    let imageFile: String?

    // MARK: - Deserialization

    init?(json: JSON) {
        guard let title: String = ("title" <~~ json ?? "meta_title" <~~ json) else {
            return nil
        }

        self.artist = "artist" <~~ json ?? "meta_artist" <~~ json
        self.title = title
        self.album = "album" <~~ json ?? "meta_album" <~~ json
        self.imageFile = "meta_image_file" <~~ json
        self.image = JSONDecoder.decodeImageFromBase64("image", json: json)
    }

    func imageURL() -> URL? {
        if let imageFile = imageFile {
            return URL(string: Constants.Config.apiBaseURL + "/resource/" + imageFile)
        }

        return nil
    }

}

extension JSONDecoder {

    static func decodeImageFromBase64(_ key: String, json: JSON) -> UIImage? {
        if let imageEncodedString = json.valueForKeyPath(keyPath: key) as? String {
            if let data = NSData(base64Encoded: imageEncodedString, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                return UIImage(data: data as Data)
            }
        }

        return nil
    }

}
