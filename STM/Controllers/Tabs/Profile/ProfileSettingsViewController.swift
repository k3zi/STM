//
//  ProfileSettingsViewController.swift
//  STM
//
//  Created by Kesi Maduka on 4/27/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import ALCameraViewController
import M13ProgressSuite

class ProfileSettingsViewController: KZViewController {

    let tableView = UITableView()
    var items = [Any]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Edit Profile"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerReusableCell(SettingsProfilePictureCell)
        tableView.backgroundColor = UIColor.whiteColor()

        let footerView = UIView()
        footerView.backgroundColor = RGB(250, g: 251, b: 252)
        let footerLabel = UILabel()
        if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String, let build = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String {
            footerLabel.text = "STM | Version: \(version) (\(build))"
        }
        footerLabel.textAlignment = .Center
        footerLabel.sizeToFit()
        footerView.addSubview(footerLabel)
        footerView.frame = footerLabel.frame
        footerLabel.frame.origin.y = 12
        footerView.frame.size.height += 24
        footerView.frame.size.width = Constants.UI.Screen.width
        footerLabel.frame.origin.x = (footerView.frame.size.width - footerLabel.frame.size.width)/2
        tableView.tableFooterView = footerView

        view.addSubview(tableView)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.tableView.reloadData()
    }

    override func setupConstraints() {
        super.setupConstraints()

        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        tableView.autoPinToBottomLayoutGuideOfViewController(self, withInset: 0)
    }

    override func tableViewCellData(tableView: UITableView, section: Int) -> [Any] {
        return items
    }

    override func tableViewCellClass(tableView: UITableView, indexPath: NSIndexPath? = nil) -> KZTableViewCell.Type {
        if indexPath?.row == 0 {
            return SettingsProfilePictureCell.self
        }

        return super.tableViewCellClass(tableView, indexPath: indexPath)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)

        let vc = CameraViewController(croppingEnabled: true) { image in
            self.dismissViewControllerAnimated(true, completion: nil)
            guard let image = image.0 else {
                return
            }

            guard let imageData = UIImagePNGRepresentation(resizeImage(image, newWidth: 200)) else {
                return
            }

            let progressView = M13ProgressViewRing()
            progressView.primaryColor = RGB(255)
            progressView.secondaryColor = Constants.UI.Color.disabled

            let hud = M13ProgressHUD(progressView: progressView)
            if let window = AppDelegate.del().window {
                hud.frame = window.bounds
            }
            hud.progressViewSize = CGSize(width: 60, height: 60)
            hud.animationPoint = CGPoint(x: hud.frame.size.width / 2, y: hud.frame.size.height / 2)
            hud.status = "Uploading Image"
            hud.applyBlurToBackground = true
            hud.maskType = M13ProgressHUDMaskTypeIOS7Blur
            AppDelegate.del().window?.addSubview(hud)
            hud.show(true)

            Constants.Network.UPLOAD("/upload/user/profilePicture", data: imageData, parameters: nil, progress: { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
                let progress = CGFloat(totalBytesWritten)/CGFloat(totalBytesExpectedToWrite)
                hud.setProgress(progress, animated: true)
            }, completionHandler: { (response, error) in
                hud.hide(true)
                self.handleResponse(response, error: error, successCompletion: { (result) in

                })
            })
        }

        presentViewController(vc, animated: true, completion: nil)
    }

    override func fetchData() {
        items.removeAll()
        items.append(STMSetting(json: ["id": 0, "name": "Profile Picture"]))
        tableView.reloadData()
    }

}
