//
//  SettingsUserCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import Kingfisher
import DateTools

class SettingsUserCell: KZTableViewCell, UITextFieldDelegate, UITextViewDelegate {
    let nameField = TextField(insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    let descriptionField = UITextView()

    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = RGB(255)

        nameField.backgroundColor = RGB(235, g: 236, b: 237)
        nameField.layer.cornerRadius = 5.0
        nameField.clipsToBounds = true
        nameField.delegate = self
        nameField.inputAccessoryView = cellToolbar()
        nameField.autocorrectionType = .no
        nameField.textAlignment = .center
        nameField.font = UIFont.systemFont(ofSize: 16)
        self.contentView.addSubview(nameField)

        descriptionField.backgroundColor = RGB(235, g: 236, b: 237)
        descriptionField.layer.cornerRadius = 5.0
        descriptionField.clipsToBounds = true
        descriptionField.delegate = self
        descriptionField.inputAccessoryView = cellToolbar()
        descriptionField.font = UIFont.systemFont(ofSize: 16)
        descriptionField.textAlignment = .center
        self.contentView.addSubview(descriptionField)
    }

    override func updateConstraints() {
        super.updateConstraints()

        nameField.autoPinEdge(toSuperviewEdge: .top, withInset: 12)
        nameField.autoPinEdge(toSuperviewEdge: .left, withInset: 12)
        nameField.autoPinEdge(toSuperviewEdge: .right, withInset: 12)
        NSLayoutConstraint.autoSetPriority(999) {
            self.nameField.autoSetDimension(.height, toSize: 35)
        }

        descriptionField.autoPinEdge(.top, to: .bottom, of: nameField, withOffset: 12)
        descriptionField.autoPinEdge(toSuperviewEdge: .left, withInset: 12)
        descriptionField.autoPinEdge(toSuperviewEdge: .right, withInset: 12)
        descriptionField.autoPinEdge(toSuperviewEdge: .bottom, withInset: 12)

        NSLayoutConstraint.autoSetPriority(999) {
            self.descriptionField.autoSetDimension(.height, toSize: 100)
        }
    }

    override func setIndexPath(_ indexPath: IndexPath, last: Bool) {
        topSeperator.alpha = 1.0
    }

    override func fillInCellData(_ shallow: Bool) {
        if let user = AppDelegate.del().currentUser {
            nameField.text = user.displayName
            descriptionField.text = user.description
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func cellToolbar() -> UIToolbar {
        let toolBar = UIToolbar()
        toolBar.barStyle = .black

        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.donePressed))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.cancelPressed))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.sizeToFit()
        return toolBar
    }

    func donePressed() {
        cancelPressed()
    }

    func cancelPressed() {
        self.endEditing(true)
    }

    //MARK: UITextView Delegate
    func textViewDidEndEditing(_ textView: UITextView) {
        guard let text = textView.text else {
            return
        }

        if textView == descriptionField {
            updateUser("description", value: text as AnyObject)
        }
    }

    func updateUser(_ property: String, value: AnyObject) {
        Constants.Network.POST("/user/update/\(property)", parameters: ["value": value]) { (response, error) in
            guard let response = response, let success = response["success"] as? Bool else {
                return
            }

            if success {
                guard let result = response["result"], let userResult = result as? JSON else {
                    return
                }

                if let user = STMUser(json: userResult) {
                    AppDelegate.del().currentUser = user
                }
            }
        }
    }

    //MARK: UITextField Delegate

    func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldShouldReturn(textField)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else {
            return false
        }

        guard text.characters.count > 0 else {
            return false
        }

        if textField == nameField {
            updateUser("displayName", value: text as AnyObject)
        }

        textField.resignFirstResponder()
        return false
    }

}
