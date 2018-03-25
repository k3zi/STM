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
    let crowdBG = UIImageView(image: UIImage(named: "loginBackground"))

    let signInBT = UIButton.styledForLaunchScreen()
    let createAccountBT = UIButton.styleForCreateAccountButton()
    var twitterSignInBT = TWTRLogInButton()
    let launchLogoWithText = UIImageView(image: UIImage(named: "launchLogoWithText"))

    override func viewDidLoad() {
        super.viewDidLoad()

        crowdBG.contentMode = .scaleAspectFill
        view.addSubview(crowdBG)

        view.addSubview(launchLogoWithText)

        // Buttons

        signInBT.setTitle("Sign In", for: UIControlState())
        signInBT.addTarget(self, action: #selector(InitialViewController.signIn), for: .touchUpInside)
        view.addSubview(signInBT)

        createAccountBT.addTarget(self, action: #selector(InitialViewController.createAccount), for: .touchUpInside)
        view.addSubview(createAccountBT)

        twitterSignInBT = TWTRLogInButton { (session, error) in
            if let unwrappedSession = session {
                self.handleTwitterSession(unwrappedSession)
            } else if let error = error {
                if error._code != 1 { //cancel code = 1
                    self.showError(error.localizedDescription)
                }
            }
        }
        twitterSignInBT.layer.cornerRadius = 10.0
        self.view.addSubview(twitterSignInBT)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let user = Constants.Settings.secretObject(forKey: "user") as? [String: AnyObject] {
            Constants.Network.POST("/user/authenticate", parameters: user, completionHandler: { (response, error) -> Void in
                self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
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

        launchLogoWithText.autoAlignAxis(toSuperviewAxis: .horizontal)
        launchLogoWithText.autoAlignAxis(toSuperviewAxis: .vertical)

        //twitterSignInBT.autoPinEdge(.top, to: .bottom, of: launchLogoWithText, withOffset: 90)
        twitterSignInBT.autoPinEdge(toSuperviewEdge: .left, withInset: 45)
        twitterSignInBT.autoPinEdge(toSuperviewEdge: .right, withInset: 45)
        twitterSignInBT.autoSetDimension(.height, toSize: 50)

        signInBT.autoPinEdge(.top, to: .bottom, of: twitterSignInBT, withOffset: 15)
        signInBT.autoPinEdge(toSuperviewEdge: .left, withInset: 45)
        signInBT.autoPinEdge(toSuperviewEdge: .right, withInset: 45)
        signInBT.autoSetDimension(.height, toSize: 50)

        createAccountBT.autoPinEdge(.top, to: .bottom, of: signInBT, withOffset: 15)
        createAccountBT.autoPinEdge(toSuperviewEdge: .left, withInset: 45)
        createAccountBT.autoPinEdge(toSuperviewEdge: .right, withInset: 45)
        createAccountBT.autoPin(toBottomLayoutGuideOf: self, withInset: 15)
    }

    @objc func createAccount() {
        if let nav = self.navigationController {
            let vc = CreateAccountViewController()
            nav.pushViewController(vc, animated: true)
        }
    }

    @objc func signIn() {
        if let nav = self.navigationController {
            let vc = SignInViewController()
            nav.pushViewController(vc, animated: true)
        }
    }

    func handleTwitterSession(_ session: TWTRSession) {
        self.twitterSignInBT.showIndicator()

        let params = ["twitterAuthToken": session.authToken, "username": session.userName]
        Constants.Network.POST("/user/twitter/authenticate", parameters: params, completionHandler: { (response, error) -> Void in
            self.twitterSignInBT.hideIndicator()
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                guard let result = result as? JSON else {
                    return
                }

                if let user = STMUser(json: result) {
                    Constants.Settings.setSecretObject(result, forKey: "user")
                    Answers.logLogin(withMethod: "Twitter", success: true, customAttributes: nil)
                    return AppDelegate.del().loginUser(user)
                } else if let usernameAvailable = result["usernameAvailable"] as? Bool {
                    let vc = FinishTwitterAccountViewController(session: session, usernameAvailable: usernameAvailable)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            })
        })
    }

}
