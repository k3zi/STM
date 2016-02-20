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
    
    let displayNameTextField = UITextField.styledForLaunchScreen()
    let usernameTextField = UITextField.styledForLaunchScreen()
    let passwordTextField = UITextField.styledForLaunchScreen()
    let emailTextField = UITextField.styledForLaunchScreen()
    let createAccountBT = UIButton.styledForLaunchScreen()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        crowdBGGradient.colors = [RGB(0, a: 160).CGColor, RGB(255, a: 0).CGColor, RGB(255, a: 0).CGColor, RGB(0, a: 160).CGColor]
        crowdBGGradient.locations = [NSNumber(float: 0.0), NSNumber(float: 0.315), NSNumber(float: 0.685), NSNumber(float: 1.0)]
        crowdBG.layer.addSublayer(crowdBGGradient)
        
        crowdBGGOverlay.opacity = 0.66
        crowdBGGOverlay.backgroundColor = Constants.Color.tint.CGColor
        crowdBG.layer.addSublayer(crowdBGGOverlay)
        
        crowdBG.contentMode = .ScaleAspectFill
        view.addSubview(crowdBG)
        
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
        emailTextField.keyboardType = .EmailAddress
        emailTextField.unstyleField()
        view.addSubview(emailTextField)
        
        createAccountBT.setTitle("Create Account", forState: .Normal)
        createAccountBT.addTarget(self, action: Selector("createAccount"), forControlEvents: .TouchUpInside)
        view.addSubview(createAccountBT)
    }
    
    override func setupConstraints() {
        crowdBG.autoPinEdgesToSuperviewEdges()
        
        for view in [displayNameTextField, usernameTextField, passwordTextField, emailTextField, createAccountBT] {
            view.autoPinEdgeToSuperviewEdge(.Left, withInset: 45)
            view.autoPinEdgeToSuperviewEdge(.Right, withInset: 45)
            view.autoSetDimension(.Height, toSize: 50)
        }
        
        displayNameTextField.autoPinToTopLayoutGuideOfViewController(self, withInset: 45)
        
        usernameTextField.autoPinEdge(.Top, toEdge: .Bottom, ofView: displayNameTextField, withOffset: 15)
        passwordTextField.autoPinEdge(.Top, toEdge: .Bottom, ofView: usernameTextField, withOffset: 15)
        emailTextField.autoPinEdge(.Top, toEdge: .Bottom, ofView: passwordTextField, withOffset: 15)
        createAccountBT.autoPinEdge(.Top, toEdge: .Bottom, ofView: emailTextField, withOffset: 15)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        crowdBGGradient.frame = crowdBG.bounds
        crowdBGGOverlay.frame = crowdBG.bounds
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
        
        let params = ["displayName" : displayName, "username": username, "password": password, "email": email]
        Constants.Network.POST("/createAccount", parameters: params, completionHandler: { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                if let vc = self.presentingViewController {
                    vc.dismissViewControllerAnimated(true, completion: nil)
                }
            })
        })
    }
    
}
