//
//  Constants.swift
//  Dawgtown
//
//  Created by Kesi Maduka on 7/25/15.
//  Copyright (c) 2015 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import CoreLocation
import CryptoSwift

//MARK: Constants
//swiftlint:disable nesting
//swiftlint:disable type_name

typealias CompletionBlock = (JSON?, Error?) -> Void

// Create a protocol extension that objects can conform to.
protocol Initializer {}
extension Initializer {
    func with(_ bootStrap: (inout Self) -> ()) -> Self {
        var s = self
        bootStrap(&s)
        return s
    }

    func withStatic(_ bootStrap: (inout Self) -> ()) {
        var s = self
        bootStrap(&s)
    }
}
// Enable all NSObjects to have "with"
extension NSObject: Initializer {}


struct Constants {

	static let Settings = UserDefaults.standard

	struct Config {
        static let apiVersion = "1"

        static let siteBaseURL = "https://stm.io"
        /*#if DEBUG
        static let apiBaseURL = "https://api-dev.stm.io/v\(apiVersion)"
        static let systemCredentials = URLCredential(user: "STM-DEV-API", password: "C/=}SU,nv)A**9cX.L&ML56", persistence: .forSession)
        #else*/
        static let apiBaseURL = "https://api.stm.io/v\(apiVersion)"
        static let systemCredentials = URLCredential(user: "STM-API", password: "PXsd<rhKG0r'@U.-Z`>!9V%-Z<Z", persistence: .forSession)
        //#endif
		static let hashids = Hashids(salt: "pepper", minHashLength: 4, alphabet: "abcdefghijkmnpqrstuxyACDEFGHKMNPQRSTUQY23456789")
		static let streamHash = "WrfN'/:_f.#8fYh(=RY(LxTDRrU"
        static let userDefaultsSecret = "eQpvrIz91DyP9Ge4GY4LRz0vbbG7ot"

        static let twitterConsumerKey = "i9HggEKaSKNRVnHBBQDdFDQx1"
        static let twitterConsumerSecret = "l2iuaqf8bKyW01El13M0NkC3M6fNGFlQAVWByhnZROsQwFIbFn"

        static func sessionConfig() -> URLSessionConfiguration {
            let sessionConfig = URLSessionConfiguration.default
            let credentialStorage = URLCredentialStorage.shared
            credentialStorage.set(Constants.Config.systemCredentials, for: URLProtectionSpace(host: "api.stm.io", port: 443, protocol: "https", realm: nil, authenticationMethod: NSURLAuthenticationMethodHTTPBasic))
            credentialStorage.set(Constants.Config.systemCredentials, for: URLProtectionSpace(host: "api-dev.stm.io", port: 443, protocol: "https", realm: nil, authenticationMethod: NSURLAuthenticationMethodHTTPBasic))
            sessionConfig.urlCredentialStorage = credentialStorage
            return sessionConfig
        }
	}

	struct Notification {
        static let UpdateUserProfile = "STMNotificationUpdateUserProfile"
        static let DidPostComment = "STMNotificationDidPostComment"
        static let DidPostMessage = "STMNotificationDidMessage"
        static let DidCreateStream = "STMNotificationDidCreateStream"
        static let DidLikeComment = "STMNotificationDidLikeComment"
        static let DidRepostComment = "STMNotificationDidRepostComment"

        func UpdateForComment(_ comment: STMComment) -> String {
            return "STMNotificationUpdateForComment-\(comment.id)"
        }
	}

	struct Network {
        static func defaultHeaders() -> [String: String]? {
            guard let user = Constants.Settings.secretObject(forKey: "user") as? [String: AnyObject] else {
                return nil
            }

            guard let username = user["username"] as? String else {
                return nil
            }

            guard let password = user["password"] as? String else {
                return nil
            }

            return ["STM-Username": username, "STM-Password": password]
        }

