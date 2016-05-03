//
//  Constants.swift
//  Dawgtown
//
//  Created by Kesi Maduka on 7/25/15.
//  Copyright (c) 2015 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import CoreLocation

//MARK: Constants
//swiftlint:disable nesting

struct Constants {

	static let http = Http(baseURL: Config.apiBaseURL)
	static let Settings = NSUserDefaults.standardUserDefaults()

	struct Config {
        static let apiVersion = "1"

        static let siteBaseURL = "https://stm.io"
        static let apiBaseURL = "https://api.stm.io/v\(apiVersion)"
		static let systemCredentials = NSURLCredential(user: "STM-API", password: "PXsd<rhKG0r'@U.-Z`>!9V%-Z<Z", persistence: .ForSession)
		static let hashids = Hashids(salt: "pepper", minHashLength: 4, alphabet: "abcdefghijkmnpqrstuxyACDEFGHKMNPQRSTUQY23456789")
		static let streamHash = "WrfN'/:_f.#8fYh(=RY(LxTDRrU"
        static let userDefaultsSecret = "eQpvrIz91DyP9Ge4GY4LRz0vbbG7ot"
	}

	struct Notification {
        static let UpdateUserProfile = "STMNotificationUpdateUserProfile"
        static let DidPostComment = "STMNotificationDidPostComment"
        static let DidPostMessage = "STMNotificationDidMessage"
        static let DidCreateStream = "STMNotificationDidCreateStream"
        static let DidLikeComment = "STMNotificationDidLikeComment"
        static let DidRepostComment = "STMNotificationDidRepostComment"

        func UpdateForComment(comment: STMComment) -> String {
            return "STMNotificationUpdateForComment-\(comment.id)"
        }
	}

	struct Network {
		static func POST(url: String, parameters: [String: AnyObject]?, completionHandler: CompletionBlock) {
			Constants.http.request(.POST, path: url, parameters: parameters, credential: Constants.Config.systemCredentials, completionHandler: completionHandler)
		}

		static func GET(url: String, parameters: [String: AnyObject]?, completionHandler: CompletionBlock) {
			Constants.http.request(.GET, path: url, parameters: parameters, credential: Constants.Config.systemCredentials, completionHandler: completionHandler)
		}

        static func UPLOAD(url: String, data: NSData, parameters: [String: AnyObject]?, progress: ProgressBlock? = nil, completionHandler: CompletionBlock) {
            Constants.http.upload(url, data: data, parameters: parameters, credential: Constants.Config.systemCredentials, method: .POST, responseSerializer: JsonResponseSerializer(), progress: progress, completionHandler: completionHandler)
        }
	}

    struct UI {

        struct Animation {
            static let visualEffectsLength =  NSTimeInterval(0.5)
        }

        struct Color {
            static let tint = RGB(92, g: 38, b: 254)
            static let disabled = RGB(234, g: 234, b: 234)
            static let off = RGB(150, g: 150, b: 150)
            static let imageViewDefault = RGB(197, g: 198, b: 199)
        }

        struct Screen {
            static let width = UIScreen.mainScreen().bounds.width
            static let height = UIScreen.mainScreen().bounds.height
            static let bounds = UIScreen.mainScreen().bounds

            static func keyboardAdjustment(show: Bool, rect: CGRect) -> CGFloat {
                return (show ? (-rect.size.height + (AppDelegate.del().playerIsMinimized() ? 40 : 0)) : 0)
            }
        }

        struct Tabs {
            static let indexForDashboard = 0
            static let indexForHostStream = 1
            static let indexForMessages = 2
            static let indexForSearch = 3
            static let indexForProfile = 4
        }

    }

}

enum StreamType {
	case Local
	case Global
}

@IBDesignable class ExtendedButton: UIButton {
	@IBInspectable var touchMargin: CGFloat = 30.0

	override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
		let extendedArea = CGRectInset(self.bounds, -touchMargin, -touchMargin)
		return CGRectContainsPoint(extendedArea, point)
	}
}

/**
 Delays code excecution

 - parameter delay:   The number of seconds to delay for
 - parameter closure: The block to be executed after the delay
 */
func delay(delay: Double, closure: () -> ()) {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
}

extension UIButton {

