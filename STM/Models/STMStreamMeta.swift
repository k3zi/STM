//
//  STMStreamMeta.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import Gloss

struct STMStreamMeta: Decodable {

    let artist: String?
    let title: String
    let album: String?
    let image: UIImage?

    // MARK: - Deserialization

    init?(json: JSON) {
        guard let title: String = "title" <~~ json else {
            return nil
        }

        self.artist = "artist" <~~ json
        self.title = title
        self.album = "album" <~~ json
        self.image = Decoder.decodeImageFromBase64("image", json: json)
    }

}

extension Decoder {

    static func decodeImageFromBase64(key: String, json: JSON) -> UIImage? {
        if let imageEncodedString = json.valueForKeyPath(key) as? String {
            if let data = NSData(base64EncodedString: imageEncodedString, options: NSDataBase64DecodingOptions(rawValue: 0)) {
                return UIImage(data: data)
            }
        }

        return nil
    }

}
