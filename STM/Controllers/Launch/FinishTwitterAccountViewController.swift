//
//  FinishTwitterAccountViewController.swift
//  STM
//
//  Created by Kesi Maduka on 1/29/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import TwitterKit

class FinishTwitterAccountViewController: KZViewController {
    let crowdBG = UIImageView(image: UIImage(named: "crowdBG"))
    let crowdBGGradient = CAGradientLayer()
    let crowdBGGOverlay = CALayer()

    let backBT = UIButton.styleForBackButton()
    let displayNameTextField = UITextField.styledForLaunchScreen()
    let usernameTextField = UITextField.styledForLaunchScreen()
    let passwordTextField = UITextField.styledForLaunchScreen()
    let emailTextField = UITextField.styledForLaunchScreen()
    let createAccountBT = UIButton.styledForLaunchScreen()

    let session: TWTRSession
    let usernameAvailable: Bool
    let welcomeLabel = UILabel()

    init(session: TWTRSession, usernameAvailable: Bool) {
        self.session = session
        self.usernameAvailable = usernameAvailable
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        crowdBGGradient.colors = [RGB(0, a: 0.63).CGColor, RGB(255, a: 0).CGColor, RGB(255, a: 0).CGColor, RGB(0, a: 0.63).CGColor]
        crowdBGGradient.locations = [NSNumber(float: 0.0), NSNumber(float: 0.315), NSNumber(float: 0.685), NSNumber(float: 1.0)]
        crowdBG.layer.addSublayer(crowdBGGradient)

        crowdBGGOverlay.opacity = 0.66
        crowdBGGOverlay.backgroundColor = Constants.UI.Color.tint.CGColor
        crowdBG.layer.addSublayer(crowdBGGOverlay)

        crowdBG.contentMode = .ScaleAspectFill
        view.addSubview(crowdBG)

        backBT.addTarget(self, action: #selector(CreateAccountViewController.dismiss), forControlEvents: .TouchUpInside)
        view.addSubview(backBT)

        welcomeLabel.text = "Hi" + (usernameAvailable ? " @\(session.userName)!" : "! Unfortunately this username isn't available. Please pick another:")
        welcomeLabel.textColor = RGB(255)
        welcomeLabel.font = UIFont.systemFontOfSize(20)
        welcomeLabel.numberOfLines = 0
        welcomeLabel.textAlignment = .Center
        view.addSubview(welcomeLabel)

        //Fields

        displayNameTextField.placeholder = "Display Name"
        view.addSubview(displayNameTextField)

        usernameTextField.placeholder = "Username"
        usernameTextField.text = usernameAvailable ? session.userName : ""
        usernameTextField.unstyleField()
        view.addSubview(usernameTextField)

        passwordTextField.placeholder = "Password"
        passwordTextField.protectField()
        view.addSubview(passwordTextField)

        emailTextField.placeholder = "Email"
        emailTextField.keyboardType = .EmailAddress
        emailTextField.unstyleField()
        view.addSubview(emailTextField)

        createAccountBT.setTitle("Create Account", forState: .Normal)
        createAccountBT.addTarget(self, action: #selector(CreateAccountViewController.createAccount), forControlEvents: .TouchUpInside)
        view.addSubview(createAccountBT)
    }

    override func setupConstraints() {
        crowdBG.autoPinEdgesToSuperviewEdges()

        for view in [displayNameTextField, usernameTextField, passwordTextField, createAccountBT, emailTextField] {
            view.autoPinEdgeToSuperviewEdge(.Left, withInset: 45)
            view.autoPinEdgeToSuperviewEdge(.Right, withInset: 45)
            view.autoSetDimension(.Height, toSize: 50)
        }

        backBT.autoPinToTopLayoutGuideOfViewController(self, withInset: 20)
        backBT.autoPinEdgeToSuperviewEdge(.Left, withInset: 25)

        welcomeLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: backBT)
        welcomeLabel.autoAlignAxisToSuperviewAxis(.Vertical)
        welcomeLabel.autoPinEdge(.Left, toEdge: .Right, ofView: backBT, withOffset: 20)
        welcomeLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 100)

        displayNameTextField.autoPinEdge(.Top, toEdge: .Bottom, ofView: backBT, withOffset: 30)
        usernameTextField.autoPinEdge(.Top, toEdge: .Bottom, ofView: displayNameTextField, withOffset: 15)
        passwordTextField.autoPinEdge(.Top, toEdge: .Bottom, ofView: usernameTextField, withOffset: 15)
        emailTextField.autoPinEdge(.Top, toEdge: .Bottom, ofView: passwordTextField, withOffset: 15)
        createAccountBT.autoPinEdge(.Top, toEdge: .Bottom, ofView: emailTextField, withOffset: 15)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        displayNameTextField.becomeFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        crowdBGGradient.frame = crowdBG.bounds
        crowdBGGOverlay.frame = crowdBG.bounds
        welcomeLabel.preferredMaxLayoutWidth = welcomeLabel.frame.size.width
    }

    func dismiss() {
        if let vc = self.navigationController {
            vc.popViewControllerAnimated(true)
        }
    }

    func createAccount() {
        guard let displayName = displayNameTextField.text, username = usernameTextField.text, password = passwordTextField.text, email = emailTextField.text else {
            return showError("All fields are required")
        }

        guard displayName.characters.count > 0 else {
            return showError("No Display Name Entered")
        }

        guard username.characters.count > 0 else {
            return showError("No Username Entered")
        }

        guard password.characters.count > 0 else {
            return showError("No Password Entered")
        }

        guard email.characters.count > 0 else {
            return showError("No Email Entered")
        }

        guard isValidEmail(email) else {
            return showError("Invalid Email Entered")
        }

        let params = ["displayName" : displayName, "username": username, "password": password, "email": email, "twitterAuthToken": session.authToken, "twitterAuthTokenSecret": session.authTokenSecret]

        createAccountBT.showIndicator()
        backBT.enabled = false
        Constants.Network.POST("/user/twitter/create", parameters: params, completionHandler: { (response, error) -> Void in
            self.createAccountBT.hideIndicator()
            self.backBT.enabled = true
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                Answers.logSignUpWithMethod("Twitter", success: true, customAttributes: [:])

                Constants.Settings.setSecretObject(result, forKey: "user")

                if let result = result as? JSON {
                    if let user = STMUser(json: result) {
                        AppDelegate.del().loginUser(user)
                        Answers.logLoginWithMethod("Twitter", success: true, customAttributes: nil)
                    }
                }
            })
        })
    }

    func isValidEmail(testStr: String) -> Bool {
        let emailRegEx = "^(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?(?:(?:(?:[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+(?:\\.[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+)*)|(?:\"(?:(?:(?:(?: )*(?:(?:[!#-Z^-~]|\\[|\\])|(?:\\\\(?:\\t|[ -~]))))+(?: )*)|(?: )+)\"))(?:@)(?:(?:(?:[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)(?:\\.[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)*)|(?:\\[(?:(?:(?:(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))\\.){3}(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))))|(?:(?:(?: )*[!-Z^-~])*(?: )*)|(?:[Vv][0-9A-Fa-f]+\\.[-A-Za-z0-9._~!$&'()*+,;=:]+))\\])))(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?$"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluateWithObject(testStr)
        return result
    }

}
