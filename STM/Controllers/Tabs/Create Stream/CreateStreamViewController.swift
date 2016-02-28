//
//  CreateStreamViewController.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import KMPlaceholderTextView

class CreateStreamViewController: KZScrollViewController {

    let streamTypeSegmentControl = UISegmentedControl(items: ["Global", "Local"])
    let streamNameTextField = UITextField()
    let privacySwitch = UISwitch()
    let passcodeTextField = UITextField()
    let streamDescriptionTextView = KMPlaceholderTextView()
    let hostBT = UIButton()

    let publicLabel = UILabel()
    let privateLabel = UILabel()
    let tableView = KZIntrinsicTableView()
    var items = [Any]()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        view.backgroundColor = RGB(234)

        streamTypeSegmentControl.selectedSegmentIndex = 0
        streamTypeSegmentControl.tintColor = Constants.Color.tint
        contentView.addSubview(streamTypeSegmentControl)

        streamNameTextField.layer.cornerRadius = 5
        streamNameTextField.clipsToBounds = true
        streamNameTextField.placeholder = "Stream Name"
        streamNameTextField.textAlignment = .Center
        streamNameTextField.backgroundColor = RGB(255)
        streamNameTextField.autocorrectionType = .No
        contentView.addSubview(streamNameTextField)

        passcodeTextField.layer.cornerRadius = 5
        passcodeTextField.clipsToBounds = true
        passcodeTextField.placeholder = "Passcode"
        passcodeTextField.textAlignment = .Center
        passcodeTextField.backgroundColor = RGB(255)
        passcodeTextField.autocorrectionType = .No
        passcodeTextField.keyboardType = .NumberPad
        passcodeTextField.secureTextEntry = true
        passcodeTextField.alpha = 0.7
        passcodeTextField.enabled = false
        contentView.addSubview(passcodeTextField)

        privacySwitch.addTarget(self, action: Selector("togglePrivacy"), forControlEvents: .ValueChanged)
        contentView.addSubview(privacySwitch)

        publicLabel.text = "Public Stream"
        contentView.addSubview(publicLabel)

        privateLabel.text = "Private Stream"
        contentView.addSubview(privateLabel)

        streamDescriptionTextView.font = UIFont.systemFontOfSize(15)
        streamDescriptionTextView.layer.cornerRadius = 5
        streamDescriptionTextView.clipsToBounds = true
        streamDescriptionTextView.placeholder = "Stream Description..."
        streamDescriptionTextView.backgroundColor = RGB(255)
        streamDescriptionTextView.textContainerInset = UIEdgeInsetsMake(15, 15, 15, 15)
        streamDescriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(streamDescriptionTextView)