        static func POST(_ url: String, parameters: [String: Any]? = nil, completionHandler: @escaping CompletionBlock) {
            guard let absoluteURL = URL(string: Constants.Config.apiBaseURL + url) else {
                completionHandler(nil, nil)
                return
            }

            var request = URLRequest(url: absoluteURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let headers = Constants.Network.defaultHeaders() {
                for (field, value) in headers {
                    request.setValue(value, forHTTPHeaderField: field)
                }
            }

            if let parameters = parameters {
                request.httpBody = try! JSONSerialization.data(withJSONObject: parameters)
            }

            Alamofire.request(request)
                .authenticate(usingCredential: Constants.Config.systemCredentials).responseJSON { (response) in
                    switch response.result {
                    case .success:
                        if let json = response.result.value as? JSON {
                            completionHandler(json, nil)
                        }
                    case .failure(let error):
                        completionHandler(nil, error)
                    }
            }
        }

        static func GET(_ url: String, parameters: [String: AnyObject]? = nil, completionHandler: @escaping CompletionBlock) {
            guard let absoluteURL = URL(string: Constants.Config.apiBaseURL + url) else {
                completionHandler(nil, nil)
                return
            }

            var request = URLRequest(url: absoluteURL)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let headers = Constants.Network.defaultHeaders() {
                for (field, value) in headers {
                   request.setValue(value, forHTTPHeaderField: field)
                }
            }

            if let parameters = parameters {
                request.httpBody = try! JSONSerialization.data(withJSONObject: parameters)
            }

            Alamofire.request(request)
                .authenticate(usingCredential: Constants.Config.systemCredentials).responseJSON { (response) in
                    switch response.result {
                    case .success:
                        if let json = response.result.value as? JSON {
                            completionHandler(json, nil)
                        }
                    case .failure(let error):
                        completionHandler(nil, error)
                    }
            }
        }

        static func UPLOAD(_ url: String, data: Data, progressHandler: @escaping (Double) -> Void, completionHandler: @escaping CompletionBlock) {
            Alamofire.upload(data, to: Constants.Config.apiBaseURL + url, headers: Constants.Network.defaultHeaders())
                .authenticate(usingCredential: Constants.Config.systemCredentials)
                .uploadProgress { progress in // main queue by default
                    progressHandler(progress.fractionCompleted)
                }
                .responseJSON { (response) in
                    switch response.result {
                    case .success:
                        if let json = response.result.value as? JSON {
                            completionHandler(json, nil)
                        }
                    case .failure(let error):
                        completionHandler(nil, error)
                    }
            }
        }
    }

    struct UI {

        struct Animation {
            static let visualEffectsLength =  TimeInterval(0.5)
        }

        struct Color {
            static let tint = RGB(92, g: 38, b: 254)
            static let disabled = RGB(234, g: 234, b: 234)
            static let off = RGB(150, g: 150, b: 150)
            static let imageViewDefault = RGB(197, g: 198, b: 199)
        }

        struct Screen {
            static let width = UIScreen.main.bounds.width
            static let height = UIScreen.main.bounds.height
            static let bounds = UIScreen.main.bounds

            static func keyboardAdjustment(_ show: Bool, rect: CGRect) -> CGFloat {
                guard show else {
                    return 0.0
                }

                var height = -rect.size.height

                if AppDelegate.del().playerIsMinimized() {
                    height = height + 40
                }

                return height
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
	case local
	case global
}

@IBDesignable class ExtendedButton: UIButton {
	@IBInspectable var touchMargin: CGFloat = 30.0

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let extendedArea = self.bounds.insetBy(dx: -touchMargin, dy: -touchMargin)
		return extendedArea.contains(point)
	}
}

/**
 Delays code excecution

 - parameter delay:   The number of seconds to delay for
 - parameter closure: The block to be executed after the delay
 */
func delay(_ delay: Double, closure: @escaping () -> ()) {
	DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

extension UIButton {

    open override var intrinsicContentSize: CGSize {
		let intrinsicContentSize = super.intrinsicContentSize
		let adjustedWidth = intrinsicContentSize.width + titleEdgeInsets.left + titleEdgeInsets.right
		let adjustedHeight = intrinsicContentSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom
		return CGSize(width: adjustedWidth, height: adjustedHeight)
	}

	public func setBackgroundColor(_ color: UIColor, forState: UIControlState) {
		UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
		UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
		UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
		let colorImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		self.setBackgroundImage(colorImage, for: forState)
	}

}

extension UITableView {

    func scrollToBottom(_ animated: Bool = true) {
        let section = self.numberOfSections
        guard section > 0 else {
            return
        }

        let row = self.numberOfRows(inSection: section - 1)
        guard row > 0 else {
            return
        }

        let index = IndexPath(row: row - 1, section: section - 1)
        self.scrollToRow(at: index, at: .bottom, animated: animated)
    }

}

extension UIView {

	class func lineWithBGColor(_ backgroundColor: UIColor, vertical: Bool = false, lineHeight: CGFloat = 1.0) -> UIView {
		let view = UIView()
		NSLayoutConstraint.autoSetPriority(999) { () -> Void in
			view.autoSetDimension(vertical ? .width : .height, toSize: (lineHeight / UIScreen.main.scale))
		}
		view.backgroundColor = backgroundColor
		return view
	}

    func estimatedHeight(_ maxWidth: CGFloat) -> CGFloat {
        return self.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)).height
    }

}

extension Int {

