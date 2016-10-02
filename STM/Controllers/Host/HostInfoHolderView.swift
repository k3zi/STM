//
//  HostInfoHolderView.swift
//  STM
//
//  Created by Kesi Maduka on 2/18/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class HostInfoHolderView: UIView {

    var comments: Int = 0 {
        didSet {
            DispatchQueue.main.async { () -> Void in
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    self.commentCount.text = String(self.comments)
                    self.layoutIfNeeded()
                }) 
            }
        }
    }

    var listeners: Int = 0 {
        didSet {
            DispatchQueue.main.async { () -> Void in
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    self.listenerCount.text = String(self.listeners)
                    self.layoutIfNeeded()
                }) 
            }
        }
    }

    var bandwidth: Float = 0.0 {
        didSet {
            DispatchQueue.main.async { () -> Void in
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    self.bandwidthCount.text = String(self.bytesToSize(self.bandwidth))
                    self.layoutIfNeeded()
                }) 
            }
        }
    }

    let commentCount = UILabel()
    let commentCountImageView = UIImageView(image: UIImage(named: "toolbar_comments"))

    let listenerCount = UILabel()
    let listenerCountImageView = UIImageView(image: UIImage(named: "toolbar_listeners"))

    let bandwidthCount = UILabel()
    let bandwidthCountImageView = UIImageView(image: UIImage(named: "toolbar_bandwidth"))

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.autoSetDimension(.height, toSize: 16)

        listenerCount.isHidden = true
        listenerCountImageView.isHidden = true
        [commentCount, commentCountImageView, listenerCount, listenerCountImageView, bandwidthCount, bandwidthCountImageView].forEach({ self.addSubview($0) })

        [commentCount, listenerCount, bandwidthCount].forEach({ $0.textColor = RGB(92, g: 38, b: 254) })
        [commentCount, listenerCount, bandwidthCount].forEach({ $0.font = UIFont.systemFont(ofSize: 13) })

        commentCountImageView.autoAlignAxis(toSuperviewAxis: .horizontal)
        commentCountImageView.autoPinEdge(toSuperviewEdge: .left)

        commentCount.autoAlignAxis(.horizontal, toSameAxisOf: commentCountImageView)
        commentCount.autoPinEdge(.left, to: .right, of: commentCountImageView, withOffset: 4)

        /*listenerCountImageView.autoPinEdge(.Left, toEdge: .Right, ofView: commentCount, withOffset: 12)
        listenerCountImageView.autoAlignAxis(.Horizontal, toSameAxisOfView: commentCount)

        listenerCount.autoAlignAxis(.Horizontal, toSameAxisOfView: listenerCountImageView)
        listenerCount.autoPinEdge(.Left, toEdge: .Right, ofView: listenerCountImageView, withOffset: 4)*/

        bandwidthCountImageView.autoPinEdge(.left, to: .right, of: commentCount, withOffset: 12)
        bandwidthCountImageView.autoAlignAxis(.horizontal, toSameAxisOf: commentCount)

        bandwidthCount.autoAlignAxis(.horizontal, toSameAxisOf: bandwidthCountImageView)
        bandwidthCount.autoPinEdge(.left, to: .right, of: bandwidthCountImageView, withOffset: 4)
        bandwidthCount.autoPinEdge(toSuperviewEdge: .right)
    }

    /**
    Converts the number of bytes to a readable format

     - parameter bytes: the number of bytes

     - returns: the data size in Bytes, KB, MB, GB or TB
     */
    func bytesToSize(_ bytes: Float) -> String {
        if bytes == 0 {
            return "0 Bytes"
        }

        var sizes = ["Bytes", "KB", "MB", "GB", "TB"]
        let i = Int(floor(log(bytes) / log(1000)))
        return String(format:"%.2f", Float(bytes / pow(1024.0, Float(i)))) + " " + sizes[i]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
