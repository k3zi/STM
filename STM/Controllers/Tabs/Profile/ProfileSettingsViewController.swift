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
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: SettingsProfilePictureCell.self)
        tableView.register(cellType: SettingsUserCell.self)
        tableView.register(cellType: SettingsNameCell.self.self)
        tableView.backgroundColor = UIColor.white

        let footerView = UIView()
        footerView.backgroundColor = RGB(250, g: 251, b: 252)
        let footerLabel = UILabel()
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            footerLabel.text = "STM | Version: \(version) (\(build))"
        }
        footerLabel.textAlignment = .center
        footerLabel.sizeToFit()
        footerView.addSubview(footerLabel)
        footerView.frame = footerLabel.frame
        footerLabel.frame.origin.y = 12
        footerView.frame.size.height += 24
        footerView.frame.size.width = Constants.UI.Screen.width
        footerLabel.frame.origin.x = (footerView.frame.size.width - footerLabel.frame.size.width)/2
        tableView.tableFooterView = footerView

        view.addSubview(tableView)

        fetchOnce()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.tableView.reloadData()
    }

    override func setupConstraints() {
        super.setupConstraints()

        tableView.autoPin(toTopLayoutGuideOf: self, withInset: 0)
        tableView.autoPinEdge(toSuperviewEdge: .left)
        tableView.autoPinEdge(toSuperviewEdge: .right)
        tableView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)
    }

    override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        return items
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath? = nil) -> KZTableViewCell.Type {
        if indexPath?.row == 0 {
            return SettingsProfilePictureCell.self
        } else if indexPath?.row == 1 {
            return SettingsUserCell.self
        }

        return SettingsNameCell.self
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)

        if indexPath.row == 0 {
            changeProfilePiture()
        } else if indexPath.row == 2 {
            logoutUser()
        }
    }

    func fetchOnce() {
        items.removeAll()
        items.append(STMSetting(json: ["id": 0, "name": "Profile Picture"]))
        items.append(STMSetting(json: ["id": 1, "name": ""]))
        items.append(STMSetting(json: ["id": 2, "name": "Logout"]))
        tableView.reloadData()
    }

    func changeProfilePiture() {
        let params = CroppingParameters(isEnabled: true)
        let vc = CameraViewController(croppingParameters: params) { image, asset in
            guard let image = image else {
                return
            }

            self.dismiss(animated: true, completion: nil)

            guard let imageData = UIImagePNGRepresentation(resizeImage(image, newWidth: 200)) else {
                return
            }

            let progressView = M13ProgressViewRing()
            progressView.primaryColor = RGB(255)
            progressView.secondaryColor = Constants.UI.Color.disabled

            let hud = M13ProgressHUD(progressView: progressView)
            if let window = AppDelegate.del().window {
                hud?.frame = window.bounds
            }
            hud?.progressViewSize = CGSize(width: 60, height: 60)
            hud?.animationPoint = CGPoint(x: (hud?.frame.size.width)! / 2, y: (hud?.frame.size.height)! / 2)
            hud?.status = "Uploading Image"
            hud?.applyBlurToBackground = true
            hud?.maskType = M13ProgressHUDMaskTypeIOS7Blur
            AppDelegate.del().window?.addSubview(hud!)
            hud?.show(true)

            Constants.Network.UPLOAD("/user/upload/profilePicture", data: imageData, progressHandler: { (progress) in
                hud?.setProgress(CGFloat(progress), animated: true)
                }, completionHandler: { (response, error) in
                    hud?.hide(true)
                    self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) in
                        guard let result = result as? JSON, let user = STMUser(json: result) else {
                            return
                        }

                        AppDelegate.del().currentUser = user
                    })
            })
        }

        present(vc, animated: true, completion: nil)
    }

    func logoutUser() {
        guard let window = AppDelegate.del().window else {
            return
        }

        AppDelegate.del().currentUser = nil
        Constants.Settings.set(nil, forKey: "user")

        let nav = NavigationController(rootViewController: InitialViewController())
        nav.setNavigationBarHidden(true, animated: false)
        UIView.transition(with: window, duration: 0.5, options: UIViewAnimationOptions.transitionCrossDissolve, animations: {
            AppDelegate.del().window?.rootViewController = nav
            }, completion: { (finished) -> Void in
        })
    }
}
