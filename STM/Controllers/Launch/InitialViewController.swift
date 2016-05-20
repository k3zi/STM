//
//  InitialViewController.swift
//  STM
//
//  Created by Kesi Maduka on 1/29/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import TwitterKit

class InitialViewController: KZViewController {
    let crowdBG = UIImageView(image: UIImage(named: "crowdBG"))
    let crowdBGGradient = CAGradientLayer()
    let crowdBGGOverlay = CALayer()

    let signInBT = UIButton.styledForLaunchScreen()
    let createAccountBT = UIButton.styledForLaunchScreen()
    var twitterSignInBT = TWTRLogInButton()
    let launchLogoWithText = UIImageView(image: UIImage(named: "launchLogoWithText"))

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

        view.addSubview(launchLogoWithText)

        //Buttons

        signInBT.setTitle("Sign In", forState: .Normal)
        signInBT.addTarget(self, action: #selector(InitialViewController.signIn), forControlEvents: .TouchUpInside)
        view.addSubview(signInBT)

        createAccountBT.setTitle("Create An Account", forState: .Normal)
        createAccountBT.addTarget(self, action: #selector(InitialViewController.createAccount), forControlEvents: .TouchUpInside)
        view.addSubview(createAccountBT)

        twitterSignInBT = TWTRLogInButton { (session, error) in
            if let unwrappedSession = session {
                self.handleTwitterSession(unwrappedSession)
            } else if let error = error {
                if error.code != 1 { //cancel code = 1
                    self.showError(error.localizedDescription)
                }
            }
        }
        twitterSignInBT.layer.cornerRadius = 10.0
        self.view.addSubview(twitterSignInBT)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let user = Constants.Settings.secretObjectForKey("user") as? [String: AnyObject] {
            Constants.Network.POST("/user/authenticate", parameters: user, completionHandler: { (response, error) -> Void in
                self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                    Constants.Settings.setSecretObject(result, forKey: "user")

                    if let result = result as? JSON {
                        if let user = STMUser(json: result) {
                            AppDelegate.del().loginUser(user)
                        }
                    }
                    }, errorCompletion: { Void in
                        if let window = AppDelegate.del().window as? Window {
                            window.screenIsReady = true
                        }
                })
            })
        } else {
            if let window = AppDelegate.del().window as? Window {
                window.screenIsReady = true
            }
        }
    }

    override func setupConstraints() {
        crowdBG.autoPinEdgesToSuperviewEdges()

        launchLogoWithText.autoAlignAxisToSuperviewAxis(.Vertical)

        twitterSignInBT.autoPinEdge(.Top, toEdge: .Bottom, ofView: launchLogoWithText, withOffset: 90)
        twitterSignInBT.autoPinEdgeToSuperviewEdge(.Left, withInset: 45)
        twitterSignInBT.autoPinEdgeToSuperviewEdge(.Right, withInset: 45)
        twitterSignInBT.autoSetDimension(.Height, toSize: 50)

        signInBT.autoPinEdge(.Top, toEdge: .Bottom, ofView: twitterSignInBT, withOffset: 15)
        signInBT.autoPinEdgeToSuperviewEdge(.Left, withInset: 45)
        signInBT.autoPinEdgeToSuperviewEdge(.Right, withInset: 45)
        signInBT.autoSetDimension(.Height, toSize: 50)

        createAccountBT.autoPinEdge(.Top, toEdge: .Bottom, ofView: signInBT, withOffset: 15)
        createAccountBT.autoPinEdgeToSuperviewEdge(.Left, withInset: 45)
        createAccountBT.autoPinEdgeToSuperviewEdge(.Right, withInset: 45)
        createAccountBT.autoMatchDimension(.Height, toDimension: .Height, ofView: signInBT)
        createAccountBT.autoPinToBottomLayoutGuideOfViewController(self, withInset: 90)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        crowdBGGradient.frame = crowdBG.bounds
        crowdBGGOverlay.frame = crowdBG.bounds
    }

    func createAccount() {
        if let nav = self.navigationController {
            let vc = CreateAccountViewController()
            nav.pushViewController(vc, animated: true)
        }
    }

    func signIn() {
        if let nav = self.navigationController {
            let vc = SignInViewController()
            nav.pushViewController(vc, animated: true)
        }
    }

    func handleTwitterSession(session: TWTRSession) {
        self.twitterSignInBT.showIndicator()
        let params = ["twitterAuthToken": session.authToken, "username": session.userName]
        Constants.Network.POST("/user/twitter/authenticate", parameters: params, completionHandler: { (response, error) -> Void in
            self.twitterSignInBT.hideIndicator()
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                guard let result = result as? JSON else {
                    return
                }

                if let user = STMUser(json: result) {
                    Constants.Settings.setSecretObject(result, forKey: "user")
                    Answers.logLoginWithMethod("Twitter", success: true, customAttributes: nil)
                    return AppDelegate.del().loginUser(user)
                } else if let usernameAvailable = result["usernameAvailable"] as? Bool {
                    let vc = FinishTwitterAccountViewController(session: session, usernameAvailable: usernameAvailable)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            })
        })
    }

}
