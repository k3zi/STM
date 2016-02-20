//
//  KZPlayerPlaylist.swift
//  KZPlayer
//
//  Created by Kesi Maduka on 10/26/15.
//  Copyright © 2015 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import RealmSwift

class KZPlayerPlaylist: Object {
    let items = List<KZPlayerPlaylistItem>()

    func add(item: KZPlayerItem) {
        let newItem = KZPlayerPlaylistItem(orig: item)
        newItem.order = items.count + 1
        items.append(newItem)
    }

    func addItems(items: [KZPlayerItem]) {
        for item in items {
            add(item)
        }
    }

    func remove(index: Int) {
        items.removeAtIndex(index)
    }

    func exchange(fromRow: Int, toRow: Int) {
        items.swap(fromRow, toRow)
    }
}

class KZPlayerPlaylistItem: KZPlayerUpNextItem {
    var order = 0
}
