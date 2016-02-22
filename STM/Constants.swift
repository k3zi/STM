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

struct Constants {
    static let baseURL = "https://api.stm.io"
    static let http = Http(baseURL: baseURL + "/v1")
    static let Settings = NSUserDefaults.standardUserDefaults()

    struct Config {
        static let systemCredentials = NSURLCredential(user: "STM-API", password: "PXsd<rhKG0r'@U.-Z`>!9V%-Z<Z", persistence: .ForSession)
        static let hashids = Hashids(salt: "pepper", minHashLength: 4, alphabet: "abcdefghijkmnpqrstuvwxy23456789")
        static let streamHash = "WrfN'/:_f.#8fYh(=RY(LxTDRrU"
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
            Constants.http.POST(url, parameters: parameters, credential: Constants.Config.systemCredentials, completionHandler: completionHandler)
        }

        static func GET(url: String, parameters: [String: AnyObject]?, completionHandler: CompletionBlock) {
            Constants.http.GET(url, parameters: parameters, credential: Constants.Config.systemCredentials, completionHandler: completionHandler)
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

extension UIView {

    class func lineWithBGColor(backgroundColor: UIColor, vertical: Bool = false, lineHeight: CGFloat = 1.0) -> UIView {
        let view = UIView()
        NSLayoutConstraint.autoSetPriority(999) { () -> Void in
            view.autoSetDimension(vertical ? .Width: .Height, toSize: (lineHeight/UIScreen.mainScreen().scale))
        }
        view.backgroundColor = backgroundColor
        return view
    }

}

//MARK: Data Transformers for ObjectMapper
public class DateTransform: TransformType {
    public typealias Object = NSDate
    public typealias JSON = AnyObject

    public init() { }

    public func transformFromJSON(value: AnyObject?) -> NSDate? {
        if let timeInt = value as? Int {
            return NSDate(timeIntervalSince1970: NSTimeInterval(timeInt))
        }

        if let timeString = value as? String {
            if let timeInt = Int(timeString) {
                return NSDate(timeIntervalSince1970: NSTimeInterval(timeInt))
            }
        }

        return nil
    }

    public func transformToJSON(value: NSDate?) -> AnyObject? {
        if let date = value {
            return Double(date.timeIntervalSince1970)
        }

        return nil
    }
}

public class IntTransform: TransformType {
    public typealias Object = Int
    public typealias JSON = AnyObject

    public init() { }

    public func transformFromJSON(value: AnyObject?) -> Int? {
        if let timeInt = value as? Int {
            return timeInt
        }

        if let timeString = value as? String {
            if let timeInt = Int(timeString) {
                return timeInt
            }
        }

        return nil
    }

    public func transformToJSON(value: Int?) -> AnyObject? {
        return value
    }
}
