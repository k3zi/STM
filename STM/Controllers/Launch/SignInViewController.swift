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

        crowdBGGradient.colors = [RGB(0, a: 0.63).CGColor, RGB(255, a: 0).CGColor, RGB(255, a: 0).CGColor, RGB(0, a: 0.63).CGColor]
        crowdBGGradient.locations = [NSNumber(float: 0.0), NSNumber(float: 0.315), NSNumber(float: 0.685), NSNumber(float: 1.0)]
        crowdBG.layer.addSublayer(crowdBGGradient)

        crowdBGGOverlay.opacity = 0.66
        crowdBGGOverlay.backgroundColor = Constants.Color.tint.CGColor
        crowdBG.layer.addSublayer(crowdBGGOverlay)

        crowdBG.contentMode = .ScaleAspectFill
        view.addSubview(crowdBG)

        backBT.addTarget(self, action: #selector(SignInViewController.dismiss), forControlEvents: .TouchUpInside)
        view.addSubview(backBT)

        //Fields

        usernameTextField.placeholder = "Username"
        usernameTextField.unstyleField()
        view.addSubview(usernameTextField)

        passwordTextField.placeholder = "Password"
        passwordTextField.protectField()
        view.addSubview(passwordTextField)

        signInBT.setTitle("Sign In", forState: .Normal)
        signInBT.addTarget(self, action: #selector(SignInViewController.signIn), forControlEvents: .TouchUpInside)
        view.addSubview(signInBT)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        usernameTextField.becomeFirstResponder()
    }

    override func setupConstraints() {
        crowdBG.autoPinEdgesToSuperviewEdges()

        for view in [usernameTextField, passwordTextField, signInBT] {
            view.autoPinEdgeToSuperviewEdge(.Left, withInset: 45)
            view.autoPinEdgeToSuperviewEdge(.Right, withInset: 45)
            view.autoSetDimension(.Height, toSize: 50)
        }

        backBT.autoPinToTopLayoutGuideOfViewController(self, withInset: 20)
        backBT.autoPinEdgeToSuperviewEdge(.Left, withInset: 25)
        usernameTextField.autoPinEdge(.Top, toEdge: .Bottom, ofView: backBT, withOffset: 30)
        passwordTextField.autoPinEdge(.Top, toEdge: .Bottom, ofView: usernameTextField, withOffset: 15)
        signInBT.autoPinEdge(.Top, toEdge: .Bottom, ofView: passwordTextField, withOffset: 15)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        crowdBGGradient.frame = crowdBG.bounds
        crowdBGGOverlay.frame = crowdBG.bounds
    }

    func signIn() {
        guard let username = usernameTextField.text else {
            return showError("No Username Entered")
        }

        guard username.characters.count > 0 else {
            return showError("No Username Entered")
        }

        guard let password = passwordTextField.text else {
            return showError("No Password Entered")
        }

        guard password.characters.count > 0 else {
            return showError("No Password Entered")
        }

        signInBT.showIndicator()
        backBT.enabled = false

        Constants.Network.POST("/signIn", parameters: ["username": username, "password": password], completionHandler: { (response, error) -> Void in
            self.signInBT.hideIndicator()
            self.backBT.enabled = true
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                Constants.Settings.setSecretObject(result, forKey: "user")

                if let result = result as? JSON {
                    if let user = STMUser(json: result) {
                        AppDelegate.del().loginUser(user)
                        Answers.logLoginWithMethod("Password", success: true, customAttributes: nil)
                    }
                }
            })
        })
    }

    func dismiss() {
        if let vc = self.navigationController {
            vc.popViewControllerAnimated(true)
        }
    }

}
