//
//  KZFunctions.swift
//  KZ
//
//  Created by Kesi Maduka on 1/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

public func RGB(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) -> UIColor {
	return UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
}

public func RGB(x: CGFloat, a: CGFloat = 1.0) -> UIColor {
	return RGB(x, g: x, b: x, a: a)
}

public func HEX(str: String) -> UIColor {
	let hex = str.stringByTrimmingCharactersInSet(NSCharacterSet.alphanumericCharacterSet().invertedSet)
	var int = UInt32()
	NSScanner(string: hex).scanHexInt(&int)
	let r, g, b: UInt32
	switch hex.characters.count {
	case 3:
		(r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
	case 6:
		(r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
	default:
		(r, g, b) = (1, 1, 0)
	}

	return RGB(CGFloat(r), g: CGFloat(g), b: CGFloat(b))
}

public func delay(delay: Double, closure: () -> ()) {
	dispatch_after(
		dispatch_time(
			DISPATCH_TIME_NOW,
			Int64(delay * Double(NSEC_PER_SEC))
		),
		dispatch_get_main_queue(), closure)
}