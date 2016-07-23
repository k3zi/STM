//
//  KZExtensions.swift
//  KZ
//
//  Created by Kesi Maduka on 1/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

public typealias KZCompletionBlock = (String -> Void)

//MARK: UIKit Extensions

public extension UIView {

    /**
     Creates a seperator

     - parameter color: The lines color
     - parameter vertical:        Pass in true to make a vertical line instead of a horizontal
     - parameter lineHeight:      The thickness of the line (to be automatically adjusted for a devices scale)

     - returns: The line
     */
    class public func lineWithBGColor(color: UIColor, vertical: Bool = false, lineHeight: CGFloat = 1.0) -> UIView {
        let view = UIView()
        NSLayoutConstraint.autoSetPriority(999) { () -> Void in
            view.autoSetDimension(vertical ? .Width : .Height, toSize: (lineHeight / UIScreen.mainScreen().scale))
        }
        view.backgroundColor = color
        return view
    }

}

public extension UIButton {

    override public func intrinsicContentSize() -> CGSize {
        let intrinsicContentSize = super.intrinsicContentSize()

        let adjustedWidth = intrinsicContentSize.width + titleEdgeInsets.left + titleEdgeInsets.right
        let adjustedHeight = intrinsicContentSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom
        return CGSize(width: adjustedWidth, height: adjustedHeight)
    }

    /**
     Changes the backgroundColor for the specified control state

     - parameter color:    The color to use for the specified state.
     - parameter forState: The state that uses the specified image.
     */
    public func setBackgroundColor(color: UIColor?, forState: UIControlState) {
        guard let color = color else {
            return self.setBackgroundImage(nil, forState: forState)
        }

        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), color.CGColor)
        CGContextFillRect(UIGraphicsGetCurrentContext(), CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.setBackgroundImage(colorImage, forState: forState)
    }

}

public extension UIViewController {

    /**
     Displays an error alert to the user.

     - parameter message: The error message to display in the alert.
     */
    public func showError(message: String) {
        showAlert("Error", message: message)
    }

    /**
     Displays a success alert to the user.

     - parameter message: The success message to display in the alert.
     */
    public func showSuccess(message: String) {
        showAlert("Success", message: message)
    }

    /**
     Displays alert to user.

     - parameter title:   The title of the alert.
     - parameter message: The message to place in the alert.
     */
    public func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.view.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }

    /**
     Handles a network response object and executes a callback on success

     - parameter response:          The unserialized response object
     - parameter error:             Pass in an error to be displayed in a UIAlert
     - parameter successCompletion: Called when response['success'] == true
     */
    public func handleResponse(response: AnyObject?, error: NSError?, successCompletion: AnyObject -> Void) {
        handleResponse(response, error: error, successCompletion: successCompletion, errorCompletion: nil)
    }

    /**
     Handles a network response object and executes a callback on success/error

     - parameter response:          The unserialized response object
     - parameter error:             Pass in an error to be displayed in a UIAlert
     - parameter successCompletion: Called when response['success'] == true
     - parameter errorCompletion:   Called when response['success'] is a String or error != nil
     */
    public func handleResponse(response: AnyObject?, error: NSError?, successCompletion: (AnyObject -> Void)? = nil, errorCompletion: (String -> Void)? = nil) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let error = error {
                print(error)
                print(error.code)
                if let errorCompletion = errorCompletion {
                    errorCompletion(error.localizedDescription)
                }

                if ![-1011, -1001, -1004, 9, 404, 500, -1005].contains(error.code) {
                    self.showError(error.localizedDescription)
                }
            } else if let response = response {
                guard let success = response["success"] as? Bool else {
                    return
                }

                if success {
                    guard let result = response["result"] else {
                        return
                    }

                    if let result = result, successCompletion = successCompletion {
                        successCompletion(result)
                    }
                } else if let error = response["error"] as? String {
                    if let suppress = response["suppress"] as? Bool {
                        if suppress {
                            return
                        }
                    }

                    if let errorCompletion = errorCompletion {
                        errorCompletion(error)
                    }

                    self.showError(error)
                }
            }
        })
    }

    /**
     Goes to the previous view controller respecting the presentingViewController first then the navigation stack
     */
    public func goBack() {
        if let vc = self.presentingViewController {
            vc.dismissViewControllerAnimated(true, completion: nil)
        } else if let nav = self.navigationController {
            nav.popViewControllerAnimated(true)
        }
    }
}

//MARK: Foundation Extensions

public extension String {
    public func firstCharacterUpperCase() -> String {
        let lowercaseString = self.lowercaseString

        return lowercaseString.stringByReplacingCharactersInRange(lowercaseString.startIndex...lowercaseString.startIndex, withString: String(lowercaseString[lowercaseString.startIndex]).uppercaseString)
    }
}
