//
//  AppDelegate.swift
//  STM
//
//  Created by Kesi Maduka on 1/29/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import IQKeyboardManager

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var shortcutItem: UIApplicationShortcutItem?
    var currentUser: STMUser?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        IQKeyboardManager.sharedManager().shouldShowTextFieldPlaceholder = false
        IQKeyboardManager.sharedManager().enable = true
        NSUserDefaults.standardUserDefaults().setSecret("eQpvrIz91DyP9Ge4GY4LRz0vbbG7ot")
        
        let nav = NavigationController(rootViewController: InitialViewController())
        nav.setNavigationBarHidden(true, animated: false)
        
        window = Window(frame: Constants.Screen.bounds)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil))
        application.registerForRemoteNotifications()
        
        NSSetUncaughtExceptionHandler { exception in
            print(exception)
            print(exception.callStackSymbols)
        }
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let characterSet = NSCharacterSet(charactersInString: "<>")
        let deviceTokenString = (deviceToken.description as NSString).stringByTrimmingCharactersInSet( characterSet).stringByReplacingOccurrencesOfString( " ", withString: "" ) as String
        Constants.Settings.setSecretObject(deviceTokenString, forKey: "deviceTokenString")
    }
    
    func createTabSet() -> UITabBarController {
        let tabVC = UITabBarController()
        let tab1 = NavigationController(rootViewController: DashboardViewController())
        let tab2 = NavigationController(rootViewController: CreateStreamViewController())
        let tab3 = NavigationController(rootViewController: DashboardViewController())
        let tab4 = NavigationController(rootViewController: DashboardViewController())
        let tab5 = NavigationController(rootViewController: DashboardViewController())
        tabVC.setViewControllers([tab1, tab2, tab3, tab4, tab5], animated: false)
        
        self.window?.rootViewController = tabVC
        self.window?.makeKeyAndVisible()
        
        tab1.tabBarItem = UITabBarItem(title: "Dashboard", image: UIImage(named: "tabDashboard"), tag: 1)
        
        tab2.tabBarItem = UITabBarItem(title: "Host", image: UIImage(named: "tabCreateStream"), tag: 2)
        
        tab3.tabBarItem = UITabBarItem(title: "Local", image: UIImage(named: "tabJoinStream"), tag: 3)
        
        tab4.tabBarItem = UITabBarItem(title: "Friends", image: UIImage(named: "tabFriends"), tag: 4)
        
        tab5.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(named: "tabProfile"), tag: 5)
        
        tabVC.selectedViewController = tab1
        
        if let item = shortcutItem {
            self.handleShortcutItem(item, completionHandler: nil)
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
        
        if let window = window as? Window {
            let tabSet = AppDelegate.del().createTabSet()
            UIView.transitionWithView(window, duration: window.screenIsReady == true ? 0.5: 0.0, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                AppDelegate.del().window?.rootViewController = tabSet
                }, completion: { (finished) -> Void in
                    if window.screenIsReady == false {
                        window.screenIsReady = true
                    }
            })
        }
        
        if let token = Constants.Settings.secretObjectForKey("deviceTokenString") {
            Constants.Network.POST("/updateAPNS", parameters: ["token": token], completionHandler: { (response, error) -> Void in
                print("Network: Updated Token")
            })
        }
    }
    
    func handleShortcutItem(item: UIApplicationShortcutItem, completionHandler: ((Bool) -> Void)?) -> Bool {
        return true
    }
    
    class func del() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }
}