        hostBT.setTitle("Host", forState: .Normal)
        hostBT.titleLabel?.font = UIFont.systemFontOfSize(15, weight: UIFontWeightMedium)
        hostBT.setTitleColor(Constants.Color.tint, forState: .Normal)
        hostBT.setBackgroundColor(UIColor.clearColor(), forState: .Normal)
        hostBT.setTitleColor(RGB(255), forState: .Highlighted)
        hostBT.setBackgroundColor(Constants.Color.tint, forState: .Highlighted)
        hostBT.clipsToBounds = true
        hostBT.layer.cornerRadius = 5
        hostBT.layer.borderColor = Constants.Color.tint.CGColor
        hostBT.layer.borderWidth = 1
        hostBT.addTarget(self, action: Selector("host"), forControlEvents: .TouchUpInside)
        contentView.addSubview(hostBT)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.alwaysBounceVertical = false
        tableView.bounces = false
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = RGB(255)
        tableView.registerReusableCell(HostStreamCell)
        contentView.addSubview(tableView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        streamTypeSegmentControl.autoPinEdgeToSuperviewEdge(.Top, withInset: 15)
        streamTypeSegmentControl.autoPinEdgeToSuperviewEdge(.Left, withInset: 15)
        streamTypeSegmentControl.autoPinEdgeToSuperviewEdge(.Right, withInset: 15)
        streamTypeSegmentControl.autoSetDimension(.Height, toSize: 30)

        streamNameTextField.autoPinEdge(.Top, toEdge: .Bottom, ofView: streamTypeSegmentControl, withOffset: 15)
        streamNameTextField.autoPinEdgeToSuperviewEdge(.Left, withInset: 15)
        streamNameTextField.autoPinEdgeToSuperviewEdge(.Right, withInset: 15)
        streamNameTextField.autoSetDimension(.Height, toSize: 50)

        privacySwitch.autoPinEdge(.Top, toEdge: .Bottom, ofView: streamNameTextField, withOffset: 15)
        privacySwitch.autoAlignAxisToSuperviewAxis(.Vertical)
        privacySwitch.autoPinEdge(.Left, toEdge: .Right, ofView: publicLabel, withOffset: 15)
        publicLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: privacySwitch)
        privateLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: privacySwitch)
        privateLabel.autoPinEdge(.Left, toEdge: .Right, ofView: privacySwitch, withOffset: 15)

        passcodeTextField.autoPinEdge(.Top, toEdge: .Bottom, ofView: privacySwitch, withOffset: 15)
        passcodeTextField.autoPinEdgeToSuperviewEdge(.Left, withInset: 15)
        passcodeTextField.autoPinEdgeToSuperviewEdge(.Right, withInset: 15)
        passcodeTextField.autoSetDimension(.Height, toSize: 50)

        streamDescriptionTextView.autoPinEdge(.Top, toEdge: .Bottom, ofView: passcodeTextField, withOffset: 15)
        streamDescriptionTextView.autoPinEdgeToSuperviewEdge(.Left, withInset: 15)
        streamDescriptionTextView.autoPinEdgeToSuperviewEdge(.Right, withInset: 15)
        streamDescriptionTextView.autoSetDimension(.Height, toSize: 100)

        hostBT.autoPinEdge(.Top, toEdge: .Bottom, ofView: streamDescriptionTextView, withOffset: 15)
        hostBT.autoPinEdgeToSuperviewEdge(.Left, withInset: 15)
        hostBT.autoPinEdgeToSuperviewEdge(.Right, withInset: 15)
        hostBT.autoSetDimension(.Height, toSize: 50)

        tableView.autoPinEdge(.Top, toEdge: .Bottom, ofView: hostBT, withOffset: 15)
        tableView.autoPinEdgeToSuperviewEdge(.Left)
        tableView.autoPinEdgeToSuperviewEdge(.Right)
        tableView.autoPinEdgeToSuperviewEdge(.Bottom)
    }

    func togglePrivacy() {
        passcodeTextField.enabled = privacySwitch.on
        passcodeTextField.text = ""
        passcodeTextField.alpha = privacySwitch.on ? 1.0 : 0.7
    }

    func host() {
        guard let name = streamNameTextField.text else {
            return showError("No Stream Name Entered")
        }

        guard name.characters.count > 0 else {
            return showError("No Stream Name Entered")
        }

        guard let description = streamDescriptionTextView.text else {
            return showError("No Description Entered")
        }

        guard description.characters.count > 0 else {
            return showError("No Description Entered")
        }

        let vc = HostViewController()
        let streamType = streamTypeSegmentControl.selectedSegmentIndex == 0 ? StreamType.Global : StreamType.Local
        let passcodeString = privacySwitch.on ? (passcodeTextField.text ?? "") : ""
        vc.start(streamType, name: name, passcode: passcodeString, description: description) { (nothing, error) -> Void in
            if error == nil {
                self.navigationController?.tabBarController?.presentViewController(vc, animated: true, completion: nil)
            }
        }
    }

    //MARK: Table View Delegate

    override func tableViewCellData(tableView: UITableView, section: Int) -> [Any] {
        return items
    }

    override func tableViewCellClass(tableView: UITableView, indexPath: NSIndexPath?) -> KZTableViewCell.Type {
        return HostStreamCell.self
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)

        if let stream = items[indexPath.row] as? STMStream {
            let vc = HostViewController()
            vc.start(stream) { (nothing, error) -> Void in
                if error == nil {
                    self.navigationController?.tabBarController?.presentViewController(vc, animated: true, completion: nil)
                }
            }
        }
    }

    //MARK: Cell Deletion

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            guard let stream = items[indexPath.row] as? STMStream else {
                return
            }

            guard let streamID = stream.id else {
                return
            }

            Constants.Network.GET("/delete/stream/" + String(streamID), parameters: nil, completionHandler: { (response, error) -> Void in
                self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                    self.items.removeAtIndex(indexPath.row)
                    tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
                    self.fetchData()
                })
            })
        }
    }

    //MARK: Data Functions

    override func fetchData() {
        Constants.Network.GET("/streams/user/0", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                self.items.removeAll()
                if let result = result as? [JSON] {
                    let streams = [STMStream].fromJSONArray(result)
                    streams.forEach({ self.items.append($0) })
                    self.tableView.reloadData()
                }
            })
        }
    }
}
