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

    let commentCount = UILabel()
    let commentCountImageView = UIImageView(image: UIImage(named: "toolbar_comments"))

    let listenerCount = UILabel()
    let listenerCountImageView = UIImageView(image: UIImage(named: "toolbar_listeners"))

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.autoSetDimension(.height, toSize: 16)

        listenerCount.isHidden = true
        listenerCountImageView.isHidden = true
        [commentCount, commentCountImageView, listenerCount, listenerCountImageView].forEach({ self.addSubview($0) })

        [commentCount, listenerCount].forEach({ $0.textColor = RGB(92, g: 38, b: 254) })
        [commentCount, listenerCount].forEach({ $0.font = UIFont.systemFont(ofSize: 13) })

        commentCountImageView.autoAlignAxis(toSuperviewAxis: .horizontal)
        commentCountImageView.autoPinEdge(toSuperviewEdge: .left)

        commentCount.autoAlignAxis(.horizontal, toSameAxisOf: commentCountImageView)
        commentCount.autoPinEdge(.left, to: .right, of: commentCountImageView, withOffset: 4)
        commentCount.autoPinEdge(toSuperviewEdge: .right)

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
