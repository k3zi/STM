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
	func handlePost(_ text: String)
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
		toolBar.returnKeyType = .default
		toolBar.delegate = self
		toolBar.font = UIFont.systemFont(ofSize: 15)
		toolBar.textColor = RGB(255)
		toolBar.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0)
		toolBar.backgroundColor = UIColor.clear
		toolBar.placeholder = "Type a new comment..."
		heightTextContConstraint = toolBar.autoSetDimension(.height, toSize: 30)
		toolBarContainer.addSubview(toolBar)

		sendBT.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
		sendBT.addTarget(self, action: #selector(MessageToolbarView.send), for: .touchUpInside)
		sendBT.setTitle("Post", for: .normal)
		sendBT.setTitleColor(RGB(255), for: .normal)
		toolBarContainer.addSubview(sendBT)

		toolBarContainer.autoPinEdgesToSuperviewEdges()

		toolBar.autoPinEdge(toSuperviewEdge: .left, withInset: 10)
		toolBar.autoPinEdge(toSuperviewEdge: .top, withInset: 5)
		toolBar.autoPinEdge(toSuperviewEdge: .bottom, withInset: 5)

		sendBT.autoPinEdge(.left, to: .right, of: toolBar, withOffset: 10)
		sendBT.autoPinEdge(toSuperviewEdge: .right, withInset: 25)
		sendBT.autoPinEdge(toSuperviewEdge: .bottom, withInset: 7)

		toolBar.refreshHeight()
	}

    func growingTextViewDidBeginEditing(_ growingTextView: HPGrowingTextView!) {
        self.delegate?.didBeginEditing()
        perform(#selector(placeCursorAtEnd), with: growingTextView, afterDelay: 0.02)
    }

	func growingTextView(_ growingTextView: HPGrowingTextView!, willChangeHeight height: Float) {
		UIView.animate(withDuration: 0.4, animations: { () -> Void in
			self.heightTextContConstraint?.constant = CGFloat(height)
			self.layoutIfNeeded()
		}) 
	}

	func growingTextView(_ growingTextView: HPGrowingTextView!, shouldChangeTextIn range: NSRange, replacementText text: String!) -> Bool {
		let currentText = growingTextView.text as NSString
		let proposedText = currentText.replacingCharacters(in: range, with: text)
		if proposedText.characters.count > 150 {
			return false
		}

		if proposedText.components(separatedBy: "\n").count > 3 {
			return false
		}

		return true
	}

    func placeCursorAtEnd(_ growingTextView: HPGrowingTextView) {
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

        UIView.transition(with: toolBar, duration: 0.4, options: .transitionCrossDissolve, animations: { () -> Void in
            self.toolBar.text = prefillText
        }, completion: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