    func hexedString() -> String {
        return String(format:"%02x", self)
    }

   func formatUsingAbbrevation() -> String {
        let numFormatter = NumberFormatter()

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

        return numFormatter.string(from: NSNumber (value: value as Double)) ?? ""
    }

}

extension Date {
    func shortRelativeDate() -> String {

        let timeInterval = -self.timeIntervalSinceNow

        switch timeInterval {
        case 0..<60:
            return String(format: "%.fs", timeInterval)
        case 60..<(60 * 60):
            return String(format: "%.fm", timeInterval / 60)
        case (60 * 60)..<(60 * 60 * 24):
            return String(format: "%.fh", timeInterval / (60 * 60))
        case (60 * 60 * 24)..<(60 * 60 * 24 * 365):
            return String(format: "%.fd", timeInterval / (60 * 60 * 24))
        default:
            return String(format: "%.fy", timeInterval / (60 * 60 * 24 * 365))
        }
    }
}

extension Data {

    func hexedString() -> String {
        return self.bytes.toHexString()
    }

    func MD5() -> Data {
        return self.md5()
    }

    func SHA1() -> Data? {
        return self.sha1()
    }

}

extension String {

    func MD5() -> String {
        return (self as NSString).data(using: String.Encoding.utf8.rawValue)!.MD5().hexedString()
    }

    func SHA1() -> String {
        if let data = self.data(using: .utf8), let hex = data.SHA1() {
            return hex.hexedString()
        }

        return ""
    }

}

extension UIImage {

     class func imageFrom(view: UIView) -> UIImage {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return UIImage(cgImage: (image?.cgImage!)!)
    }

}

extension UIViewController {

    func donePressed() {
        cancelPressed()
    }

    func cancelPressed() {
        view.endEditing(true)
    }

    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func dismissPopup() {
        self.dismiss(animated: true, completion: nil)
    }

}

extension UIScrollView {
    func dg_stopScrollingAnimation() {}
}

extension UIColor {

    var hexString: String {
        let components = self.cgColor.components

        let red = Float((components?[0])!)
        let green = Float((components?[1])!)
        let blue = Float((components?[2])!)
        return String(format: "%02lX%02lX%02lX", lroundf(red * 255), lroundf(green * 255), lroundf(blue * 255))
    }

}

extension Array where Element: Equatable {
    mutating func removeObject(_ object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}

func resizeImage(_ image: UIImage, newWidth: CGFloat) -> UIImage {
    let newWidth = round(newWidth)
    let scale = newWidth / image.size.width
    if scale < 1.0 {
        let newHeight = round(image.size.height * scale)
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }

    return image
}

func numberOfLinesInLabel(_ yourString: String, labelWidth: CGFloat, labelHeight: CGFloat, font: UIFont) -> Int {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.minimumLineHeight = labelHeight
    paragraphStyle.maximumLineHeight = labelHeight
    paragraphStyle.lineBreakMode = .byWordWrapping

    let attributes: [String: AnyObject] = [NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraphStyle]

    let constrain = CGSize(width: labelWidth, height: CGFloat(Float.infinity))

    let size = yourString.size(attributes: attributes)
    let stringWidth = size.width

    let numberOfLines = ceil(Double(stringWidth/constrain.width))

    return Int(numberOfLines)
}
