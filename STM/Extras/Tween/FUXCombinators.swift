//
//  FUXCombinators.swift
//  FUX
//
//  Created by Garrit Schaap on 04.02.15.
//  Copyright (c) 2015 Garrit UG (haftungsbeschränkt). All rights reserved.
//

import UIKit

infix operator >>> { associativity left }
public func >>> (left: Float, right: FUXTween) -> FUXTween {
    return FUXTween.Delay(left, Box(right))
}

infix operator ~ { associativity left }
public func ~ (left: Float, right: FUXValue) -> FUXTween {
    return tween(duration: left, value: right)
}

infix operator + { associativity left }
public func + (left: FUXValue, right: FUXValue) -> FUXValue {
    return FUXValue.Values([ Box(left), Box(right) ])
}

infix operator >>| { associativity left }
public func >>| (left: FUXTween, right: () -> ()) -> FUXTween {
    return createOnComplete(left, onComplete: right)
}


public func tween(duration duration: Float, value: FUXValue) -> FUXTween {
    return FUXTween.Tween(duration, value)
}

public func delayedTween(delay delay: Float, tween: FUXTween) -> FUXTween {
    return FUXTween.Delay(delay, Box(tween))
}

public func createDelayedTween(duration duration: Float, delay: Float, value: FUXValue) -> FUXTween {
    return FUXTween.Delay(delay, Box(FUXTween.Tween(duration, value)))
}

public func yoyo(tween tween: FUXTween) -> FUXTween {
    return FUXTween.YoYo(Box(tween))
}

public func speed(speed speed: Float, tween: FUXTween) -> FUXTween {
    return FUXTween.Speed(speed, Box(tween))
}

public func repeatTween(repeatInt repeatInt: Int, tween: FUXTween) -> FUXTween {
    return FUXTween.Repeat(repeatInt, Box(tween))
}

public func createValue(value: Float -> ()) -> FUXValue {
    return FUXValue.Value(value)
}

public func createOnComplete(tween: FUXTween, onComplete: () -> ()) -> FUXTween {
    return FUXTween.OnComplete(Box(tween), onComplete)
}

public func fromToPoint(from from: CGPoint, to: CGPoint, valueFunc: CGPoint -> ()) -> FUXValue {
    return FUXValue.Value({ tweenValue in valueFunc(CGPoint(x: from.x + (to.x - from.x) * CGFloat(tweenValue), y: from.y + (to.y - from.y) * CGFloat(tweenValue))) })
}

public func fromToValueFunc(from from: Float, to: Float, valueFunc: Float -> ()) -> FUXValue {
    return FUXValue.Value({ tweenValue in valueFunc(from + (to - from) * tweenValue) })
}

public func viewFrameValue(view view: UIView, to: CGRect) -> FUXValue {
    let from = view.frame
    let change = CGRect(x: to.origin.x - from.origin.x, y: to.origin.y - from.origin.y, width: to.size.width - from.size.width, height: to.size.height - from.size.height)
    return FUXValue.Value({ tweenValue in
        let x = from.origin.x + change.origin.x * CGFloat(tweenValue)
        let y = from.origin.y + change.origin.y * CGFloat(tweenValue)
        let width = from.size.width + change.size.width * CGFloat(tweenValue)
        let height = from.size.height + change.size.height * CGFloat(tweenValue)
        view.frame = CGRect(x: x, y: y, width: width, height: height) })
}

public func constraintValue(view view: UIView, constraint: NSLayoutConstraint, constant: CGFloat) -> FUXValue {
    let from = constraint.constant
    let change = constant - constraint.constant
    return FUXValue.Value({ tweenValue in constraint.constant = from + change * CGFloat(tweenValue); view.layoutIfNeeded() })
}

public func viewSizeValue(view view: UIView, to: CGSize) -> FUXValue {
    let from = view.frame
    let change = CGSize(width: to.width - from.width, height: to.height - from.height)
    return FUXValue.Value({ tweenValue in
        view.frame.origin.x = from.origin.x
        view.frame.origin.y = from.origin.y
        view.frame.size.width = from.size.width + change.width * CGFloat(tweenValue)
        view.frame.size.height = from.size.height + change.height * CGFloat(tweenValue) })
}

public func viewPositionValue(view view: UIView, to: CGPoint) -> FUXValue {
    let from = view.frame
    let change = CGPoint(x: to.x - from.origin.x, y: to.y - from.origin.y)
    return FUXValue.Value({ tweenValue in
        view.frame.origin.x = from.origin.x + change.x * CGFloat(tweenValue)
        view.frame.origin.y = from.origin.y + change.y * CGFloat(tweenValue)
        view.frame.size.width = from.size.width
        view.frame.size.height = from.size.height })
}

public func viewScaleValue(view view: UIView, from: CGFloat, to: CGFloat) -> FUXValue {
    let change = to - from
    return FUXValue.Value({ tweenValue in
        let scale = from + change * CGFloat(tweenValue)
        view.transform = CGAffineTransformMakeScale(scale, scale)
    })
}

public func viewRotationValue(view view: UIView, from: CGFloat, to: CGFloat) -> FUXValue {
    let change = to - from
    return FUXValue.Value({ tweenValue in
        let rotation = from + change * CGFloat(tweenValue)
        view.transform = CGAffineTransformMakeRotation(rotation)
    })
}

public func backgroundColor(view view: UIView, to: UIColor) -> FUXValue {
    let from = view.backgroundColor!
    return FUXValue.Value({ tweenValue in
        let fromColors = CGColorGetComponents(from.CGColor);
        let toColors = CGColorGetComponents(to.CGColor);
        
        let red = CGFloat(Float(fromColors[0]) * (1 - tweenValue) + Float(toColors[0]) * tweenValue)
        let green = CGFloat(Float(fromColors[1]) * (1 - tweenValue) + Float(toColors[1]) * tweenValue)
        let blue = CGFloat(Float(fromColors[2]) * (1 - tweenValue) + Float(toColors[2]) * tweenValue)
        let alpha = CGFloat(Float(fromColors[3]) * (1 - tweenValue) + Float(toColors[3]) * tweenValue)
        view.backgroundColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
    })
}