	public override func intrinsicContentSize() -> CGSize {
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

extension UITableView {

    func scrollToBottom(animated: Bool = true) {
        let section = self.numberOfSections
        guard section > 0 else {
            return
        }

        let row = self.numberOfRowsInSection(section - 1)
        guard row > 0 else {
            return
        }

        self.scrollToRowAtIndexPath(NSIndexPath(forRow: row - 1, inSection: section - 1), atScrollPosition: .Bottom, animated: animated)
    }

}

extension UIView {

	class func lineWithBGColor(backgroundColor: UIColor, vertical: Bool = false, lineHeight: CGFloat = 1.0) -> UIView {
		let view = UIView()
		NSLayoutConstraint.autoSetPriority(999) { () -> Void in
			view.autoSetDimension(vertical ? .Width : .Height, toSize: (lineHeight / UIScreen.mainScreen().scale))
		}
		view.backgroundColor = backgroundColor
		return view
	}

    func estimatedHeight(maxWidth: CGFloat) -> CGFloat {
        return self.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.max)).height
    }

}

extension Int {

    func hexedString() -> String {
        return String(format:"%02x", self)
    }

   func formatUsingAbbrevation() -> String {
        let numFormatter = NSNumberFormatter()

        typealias Abbrevation = (threshold: Double, divisor: Double, suffix: String)
        let abbreviations: [Abbrevation] = [(0, 1, ""),
                                           (1000.0, 1000.0, "K"),
                                           (100_000.0, 1_000_000.0, "M"),
                                           (100_000_000.0, 1_000_000_000.0, "B")]

        let startValue = Double(abs(self))
        let abbreviation: Abbrevation = {
            var prevAbbreviation = abbreviations[0]
            for tmpAbbreviation in abbreviations {
                if startValue < tmpAbbreviation.threshold {
                    break
                }
                prevAbbreviation = tmpAbbreviation
            }
            return prevAbbreviation
        }()

        let value = Double(self) / abbreviation.divisor
        numFormatter.positiveSuffix = abbreviation.suffix
        numFormatter.negativeSuffix = abbreviation.suffix
        numFormatter.allowsFloats = true
        numFormatter.minimumIntegerDigits = 1
        numFormatter.minimumFractionDigits = 0
        numFormatter.maximumFractionDigits = 1

        return numFormatter.stringFromNumber(NSNumber (double:value)) ?? ""
    }

}

extension NSData {

    func hexedString() -> String {
        var string = String()
        for i in UnsafeBufferPointer<UInt8>(start: UnsafeMutablePointer<UInt8>(bytes), count: length) {
            string += Int(i).hexedString()
        }
        return string
    }

    func MD5() -> NSData {
        let result = NSMutableData(length: Int(CC_MD5_DIGEST_LENGTH))!
        CC_MD5(bytes, CC_LONG(length), UnsafeMutablePointer<UInt8>(result.mutableBytes))
        return NSData(data: result)
    }

    func SHA1() -> NSData {
        let result = NSMutableData(length: Int(CC_SHA1_DIGEST_LENGTH))!
        CC_SHA1(bytes, CC_LONG(length), UnsafeMutablePointer<UInt8>(result.mutableBytes))
        return NSData(data: result)
    }

}

extension String {

    func MD5() -> String {
        return (self as NSString).dataUsingEncoding(NSUTF8StringEncoding)!.MD5().hexedString()
    }

    func SHA1() -> String {
        return (self as NSString).dataUsingEncoding(NSUTF8StringEncoding)!.SHA1().hexedString()
    }

}

extension UIImage {

    convenience init(view: UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(CGImage: image.CGImage!)
    }

}

extension UIViewController {

    func donePressed() {
        cancelPressed()
    }

    func cancelPressed() {
        view.endEditing(true)
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func dismissPopup() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}

extension UIScrollView {
    func dg_stopScrollingAnimation() {}
}

extension _ArrayType where Generator.Element : Equatable {
    mutating func removeObject(object: Self.Generator.Element) {
        while let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
}

func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
    let newWidth = round(newWidth)
    let scale = newWidth / image.size.width
    if scale < 1.0 {
        let newHeight = round(image.size.height * scale)
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.drawInRect(CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    return image
}

func numberOfLinesInLabel(yourString: String, labelWidth: CGFloat, labelHeight: CGFloat, font: UIFont) -> Int {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.minimumLineHeight = labelHeight
    paragraphStyle.maximumLineHeight = labelHeight
    paragraphStyle.lineBreakMode = .ByWordWrapping

    let attributes: [String: AnyObject] = [NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraphStyle]

    let constrain = CGSize(width: labelWidth, height: CGFloat(Float.infinity))

    let size = yourString.sizeWithAttributes(attributes)
    let stringWidth = size.width

    let numberOfLines = ceil(Double(stringWidth/constrain.width))

    return Int(numberOfLines)
}
