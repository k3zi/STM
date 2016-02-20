//
//  KZExtensions.swift
//  KZ
//
//  Created by Kesi Maduka on 1/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

public extension UIButton {
	override public func intrinsicContentSize() -> CGSize {
		let intrinsicContentSize = super.intrinsicContentSize()
		let adjustedWidth = intrinsicContentSize.width + titleEdgeInsets.left + titleEdgeInsets.right
		let adjustedHeight = intrinsicContentSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom
		return CGSize(width: adjustedWidth, height: adjustedHeight)
	}
    
    public func setBackgroundColor(color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), color.CGColor)
        CGContextFillRect(UIGraphicsGetCurrentContext(), CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, forState: forState)
    }
}

public extension String {
	public func firstCharacterUpperCase() -> String {
		let lowercaseString = self.lowercaseString

		return lowercaseString.stringByReplacingCharactersInRange(lowercaseString.startIndex...lowercaseString.startIndex, withString: String(lowercaseString[lowercaseString.startIndex]).uppercaseString)
	}
}

public extension UIViewController {

	/**
	 Displays an error alert to the user

	 - Parameters:
	 - message: The error message to display in the alert
	 */
	public func showError(message: String) {
		showAlert("Error", message: message)
	}
    
    /**
    Displays a success alert to the user
    
    - Parameters:
    - message: The success message to display in the alert
    */
	public func showSuccess(message: String) {
		showAlert("Success", message: message)
	}

	/**
	 Displays alert to user

	 - Parameters:
	 - title: The title of the alert
	 - message: The message to place in the alert
	 */
	func showAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}

	public func handleResponse(response: AnyObject?, error: NSError?, successCompletion: AnyObject -> Void) {
		handleResponse(response, error: error, successCompletion: successCompletion, errorCompletion: nil)
	}

	public func handleResponse(response: AnyObject?, error: NSError?, successCompletion: (AnyObject -> Void)? = nil, errorCompletion: (String -> Void)? = nil) {
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
				if let error = error {
					if let errorCompletion = errorCompletion {
						errorCompletion(error.localizedDescription)
					}
                    self.showError(error.localizedDescription)
				} else if let response = response {
					if let success = response["success"] as? Bool {
						if success {
							if let result = response["result"] {
								if let result = result {
									if let successCompletion = successCompletion {
										successCompletion(result)
									}
								}
							}
						} else if let error = response["error"] as? String {
							self.showError(error)
                            if let errorCompletion = errorCompletion {
                                errorCompletion(error)
                            }
                            self.showError(error)
						}
					}
				}
			})
	}

	public func goBack() {
		if let nav = self.navigationController {
			nav.popViewControllerAnimated(true)
		} else if let vc = self.presentingViewController {
			vc.dismissViewControllerAnimated(true, completion: nil)
		}
	}
}
