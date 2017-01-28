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
import KILabel

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
    var currentWindowEffects: [UIView]?

	var shortcutItem: UIApplicationShortcutItem?
	var currentUser: STMUser?

    var activeStreamController: UIViewController?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        configureApp()

		let nav = NavigationController(rootViewController: InitialViewController())
		nav.setNavigationBarHidden(true, animated: false)

		window = Window(frame: Constants.UI.Screen.bounds)
		window?.rootViewController = nav
		window?.makeKeyAndVisible()

		application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
		application.registerForRemoteNotifications()

		return true
	}

    // MARK: Configure App

    func configureApp() {
        UserDefaults.standard.setSecret(Constants.Config.userDefaultsSecret)
        Twitter.sharedInstance().start(withConsumerKey: Constants.Config.twitterConsumerKey, consumerSecret: Constants.Config.twitterConsumerSecret)
        Fabric.with([Crashlytics.self, Twitter.self])

        ImageDownloader.default.sessionConfiguration = Constants.Config.sessionConfig()

        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.audioWasInterupted(_:)), name: NSNotification.Name.AVAudioSessionInterruption, object: nil)

        func exceptionHandler(_ exception: NSException) {
            print(exception)
            print(exception.callStackSymbols)
        }
        NSSetUncaughtExceptionHandler(exceptionHandler)

        UITabBar.appearance().tintColor = Constants.UI.Color.tint2
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.white], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: Constants.UI.Color.tint2], for: .selected)

        setUpAudioSession(false)
    }

	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let characterSet = CharacterSet(charactersIn: "<>")
		let deviceTokenString = (deviceToken.description as NSString).trimmingCharacters(in: characterSet).replacingOccurrences(of: " ", with: "") as String
		Constants.Settings.setSecretObject(deviceTokenString, forKey: "deviceTokenString")
	}

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        updateBadgeCount()
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        updateBadgeCount {
            completionHandler(.noData)
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        updateBadgeCount()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        updateBadgeCount()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        updateBadgeCount()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        updateBadgeCount()
    }

    // MARK: Handle Open Requests

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return self.application(application, handleOpen: url)
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return self.application(app, handleOpen: url)
    }

    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        guard url.scheme == "streamtome" else {
            return false
        }

        guard let query = url.query else {
            return false
        }

        let mixedVars = query.components(separatedBy: "&")
        var dict = [String: String]()

        for set in mixedVars {
            let arr = set.components(separatedBy: "=")

            guard arr.count == 2 else {
                break
            }

            dict.updateValue(arr[1], forKey: arr[0])
        }

        let path = url.absoluteString.components(separatedBy: "//")[1].components(separatedBy: "?")[0]

        if path == "open-stream" {
            guard dict["stream"] != nil else {
                return false
            }

            let streamID = Constants.Config.hashids.decode(dict["stream"])[0]

            guard let topVC = self.topViewController() else {
                return false
            }

            Constants.Network.GET("/stream/\(streamID)", parameters: nil) { (response, error) -> Void in
                self.topViewController()?.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                    guard let result = result as? JSON, let stream = STMStream(json: result) else {
                        return
                    }

                    let vc = PlayerViewController()
                    let activeVC = AppDelegate.del().activeStreamController

                    vc.start(stream, vc: topVC) { (nothing, error) -> Void in
                        if let error = error {
                            (activeVC ?? topVC).showError(error)
                        } else {
                            AppDelegate.del().presentStreamController(vc)
                        }
                    }
                })
            }
        }

        return true
    }

    // MARK: APNS Notifications

    func updateBadgeCount(_ completionHandler: (() -> Void)? = nil) {
        guard let tabs = self.window?.rootViewController as? UITabBarController else {
            return
        }

        guard tabs.viewControllers?.count > 2 else {
            return
        }

        guard let nav = tabs.viewControllers?[2] as? NavigationController else {
            return
        }

        guard let vc = nav.viewControllers[0] as? MessagesViewController else {
            return
        }

        vc.fetchDataWithCompletion({
            let badgeCount = self.badgeCount()
            self.updateServerBadgeCount(badgeCount, completionHandler: completionHandler)
        })

    }

    func updateServerBadgeCount(_ badgeCount: Int, completionHandler: (() -> Void)? = nil) {
        guard let _ = AppDelegate.del().currentUser else {
            completionHandler?()
            return
        }

        UIApplication.shared.applicationIconBadgeNumber = badgeCount
        Constants.Network.POST("/user/update/badge", parameters: ["value": badgeCount]) { (response, error) in
            guard let response = response, let success = response["success"] as? Bool else {
                completionHandler?()
                return
            }

            if success {
                guard let result = response["result"], let userResult = result as? JSON else {
                    return
                }

                if let user = STMUser(json: userResult) {
                    AppDelegate.del().currentUser = user
                }
            }

            completionHandler?()
        }
    }

    func badgeCount() -> Int {
        var count = 0
        if let tabs = self.window?.rootViewController as? UITabBarController {
            if tabs.viewControllers?.count > 2 {
                if let vc = tabs.viewControllers?[2] as? NavigationController {
                    if let badgeString = vc.tabBarItem.badgeValue {
                        count = count + (Int(badgeString) ?? 0)
                    }
                }
            }
        }

        return count
    }

    // MARK: Login User

	func createTabSet() -> UITabBarController {
		let tabVC = TabBarController()

        guard let user = currentUser else {
            return tabVC
        }

		let tab1 = NavigationController(rootViewController: DashboardViewController())
		let tab2 = NavigationController(rootViewController: SearchViewController())
        let tab3 = NavigationController(rootViewController: CreateStreamViewController())
		let tab4 = NavigationController(rootViewController: MessagesViewController())
		let tab5 = NavigationController(rootViewController: ProfileViewController(user: user, isOwner: true))
		tabVC.setViewControllers([tab1, tab2, tab3, tab4, tab5], animated: false)

		self.window?.rootViewController = tabVC
		self.window?.makeKeyAndVisible()

		tab1.tabBarItem = UITabBarItem(title: "Dashboard", image: UIImage(named: "tabDashboard")?.withRenderingMode(.alwaysOriginal), tag: 1)
        tab1.tabBarItem.selectedImage = UIImage(named: "tabDashboard")
        tab2.tabBarItem = UITabBarItem(title: "Search", image: UIImage(named: "tabSearch")?.withRenderingMode(.alwaysOriginal), tag: 2)
        tab2.tabBarItem.selectedImage = UIImage(named: "tabSearch")
		tab3.tabBarItem = UITabBarItem(title: "      ", image: UIImage(named: ""), tag: 3)
		tab4.tabBarItem = UITabBarItem(title: "Messages", image: UIImage(named: "tabMessages")?.withRenderingMode(.alwaysOriginal), tag: 4)
        tab4.tabBarItem.selectedImage = UIImage(named: "tabMessages")
		tab5.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(named: "tabProfile")?.withRenderingMode(.alwaysOriginal), tag: 5)
        tab5.tabBarItem.selectedImage = UIImage(named: "tabProfile")
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

        if !UserDefaults.standard.bool(forKey: "hasSeenWalkthrough") {
            tabVC.present(WalkthroughViewController(), animated: false, completion: nil)
        }

		return tabVC
	}

	func loginUser(_ user: STMUser) {
		currentUser = user
		Crashlytics.sharedInstance().setUserIdentifier(String(user.id))
		Crashlytics.sharedInstance().setUserName(user.username)

		if let window = window as? Window {
			let tabSet = AppDelegate.del().createTabSet()
			UIView.transition(with: window, duration: window.screenIsReady == true ? 0.5 : 0.0, options: UIViewAnimationOptions.transitionCrossDissolve, animations: {
				AppDelegate.del().window?.rootViewController = tabSet
				}, completion: { (finished) -> Void in
			})
		}

		if let token = Constants.Settings.secretObject(forKey: "deviceTokenString") {
			Constants.Network.POST("/user/updateAPNS", parameters: ["token": token], completionHandler: { (response, error) -> Void in
				print("Network: Updated Token")
			})
		}
	}

    // MARK: Handle Stream Popups

    func presentStreamController(_ vc: UIViewController) {
        self.close()
        self.window?.rootViewController?.present(vc, animated: true, completion: nil)
        self.activeStreamController = vc
    }

    func playerIsMinimized() -> Bool {
        guard let vc = activeStreamController else {
            return false
        }

        if let player = vc as? PlayerViewController {
            return player.dismissBT.isSelected
        }

        if let host = vc as? HostViewController {
            return host.dismissBT.isSelected
        }

        return false
    }

    // MARK: Handle Label Clicks

    var userHandleLinkTapHandler: KILinkTapHandler = { (label: KILabel, string: String, range: NSRange) -> Void in
        let username = (string as NSString).substring(with: range) as String
        print(username)
    }

    // MARK: Audio

    /**
     Start the AVAudioSession

     - parameter withMic: Whether to allow recording
     */
    func setUpAudioSession(_ withMic: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.audioWasInterupted(_:)), name: NSNotification.Name.AVAudioSessionInterruption, object: nil)

        let category = withMic ? AVAudioSessionCategoryPlayAndRecord : AVAudioSessionCategoryPlayback
        var options = AVAudioSessionCategoryOptions()
        if withMic {
            options.insert(.defaultToSpeaker)
        }

		do {
			try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.03)
			try AVAudioSession.sharedInstance().setPreferredSampleRate(44100)
			try AVAudioSession.sharedInstance().setCategory(category, with: options)
			try AVAudioSession.sharedInstance().setActive(true)
		} catch {
			print("Error starting audio sesssion")
		}
	}

    func audioWasInterupted(_ notification: Notification) {
        if let type = (notification as NSNotification).userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber {
            switch type.uintValue {
            case AVAudioSessionInterruptionType.began.rawValue:
                self.stop()
                break

            case AVAudioSessionInterruptionType.ended.rawValue:
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

    // MARK: Window Effects

    func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
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

        UIView.animate(withDuration: Constants.UI.Animation.visualEffectsLength, animations: { () -> Void in
            effectViews.forEach({ (view) -> () in
                if let view = view as? UIVisualEffectView {
                    view.effect = nil
                } else if !(view is UIImageView) {
                    view.alpha = 0.0
                }
            })
        }, completion: { (finished) -> Void in
                effectViews.forEach({ $0.removeFromSuperview() })
        }) 
    }

	class func del() -> AppDelegate {
		if let del = UIApplication.shared.delegate as? AppDelegate {
			return del
		}

		return AppDelegate()
	}

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}
