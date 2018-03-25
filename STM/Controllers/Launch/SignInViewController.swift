//
//  InitialViewController.swift
//  STM
//
//  Created by Kesi Maduka on 1/29/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class SignInViewController: KZViewController {
    let crowdBG = UIImageView(image: UIImage(named: "crowdBG"))
    let crowdBGGradient = CAGradientLayer()
    let crowdBGGOverlay = CALayer()

    let backBT = UIButton.styleForBackButton()
    let usernameTextField = UITextField.styledForLaunchScreen()
    let passwordTextField = UITextField.styledForLaunchScreen()
    let emailTextField = UITextField.styledForLaunchScreen()
    let signInBT = UIButton.styledForLaunchScreen()

    override func viewDidLoad() {
        super.viewDidLoad()

        crowdBGGradient.colors = [RGB(0, a: 0.63).cgColor, RGB(255, a: 0).cgColor, RGB(255, a: 0).cgColor, RGB(0, a: 0.63).cgColor]
        crowdBGGradient.locations = [NSNumber(value: 0.0 as Float), NSNumber(value: 0.315 as Float), NSNumber(value: 0.685 as Float), NSNumber(value: 1.0 as Float)]
        crowdBG.layer.addSublayer(crowdBGGradient)

        crowdBGGOverlay.opacity = 0.66
        crowdBGGOverlay.backgroundColor = Constants.UI.Color.tint.cgColor
        crowdBG.layer.addSublayer(crowdBGGOverlay)

        crowdBG.contentMode = .scaleAspectFill
        view.addSubview(crowdBG)

        backBT.addTarget(self, action: #selector(self.popVC), for: .touchUpInside)
        view.addSubview(backBT)

        //Fields

        usernameTextField.placeholder = "Username"
        usernameTextField.unstyleField()
        view.addSubview(usernameTextField)

        passwordTextField.placeholder = "Password"
        passwordTextField.protectField()
        view.addSubview(passwordTextField)

        signInBT.setTitle("Sign In", for: UIControlState())
        signInBT.addTarget(self, action: #selector(SignInViewController.signIn), for: .touchUpInside)
        view.addSubview(signInBT)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        usernameTextField.becomeFirstResponder()
    }

    override func setupConstraints() {
        crowdBG.autoPinEdgesToSuperviewEdges()

        for view in [usernameTextField, passwordTextField, signInBT] {
            view.autoPinEdge(toSuperviewEdge: .left, withInset: 45)
            view.autoPinEdge(toSuperviewEdge: .right, withInset: 45)
            view.autoSetDimension(.height, toSize: 50)
        }

        backBT.autoPin(toTopLayoutGuideOf: self, withInset: 20)
        backBT.autoPinEdge(toSuperviewEdge: .left, withInset: 25)
        usernameTextField.autoPinEdge(.top, to: .bottom, of: backBT, withOffset: 30)
        passwordTextField.autoPinEdge(.top, to: .bottom, of: usernameTextField, withOffset: 15)
        signInBT.autoPinEdge(.top, to: .bottom, of: passwordTextField, withOffset: 15)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        crowdBGGradient.frame = crowdBG.bounds
        crowdBGGOverlay.frame = crowdBG.bounds
    }

    @objc func signIn() {
        guard let username = usernameTextField.text else {
            return showError("No Username Entered")
        }

        guard username.count > 0 else {
            return showError("No Username Entered")
        }

        guard let password = passwordTextField.text else {
            return showError("No Password Entered")
        }

        guard password.count > 0 else {
            return showError("No Password Entered")
        }

        signInBT.showIndicator()
        backBT.isEnabled = false

        Constants.Network.POST("/user/login", parameters: ["username": username, "password": password], completionHandler: { (response, error) -> Void in
            self.signInBT.hideIndicator()
            self.backBT.isEnabled = true
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                Constants.Settings.setSecretObject(result, forKey: "user")

                if let result = result as? JSON {
                    if let user = STMUser(json: result) {
                        AppDelegate.del().loginUser(user)
                        Answers.logLogin(withMethod: "Password", success: true, customAttributes: nil)
                    }
                }
            })
        })
    }

    @objc func popVC() {
        if let vc = self.navigationController {
            vc.popViewController(animated: true)
        }
    }

}
