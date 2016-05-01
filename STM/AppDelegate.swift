//
//  AppDelegate.swift
//  STM
//
//  Created by Kesi Maduka on 1/29/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import MediaPlayer
import Fabric
import TwitterKit
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
    var currentWindowEffects: [UIView]?

	var shortcutItem: UIApplicationShortcutItem?
	var currentUser: STMUser?

    var activeStreamController: UIViewController?

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        //Setup some things...
		NSUserDefaults.standardUserDefaults().setSecret(Constants.Config.userDefaultsSecret)
		Fabric.with([Crashlytics.self, Twitter.self])
        Constants.http.authzModule = STMAuthzModule()

        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let credentialStorage = NSURLCredentialStorage.sharedCredentialStorage()
        credentialStorage.setCredential(Constants.Config.systemCredentials, forProtectionSpace: NSURLProtectionSpace(host: "api.stm.io", port: 0, protocol: "https", realm: nil, authenticationMethod: NSURLAuthenticationMethodHTTPBasic))
        sessionConfig.URLCredentialStorage = credentialStorage
        ImageDownloader.defaultDownloader.sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()

		let nav = NavigationController(rootViewController: InitialViewController())
		nav.setNavigationBarHidden(true, animated: false)

		window = Window(frame: Constants.UI.Screen.bounds)
		window?.rootViewController = nav
		window?.makeKeyAndVisible()

		application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil))
		application.registerForRemoteNotifications()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.audioWasInterupted(_:)), name: AVAudioSessionInterruptionNotification, object: nil)

        func exceptionHandler(exception: NSException) {
            print(exception)
            print(exception.callStackSymbols)
        }
        NSSetUncaughtExceptionHandler(exceptionHandler)

        UITabBar.appearance().tintColor = Constants.UI.Color.tint

		setUpAudioSession(withMic: false)

		return true
	}

	func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
		let characterSet = NSCharacterSet(charactersInString: "<>")
		let deviceTokenString = (deviceToken.description as NSString).stringByTrimmingCharactersInSet(characterSet).stringByReplacingOccurrencesOfString(" ", withString: "") as String
		Constants.Settings.setSecretObject(deviceTokenString, forKey: "deviceTokenString")
	}

	func createTabSet() -> UITabBarController {
		let tabVC = UITabBarController()

        guard let user = currentUser else {
            return tabVC
        }

		let tab1 = NavigationController(rootViewController: DashboardViewController())
		let tab2 = NavigationController(rootViewController: CreateStreamViewController())
		let tab3 = NavigationController(rootViewController: MessagesViewController())
		let tab4 = NavigationController(rootViewController: SearchViewController())
		let tab5 = NavigationController(rootViewController: ProfileViewController(user: user, isOwner: true))
		tabVC.setViewControllers([tab1, tab2, tab3, tab4, tab5], animated: false)

		self.window?.rootViewController = tabVC
		self.window?.makeKeyAndVisible()

		tab1.tabBarItem = UITabBarItem(title: "Dashboard", image: UIImage(named: "tabDashboard"), tag: 1)
		tab2.tabBarItem = UITabBarItem(title: "Host", image: UIImage(named: "tabCreateStream"), tag: 2)
		tab3.tabBarItem = UITabBarItem(title: "Messages", image: UIImage(named: "tabMessages"), tag: 3)
		tab4.tabBarItem = UITabBarItem(title: "Search", image: UIImage(named: "tabSearch"), tag: 4)
		tab5.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(named: "tabProfile"), tag: 5)
		tabVC.selectedViewController = tab1

		if let item = shortcutItem {
			shortcutItem = nil
		}

		if let navs = tabVC.viewControllers as? [NavigationController] {
			for nav in navs {
				if let vc = nav.topViewController {
					vc.view.description
				}
			}
		}

		return tabVC
	}

	func loginUser(user: STMUser) {
		currentUser = user
		Crashlytics.sharedInstance().setUserIdentifier(String(user.id))
		Crashlytics.sharedInstance().setUserName(user.username)

		if let window = window as? Window {
			let tabSet = AppDelegate.del().createTabSet()
			UIView.transitionWithView(window, duration: window.screenIsReady == true ? 0.5 : 0.0, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
				AppDelegate.del().window?.rootViewController = tabSet
				}, completion: { (finished) -> Void in
				if window.screenIsReady == false {
					window.screenIsReady = true
				}
			})
		}

		if let token = Constants.Settings.secretObjectForKey("deviceTokenString") {
			Constants.Network.POST("/user/updateAPNS", parameters: ["token": token], completionHandler: { (response, error) -> Void in
				print("Network: Updated Token")
			})
		}
	}

    func presentStreamController(vc: UIViewController) {
        self.close()
        self.window?.rootViewController?.presentViewController(vc, animated: true, completion: nil)
        self.activeStreamController = vc
    }

    func playerIsMinimized() -> Bool {
        guard let vc = activeStreamController else {
            return false
        }

        if let player = vc as? PlayerViewController {
            return player.dismissBT.selected
        }

        if let host = vc as? HostViewController {
            return host.dismissBT.selected
        }

        return false
    }

    //MARK: Audio

    /**
     Start the AVAudioSession

     - parameter withMic: Whether to allow recording
     */
    func setUpAudioSession(withMic withMic: Bool) {
        let category = withMic ? AVAudioSessionCategoryPlayAndRecord : AVAudioSessionCategoryPlayback
        var options = AVAudioSessionCategoryOptions()
        if withMic {
            options.insert(.DefaultToSpeaker)
        }

		do {
			try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.03)
			try AVAudioSession.sharedInstance().setPreferredSampleRate(44100)
			try AVAudioSession.sharedInstance().setCategory(category, withOptions: options)
			try AVAudioSession.sharedInstance().setActive(true)
		} catch {
			print("Error starting audio sesssion")
		}
	}

    func audioWasInterupted(notification: NSNotification) {
        if let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber {
            switch type.unsignedIntegerValue {
            case AVAudioSessionInterruptionType.Began.rawValue:
                self.stop()
                break

            case AVAudioSessionInterruptionType.Ended.rawValue:
                self.play() //Check AVAudioSessionInterruptionOptionShouldResume, after there is a way to resume manualy
                break

            default:
                break
            }
        }
    }

    func play() {
        if let vc = activeStreamController as? HostViewController {
            vc.play()
        } else if let vc = activeStreamController as? PlayerViewController {
            vc.play()
        }
    }

    func stop() {
        if let vc = activeStreamController as? HostViewController {
            vc.stop()
        } else if let vc = activeStreamController as? PlayerViewController {
            vc.stop()
        }
    }

    func close() {
        if let vc = activeStreamController as? HostViewController {
            vc.close()
        } else if let vc = activeStreamController as? PlayerViewController {
            vc.close()
        }
    }

    //MARK: Window Effects

    class func topViewController(base: UIViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }

    func removeBlurEffects() {
        guard let effectViews = currentWindowEffects else {
            return
        }

        UIView.animateWithDuration(Constants.UI.Animation.visualEffectsLength, animations: { () -> Void in
            effectViews.forEach({ (view) -> () in
                if let view = view as? UIVisualEffectView {
                    view.effect = nil
                } else if !(view is UIImageView) {
                    view.alpha = 0.0
                }
            })
        }) { (finished) -> Void in
                effectViews.forEach({ $0.removeFromSuperview() })
        }
    }

	class func del() -> AppDelegate {
		if let del = UIApplication.sharedApplication().delegate as? AppDelegate {
			return del
		}

		return AppDelegate()
	}
}
