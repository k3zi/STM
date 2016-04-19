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
	static let baseURL = "https://api.stm.io"
	static let http = Http(baseURL: baseURL + "/v1")
	static let Settings = NSUserDefaults.standardUserDefaults()

	struct Config {
		static let systemCredentials = NSURLCredential(user: "STM-API", password: "PXsd<rhKG0r'@U.-Z`>!9V%-Z<Z", persistence: .ForSession)
		static let hashids = Hashids(salt: "pepper", minHashLength: 4, alphabet: "abcdefghijkmnpqrstuxyACDEFGHKMNPQRSTUQY23456789")
		static let streamHash = "WrfN'/:_f.#8fYh(=RY(LxTDRrU"
	}

    struct Animation {
        static let visualEffectsLength =  NSTimeInterval(0.5)
    }

	struct Color {
		static let tint = RGB(92, g: 38, b: 254)
		static let disabled = RGB(234, g: 234, b: 234)
		static let off = RGB(150, g: 150, b: 150)
	}

	struct Notification {
	}

	struct Screen {
		static let width = UIScreen.mainScreen().bounds.width
		static let height = UIScreen.mainScreen().bounds.height
		static let bounds = UIScreen.mainScreen().bounds
	}

	struct Network {
		static func POST(url: String, parameters: [String: AnyObject]?, completionHandler: CompletionBlock) {
			Constants.http.request(.POST, path: url, parameters: parameters, credential: Constants.Config.systemCredentials, completionHandler: completionHandler)
		}

		static func GET(url: String, parameters: [String: AnyObject]?, completionHandler: CompletionBlock) {
			Constants.http.request(.GET, path: url, parameters: parameters, credential: Constants.Config.systemCredentials, completionHandler: completionHandler)
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

	// Adds titleEdgeInsets to the autolayut frame
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
}

extension Int {
    func hexedString() -> String {
        return String(format:"%02x", self)
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
