//
//  MessageToolbarView.swift
//  STM
//
//  Created by Kesi Maduka on 2/23/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import HPGrowingTextView

protocol MessageToolbarDelegate {
	func handlePost(text: String)
    func messageToolbarPrefillText() -> String
    func didBeginEditing()
}

class MessageToolbarView: UIView, HPGrowingTextViewDelegate {
	let toolBarContainer = UIView()
	let toolBar = HPGrowingTextView()
	var heightTextContConstraint: NSLayoutConstraint?
	let sendBT = ExtendedButton()
	var delegate: MessageToolbarDelegate?

	init() {
		super.init(frame: CGRect.zero)
		self.translatesAutoresizingMaskIntoConstraints = false

		toolBarContainer.backgroundColor = RGB(0, a: 0.5)
		self.addSubview(toolBarContainer)

		toolBar.isScrollable = false
		toolBar.contentInset = UIEdgeInsetsMake(0, 5, 0, 5)
		toolBar.minNumberOfLines = 1
		toolBar.maxNumberOfLines = 3
		toolBar.returnKeyType = .Default
		toolBar.delegate = self
		toolBar.font = UIFont.systemFontOfSize(15)
		toolBar.textColor = RGB(255)
		toolBar.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0)
		toolBar.backgroundColor = UIColor.clearColor()
		toolBar.placeholder = "Type a new comment..."
		heightTextContConstraint = toolBar.autoSetDimension(.Height, toSize: 30)
		toolBarContainer.addSubview(toolBar)

		sendBT.titleLabel?.font = UIFont.boldSystemFontOfSize(16)
		sendBT.addTarget(self, action: #selector(MessageToolbarView.send), forControlEvents: .TouchUpInside)
		sendBT.setTitle("Post", forState: .Normal)
		sendBT.setTitleColor(RGB(255), forState: .Normal)
		toolBarContainer.addSubview(sendBT)

		toolBarContainer.autoPinEdgesToSuperviewEdges()

		toolBar.autoPinEdgeToSuperviewEdge(.Left, withInset: 10)
		toolBar.autoPinEdgeToSuperviewEdge(.Top, withInset: 5)
		toolBar.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 5)

		sendBT.autoPinEdge(.Left, toEdge: .Right, ofView: toolBar, withOffset: 10)
		sendBT.autoPinEdgeToSuperviewEdge(.Right, withInset: 25)
		sendBT.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 7)

		toolBar.refreshHeight()
	}

    func growingTextViewDidBeginEditing(growingTextView: HPGrowingTextView!) {
        self.delegate?.didBeginEditing()
        performSelector(#selector(placeCursorAtEnd), withObject: growingTextView, afterDelay: 0.02)
    }

	func growingTextView(growingTextView: HPGrowingTextView!, willChangeHeight height: Float) {
		UIView.animateWithDuration(0.4) { () -> Void in
			self.heightTextContConstraint?.constant = CGFloat(height)
			self.layoutIfNeeded()
		}
	}

	func growingTextView(growingTextView: HPGrowingTextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool {
		let currentText = growingTextView.text as NSString
		let proposedText = currentText.stringByReplacingCharactersInRange(range, withString: text)
		if proposedText.characters.count > 150 {
			return false
		}

		if proposedText.componentsSeparatedByString("\n").count > 3 {
			return false
		}

		return true
	}

    func placeCursorAtEnd(growingTextView: HPGrowingTextView) {
        growingTextView.selectedRange = NSRange(location: growingTextView.text.characters.count, length: 0)
    }

	func send() {
        guard let currentText = toolBar.text else {
            return
        }

        guard let delegate = delegate else {
            return
        }

        delegate.handlePost(currentText)

        let prefillText = delegate.messageToolbarPrefillText()

        UIView.transitionWithView(toolBar, duration: 0.4, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.toolBar.text = prefillText
        }, completion: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
