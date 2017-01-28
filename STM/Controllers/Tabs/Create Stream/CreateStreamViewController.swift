//
//  CreateStreamViewController.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import KMPlaceholderTextView

class CreateStreamViewController: KZViewController {

    var scrollView = UIScrollView()
    var contentView = UIView()

    let streamTypeSegmentControl = UISegmentedControl(items: ["Global", "Local"])
    let streamNameTextField = UITextField()
    let privacySwitch = UISwitch()
    let passcodeTextField = UITextField()
    let streamDescriptionTextView = KMPlaceholderTextView()
    let hostBT = UIButton()

    let categoryRadioBT = UIButton()
    let categoryPodcastBT = UIButton()
    let categoryLiveBT = UIButton()
    var selectedCategory = STMStreamType.radio

    // UI Adjustments
    lazy var keynode: Keynode.Connector = Keynode.Connector(view: self.contentView)
    var scrollViewBottomConstraint: NSLayoutConstraint?
    var passcodeHeightConstraint: NSLayoutConstraint?
    var passcodePaddingConstraint: NSLayoutConstraint?

    let formPadding = CGFloat(15)

    let publicLabel = UILabel()
    let privateLabel = UILabel()
    let tableView = KZIntrinsicTableView()
    var items = [Any]()

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
        view.backgroundColor = RGB(241, g: 242, b: 243)

        streamTypeSegmentControl.selectedSegmentIndex = 0
        streamTypeSegmentControl.tintColor = Constants.UI.Color.tint
        //contentView.addSubview(streamTypeSegmentControl)

        streamNameTextField.layer.cornerRadius = 5
        streamNameTextField.clipsToBounds = true
        streamNameTextField.placeholder = "Stream Name"
        streamNameTextField.textAlignment = .center
        streamNameTextField.backgroundColor = RGB(255)
        streamNameTextField.autocorrectionType = .no
        streamNameTextField.inputAccessoryView = UIToolbar.styleWithButtons(self)
        contentView.addSubview(streamNameTextField)

        passcodeTextField.layer.cornerRadius = 5
        passcodeTextField.clipsToBounds = true
        passcodeTextField.placeholder = "Passcode"
        passcodeTextField.textAlignment = .center
        passcodeTextField.backgroundColor = RGB(255)
        passcodeTextField.autocorrectionType = .no
        passcodeTextField.keyboardType = .numberPad
        passcodeTextField.isSecureTextEntry = true
        passcodeTextField.alpha = 0.7
        passcodeTextField.isEnabled = false
        passcodeTextField.inputAccessoryView = UIToolbar.styleWithButtons(self)
        //contentView.addSubview(passcodeTextField)

