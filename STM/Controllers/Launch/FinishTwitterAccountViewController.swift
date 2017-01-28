//
//  FinishTwitterAccountViewController.swift
//  STM
//
//  Created by Kesi Maduka on 1/29/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import TwitterKit

class FinishTwitterAccountViewController: KZViewController, UITextFieldDelegate {
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

        crowdBGGradient.colors = [RGB(0, a: 0.63).cgColor, RGB(255, a: 0).cgColor, RGB(255, a: 0).cgColor, RGB(0, a: 0.63).cgColor]
        crowdBGGradient.locations = [NSNumber(value: 0.0 as Float), NSNumber(value: 0.315 as Float), NSNumber(value: 0.685 as Float), NSNumber(value: 1.0 as Float)]
        crowdBG.layer.addSublayer(crowdBGGradient)

        crowdBGGOverlay.opacity = 0.66
        crowdBGGOverlay.backgroundColor = Constants.UI.Color.tint.cgColor
        crowdBG.layer.addSublayer(crowdBGGOverlay)

        crowdBG.contentMode = .scaleAspectFill
        view.addSubview(crowdBG)

        backBT.addTarget(self, action: #selector(CreateAccountViewController.dismiss), for: .touchUpInside)
        view.addSubview(backBT)

        welcomeLabel.text = "Hi" + (usernameAvailable ? " @\(session.userName)!" : "! Unfortunately this username isn't available. Please pick another:")
        welcomeLabel.textColor = RGB(255)
        welcomeLabel.font = UIFont.systemFont(ofSize: 10)
        welcomeLabel.numberOfLines = 0
        welcomeLabel.textAlignment = .center
        view.addSubview(welcomeLabel)

        //Fields

        displayNameTextField.placeholder = "Display Name"
        displayNameTextField.delegate = self
        view.addSubview(displayNameTextField)

        usernameTextField.placeholder = "Username"
        usernameTextField.text = usernameAvailable ? session.userName : ""
        usernameTextField.unstyleField()
        usernameTextField.delegate = self
        view.addSubview(usernameTextField)

        passwordTextField.placeholder = "Password"
        passwordTextField.protectField()
        passwordTextField.delegate = self
        view.addSubview(passwordTextField)

        emailTextField.placeholder = "Email"
        emailTextField.keyboardType = .emailAddress
        emailTextField.unstyleField()
        emailTextField.delegate = self
        view.addSubview(emailTextField)

        createAccountBT.setTitle("Create Account", for: UIControlState())
        createAccountBT.addTarget(self, action: #selector(CreateAccountViewController.createAccount), for: .touchUpInside)
        view.addSubview(createAccountBT)
    }

    override func setupConstraints() {
        crowdBG.autoPinEdgesToSuperviewEdges()

        for view in [displayNameTextField, usernameTextField, passwordTextField, createAccountBT, emailTextField] {
            view.autoPinEdge(toSuperviewEdge: .left, withInset: 45)
            view.autoPinEdge(toSuperviewEdge: .right, withInset: 45)
            view.autoSetDimension(.height, toSize: 50)
        }

        backBT.autoPin(toTopLayoutGuideOf: self, withInset: 20)
        backBT.autoPinEdge(toSuperviewEdge: .left, withInset: 25)

        welcomeLabel.autoAlignAxis(.horizontal, toSameAxisOf: backBT)
        welcomeLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        welcomeLabel.autoPinEdge(.left, to: .right, of: backBT, withOffset: 20)
        welcomeLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 100)

        displayNameTextField.autoPinEdge(.top, to: .bottom, of: backBT, withOffset: 30)
        usernameTextField.autoPinEdge(.top, to: .bottom, of: displayNameTextField, withOffset: 15)
        passwordTextField.autoPinEdge(.top, to: .bottom, of: usernameTextField, withOffset: 15)
        emailTextField.autoPinEdge(.top, to: .bottom, of: passwordTextField, withOffset: 15)
        createAccountBT.autoPinEdge(.top, to: .bottom, of: emailTextField, withOffset: 15)
    }

    override func viewWillAppear(_ animated: Bool) {
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
            vc.popViewController(animated: true)
        }
    }

    func createAccount() {
        guard let displayName = displayNameTextField.text, let username = usernameTextField.text, let password = passwordTextField.text, let email = emailTextField.text else {
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
        backBT.isEnabled = false
        Constants.Network.POST("/user/twitter/create", parameters: params, completionHandler: { (response, error) -> Void in
            self.createAccountBT.hideIndicator()
            self.backBT.isEnabled = true
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                Answers.logSignUp(withMethod: "Twitter", success: true, customAttributes: [:])

                Constants.Settings.setSecretObject(result, forKey: "user")

                if let result = result as? JSON {
                    if let user = STMUser(json: result) {
                        AppDelegate.del().loginUser(user)
                        Answers.logLogin(withMethod: "Twitter", success: true, customAttributes: nil)
                    }
                }
            })
        })
    }

    func isValidEmail(_ testStr: String) -> Bool {
        let emailRegEx = "^(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?(?:(?:(?:[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+(?:\\.[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+)*)|(?:\"(?:(?:(?:(?: )*(?:(?:[!#-Z^-~]|\\[|\\])|(?:\\\\(?:\\t|[ -~]))))+(?: )*)|(?: )+)\"))(?:@)(?:(?:(?:[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)(?:\\.[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)*)|(?:\\[(?:(?:(?:(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))\\.){3}(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))))|(?:(?:(?: )*[!-Z^-~])*(?: )*)|(?:[Vv][0-9A-Fa-f]+\\.[-A-Za-z0-9._~!$&'()*+,;=:]+))\\])))(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?$"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluate(with: testStr)
        return result
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

}
