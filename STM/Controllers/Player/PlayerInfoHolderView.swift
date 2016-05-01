//
//  PlayerInfoHolderView.swift
//  STM
//
//  Created by Kesi Maduka on 3/4/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class PlayerInfoHolderView: UIView {

    var comments: Int = 0 {
        didSet {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                UIView.animateWithDuration(0.5) { () -> Void in
                    self.commentCount.text = String(self.comments)
                    self.layoutIfNeeded()
                }
            }
        }
    }

    var listeners: Int = 0 {
        didSet {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                UIView.animateWithDuration(0.5) { () -> Void in
                    self.listenerCount.text = String(self.listeners)
                    self.layoutIfNeeded()
                }
            }
        }
    }

    let commentCount = UILabel()
    let commentCountImageView = UIImageView(image: UIImage(named: "toolbar_comments"))

    let listenerCount = UILabel()
    let listenerCountImageView = UIImageView(image: UIImage(named: "toolbar_listeners"))

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.autoSetDimension(.Height, toSize: 16)

        listenerCount.hidden = true
        listenerCountImageView.hidden = true
        [commentCount, commentCountImageView, listenerCount, listenerCountImageView].forEach({ self.addSubview($0) })

        [commentCount, listenerCount].forEach({ $0.textColor = RGB(92, g: 38, b: 254) })
        [commentCount, listenerCount].forEach({ $0.font = UIFont.systemFontOfSize(13) })

        commentCountImageView.autoAlignAxisToSuperviewAxis(.Horizontal)
        commentCountImageView.autoPinEdgeToSuperviewEdge(.Left)

        commentCount.autoAlignAxis(.Horizontal, toSameAxisOfView: commentCountImageView)
        commentCount.autoPinEdge(.Left, toEdge: .Right, ofView: commentCountImageView, withOffset: 4)
        commentCount.autoPinEdgeToSuperviewEdge(.Right)

        /*
        listenerCountImageView.autoPinEdge(.Left, toEdge: .Right, ofView: commentCount, withOffset: 12)
        listenerCountImageView.autoAlignAxis(.Horizontal, toSameAxisOfView: commentCount)

        listenerCount.autoAlignAxis(.Horizontal, toSameAxisOfView: listenerCountImageView)
        listenerCount.autoPinEdge(.Left, toEdge: .Right, ofView: listenerCountImageView, withOffset: 4)
        listenerCount.autoPinEdgeToSuperviewEdge(.Right)
 */
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