        categoryRadioBT.setImage(UIImage(named: "category_radioBT"), for: UIControlState())
        categoryRadioBT.tag = 0
        categoryRadioBT.addTarget(self, action: #selector(selectedType), for: .touchUpInside)
        contentView.addSubview(categoryRadioBT)

        categoryPodcastBT.setImage(UIImage(named: "category_podcastBT"), for: UIControlState())
        categoryPodcastBT.tag = 1
        categoryPodcastBT.alpha = 0.5
        categoryPodcastBT.addTarget(self, action: #selector(selectedType), for: .touchUpInside)
        contentView.addSubview(categoryPodcastBT)

        categoryLiveBT.setImage(UIImage(named: "category_liveBT"), for: UIControlState())
        categoryLiveBT.tag = 2
        categoryLiveBT.alpha = 0.5
        categoryLiveBT.addTarget(self, action: #selector(selectedType), for: .touchUpInside)
        contentView.addSubview(categoryLiveBT)

        privacySwitch.addTarget(self, action: #selector(CreateStreamViewController.togglePrivacy), for: .valueChanged)
        //contentView.addSubview(privacySwitch)

        publicLabel.text = "Public Stream"
        //contentView.addSubview(publicLabel)

        privateLabel.text = "Private Stream"
        //contentView.addSubview(privateLabel)

        streamDescriptionTextView.font = UIFont.systemFont(ofSize: 15)
        streamDescriptionTextView.layer.cornerRadius = 5
        streamDescriptionTextView.clipsToBounds = true
        streamDescriptionTextView.placeholder = "Stream Description..."
        streamDescriptionTextView.backgroundColor = RGB(255)
        streamDescriptionTextView.textContainerInset = UIEdgeInsetsMake(formPadding, formPadding, formPadding, formPadding)
        streamDescriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        streamDescriptionTextView.inputAccessoryView = UIToolbar.styleWithButtons(self)
        contentView.addSubview(streamDescriptionTextView)

        hostBT.setTitle("Host", for: UIControlState())
        hostBT.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightMedium)
        hostBT.setTitleColor(Constants.UI.Color.tint, for: .normal)
        hostBT.setBackgroundColor(UIColor.clear, forState: .normal)
        hostBT.setTitleColor(RGB(255), for: .highlighted)
        hostBT.setBackgroundColor(Constants.UI.Color.tint, forState: .highlighted)
        hostBT.clipsToBounds = true
        hostBT.layer.cornerRadius = 5
        hostBT.layer.borderColor = Constants.UI.Color.tint.cgColor
        hostBT.layer.borderWidth = 1
        hostBT.addTarget(self, action: #selector(CreateStreamViewController.host), for: .touchUpInside)
        contentView.addSubview(hostBT)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.alwaysBounceVertical = false
        tableView.bounces = false
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = RGB(255)
        tableView.registerReusableCell(HostStreamCell.self)
        contentView.addSubview(tableView)

        keynode.animationsHandler = { [weak self] show, rect in
            guard let me = self else {
                return
            }

            if let con = me.scrollViewBottomConstraint {
                con.constant = (show ? -rect.size.height + 54 + (AppDelegate.del().playerIsMinimized() ? 44 : 0) : 0)
                me.view.layoutIfNeeded()
            }
        }

        self.title = "Host Stream"
        self.navigationController?.tabBarItem.title = "      "
        fetchData()
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)
        scrollViewBottomConstraint = scrollView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)

        contentView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)
        contentView.autoMatch(.width, to: .width, of: view)

        /*streamTypeSegmentControl.autoPinEdgeToSuperviewEdge(.Top, withInset: formPadding)
        streamTypeSegmentControl.autoPinEdgeToSuperviewEdge(.Left, withInset: formPadding)
        streamTypeSegmentControl.autoPinEdgeToSuperviewEdge(.Right, withInset: formPadding)
        streamTypeSegmentControl.autoSetDimension(.Height, toSize: 30)*/

        streamNameTextField.autoPinEdge(toSuperviewEdge: .top, withInset: formPadding)
        //streamNameTextField.autoPinEdge(.Top, toEdge: .Bottom, ofView: streamTypeSegmentControl, withOffset: formPadding)
        streamNameTextField.autoPinEdge(toSuperviewEdge: .left, withInset: formPadding)
        streamNameTextField.autoPinEdge(toSuperviewEdge: .right, withInset: formPadding)
        streamNameTextField.autoSetDimension(.height, toSize: 50)

        categoryRadioBT.autoPinEdge(.top, to: .bottom, of: streamNameTextField, withOffset: formPadding)
        categoryRadioBT.autoPinEdge(toSuperviewEdge: .left, withInset: formPadding)

        categoryPodcastBT.autoAlignAxis(.horizontal, toSameAxisOf: categoryRadioBT)
        categoryPodcastBT.autoMatch(.width, to: .width, of: categoryRadioBT)
        categoryPodcastBT.autoMatch(.height, to: .height, of: categoryRadioBT)
        categoryPodcastBT.autoPinEdge(.left, to: .right, of: categoryRadioBT, withOffset: formPadding)

        categoryLiveBT.autoAlignAxis(.horizontal, toSameAxisOf: categoryPodcastBT)
        categoryLiveBT.autoMatch(.width, to: .width, of: categoryPodcastBT)
        categoryLiveBT.autoMatch(.height, to: .height, of: categoryPodcastBT)
        categoryLiveBT.autoPinEdge(.left, to: .right, of: categoryPodcastBT, withOffset: formPadding)
        categoryLiveBT.autoPinEdge(toSuperviewEdge: .right, withInset: formPadding)

        /*privacySwitch.autoPinEdge(.Top, toEdge: .Bottom, ofView: streamNameTextField, withOffset: formPadding)
        privacySwitch.autoAlignAxisToSuperviewAxis(.Vertical)
        privacySwitch.autoPinEdge(.Left, toEdge: .Right, ofView: publicLabel, withOffset: formPadding)
        publicLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: privacySwitch)
        privateLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: privacySwitch)
        privateLabel.autoPinEdge(.Left, toEdge: .Right, ofView: privacySwitch, withOffset: formPadding)*/

        /*passcodePaddingConstraint = passcodeTextField.autoPinEdge(.Top, toEdge: .Bottom, ofView: privacySwitch, withOffset: 0)
        passcodeTextField.autoPinEdgeToSuperviewEdge(.Left, withInset: formPadding)
        passcodeTextField.autoPinEdgeToSuperviewEdge(.Right, withInset: formPadding)
        passcodeHeightConstraint = passcodeTextField.autoSetDimension(.Height, toSize: 0)*/

        streamDescriptionTextView.autoPinEdge(.top, to: .bottom, of: categoryRadioBT, withOffset: formPadding)
        streamDescriptionTextView.autoPinEdge(toSuperviewEdge: .left, withInset: formPadding)
        streamDescriptionTextView.autoPinEdge(toSuperviewEdge: .right, withInset: formPadding)
        streamDescriptionTextView.autoSetDimension(.height, toSize: 100)

        hostBT.autoPinEdge(.top, to: .bottom, of: streamDescriptionTextView, withOffset: formPadding)
        hostBT.autoPinEdge(toSuperviewEdge: .left, withInset: formPadding)
        hostBT.autoPinEdge(toSuperviewEdge: .right, withInset: formPadding)
        hostBT.autoSetDimension(.height, toSize: 50)

        tableView.autoPinEdge(.top, to: .bottom, of: hostBT, withOffset: 15)
        tableView.autoPinEdge(toSuperviewEdge: .left)
        tableView.autoPinEdge(toSuperviewEdge: .right)
        tableView.autoPinEdge(toSuperviewEdge: .bottom)
    }

