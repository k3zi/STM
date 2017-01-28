//
//  InitialViewController.swift
//  STM
//
//  Created by Kesi Maduka on 1/29/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class CreateAccountViewController: KZViewController {
    let crowdBG = UIImageView(image: UIImage(named: "crowdBG"))
    let crowdBGGradient = CAGradientLayer()
    let crowdBGGOverlay = CALayer()

    let backBT = UIButton.styleForBackButton()
    let displayNameTextField = UITextField.styledForLaunchScreen()
    let usernameTextField = UITextField.styledForLaunchScreen()
    let passwordTextField = UITextField.styledForLaunchScreen()
    let emailTextField = UITextField.styledForLaunchScreen()
    let createAccountBT = UIButton.styledForLaunchScreen()

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

        displayNameTextField.placeholder = "Display Name"
        view.addSubview(displayNameTextField)

        usernameTextField.placeholder = "Username"
        usernameTextField.unstyleField()
        view.addSubview(usernameTextField)

        passwordTextField.placeholder = "Password"
        passwordTextField.protectField()
        view.addSubview(passwordTextField)

        emailTextField.placeholder = "Email"
        emailTextField.keyboardType = .emailAddress
        emailTextField.unstyleField()
        view.addSubview(emailTextField)

        createAccountBT.setTitle("Create Account", for: UIControlState())
        createAccountBT.addTarget(self, action: #selector(CreateAccountViewController.createAccount), for: .touchUpInside)
        view.addSubview(createAccountBT)
    }

    override func setupConstraints() {
        crowdBG.autoPinEdgesToSuperviewEdges()

        for view in [displayNameTextField, usernameTextField, passwordTextField, emailTextField, createAccountBT] {
            view.autoPinEdge(toSuperviewEdge: .left, withInset: 45)
            view.autoPinEdge(toSuperviewEdge: .right, withInset: 45)
            view.autoSetDimension(.height, toSize: 50)
        }

        backBT.autoPin(toTopLayoutGuideOf: self, withInset: 20)
        backBT.autoPinEdge(toSuperviewEdge: .left, withInset: 25)
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
    }

    func popVC() {
        if let vc = self.navigationController {
            vc.popViewController(animated: true)
        }
    }

    func createAccount() {
        guard let displayName = displayNameTextField.text else {
            return showError("No Display Name Entered")
        }

        guard displayName.characters.count > 0 else {
            return showError("No Display Name Entered")
        }

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

        guard let email = emailTextField.text else {
            return showError("No Email Entered")
        }

        guard email.characters.count > 0 else {
            return showError("No Email Entered")
        }

        guard isValidEmail(email) else {
            return showError("Invalid Email Entered")
        }

        let params = ["displayName" : displayName, "username": username, "password": password, "email": email]

        createAccountBT.showIndicator()
        backBT.isEnabled = false
        Constants.Network.POST("/user/create", parameters: params, completionHandler: { (response, error) -> Void in
            print(response as Any)
            self.createAccountBT.hideIndicator()
            self.backBT.isEnabled = true
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                Answers.logSignUp(withMethod: "Email", success: true, customAttributes: [:])

                Constants.Settings.setSecretObject(result, forKey: "user")

                guard let result = result as? JSON, let user = STMUser(json: result) else {
                    return
                }

                AppDelegate.del().loginUser(user)
                Answers.logLogin(withMethod: "Password", success: true, customAttributes: nil)
            })
        })
    }

    func isValidEmail(_ testStr: String) -> Bool {
        let emailRegEx = "^(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?(?:(?:(?:[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+(?:\\.[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+)*)|(?:\"(?:(?:(?:(?: )*(?:(?:[!#-Z^-~]|\\[|\\])|(?:\\\\(?:\\t|[ -~]))))+(?: )*)|(?: )+)\"))(?:@)(?:(?:(?:[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)(?:\\.[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)*)|(?:\\[(?:(?:(?:(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))\\.){3}(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))))|(?:(?:(?: )*[!-Z^-~])*(?: )*)|(?:[Vv][0-9A-Fa-f]+\\.[-A-Za-z0-9._~!$&'()*+,;=:]+))\\])))(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?$"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluate(with: testStr)
        return result
    }

}