    func selectedType(_ button: UIButton) {
        for x in [categoryLiveBT, categoryPodcastBT, categoryRadioBT] {
            x.alpha = (button == x) ? 1.0 : 0.5
        }

        if let type = STMStreamType(rawValue: button.tag) {
            selectedCategory = type
        }
    }

    func togglePrivacy() {
        let enabled = privacySwitch.isOn
        passcodeTextField.isEnabled = enabled
        passcodeTextField.text = ""
        passcodeTextField.alpha = enabled ? 1.0 : 0.7

        UIView.animate(withDuration: 0.2, animations: {
            self.passcodeHeightConstraint?.constant = enabled ? 50.0 : 0.0
            self.passcodePaddingConstraint?.constant = enabled ? 14.0 : 0.0
            self.view.layoutIfNeeded()
        }) 
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

        guard AppDelegate.del().activeStreamController == nil else {
            return showError("You are already hosting/playing a stream. Please close it before starting another")
        }

        let vc = HostViewController()
        //let streamType = streamTypeSegmentControl.selectedSegmentIndex == 0 ? StreamType.Global : StreamType.Local
        let passcodeString = privacySwitch.isOn ? (passcodeTextField.text ?? "") : ""
        vc.start(selectedCategory, name: name, passcode: passcodeString, description: description) { (nothing, error) -> Void in
            if error == nil {
                self.streamNameTextField.text = nil
                self.selectedType(self.categoryRadioBT)
                self.streamDescriptionTextView.text = nil
                AppDelegate.del().presentStreamController(vc)
            }
        }
    }

    // MARK: Table View Delegate

    override func tableViewNoDataText(_ tableView: UITableView) -> String {
        return "You haven't created a stream yet"
    }

    override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        return items
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        return HostStreamCell.self
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)

        guard self.tableViewCellData(tableView, section: indexPath.section).count > 0 else {
            return
        }

        if let activeVC = AppDelegate.del().activeStreamController {
            return activeVC.showError("You are already hosting/playing a stream. Please close it before starting another")
        }

        if let stream = self.tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? STMStream {
            let vc = HostViewController()
            vc.start(stream) { (nothing, error) -> Void in
                if error == nil {
                    AppDelegate.del().presentStreamController(vc)
                }
            }
        }
    }

    // MARK: Cell Deletion

    func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let stream = items[indexPath.row] as? STMStream else {
                return
            }

            Constants.Network.GET("/stream/\(stream.id)/delete", parameters: nil, completionHandler: { (response, error) -> Void in
                self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                    self.items.remove(at: indexPath.row)
                    tableView.reloadSections(NSIndexSet(index: 0) as IndexSet, with: .fade)
                    self.fetchData()
                })
            })
        }
    }

    // MARK: Data Functions

    override func fetchData() {
        guard let user = AppDelegate.del().currentUser else {
            return
        }

        Constants.Network.GET("/user/\(user.id)/streams", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                self.items.removeAll()
                if let result = result as? [JSON] {
                    let streams = [STMStream].fromJSONArray(result)
                    streams?.forEach({ self.items.append($0) })
                    self.tableView.reloadData()
                }
            })
        }
    }
}
