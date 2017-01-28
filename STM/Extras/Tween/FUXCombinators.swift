//
//  FUXCombinators.swift
//  FUX
//
//  Created by Garrit Schaap on 04.02.15.
//  Copyright (c) 2015 Garrit UG (haftungsbeschränkt). All rights reserved.
//

import UIKit

precedencegroup FUXPrec {
    associativity: left
    higherThan: AssignmentPrecedence
    lowerThan: MultiplicationPrecedence
}

infix operator >>> : FUXPrec
public func >>> (left: Float, right: FUXTween) -> FUXTween {
    return FUXTween.delay(left, Box(right))
}

infix operator ~ : FUXPrec
public func ~ (left: Float, right: FUXValue) -> FUXTween {
    return tween(left, value: right)
}

infix operator + : FUXPrec
public func + (left: FUXValue, right: FUXValue) -> FUXValue {
    return FUXValue.values([ Box(left), Box(right) ])
}

infix operator >>| : FUXPrec
public func >>| (left: FUXTween, right: @escaping () -> ()) -> FUXTween {
    return createOnComplete(left, onComplete: right)
}

public func tween(_ duration: Float, value: FUXValue) -> FUXTween {
    return FUXTween.tween(duration, value)
}

public func delayedTween(_ delay: Float, tween: FUXTween) -> FUXTween {
    return FUXTween.delay(delay, Box(tween))
}

public func createDelayedTween(_ duration: Float, delay: Float, value: FUXValue) -> FUXTween {
    return FUXTween.delay(delay, Box(FUXTween.tween(duration, value)))
}

public func yoyo(_ tween: FUXTween) -> FUXTween {
    return FUXTween.yoYo(Box(tween))
}

public func speed(_ speed: Float, tween: FUXTween) -> FUXTween {
    return FUXTween.speed(speed, Box(tween))
}

public func repeatTween(_ repeatInt: Int, tween: FUXTween) -> FUXTween {
    return FUXTween.repeat(repeatInt, Box(tween))
}

public func createValue(_ value: @escaping (Float) -> ()) -> FUXValue {
    return FUXValue.value(value)
}

public func createOnComplete(_ tween: FUXTween, onComplete: @escaping () -> ()) -> FUXTween {
    return FUXTween.onComplete(Box(tween), onComplete)
}

public func fromToPoint(_ from: CGPoint, to: CGPoint, valueFunc: @escaping (CGPoint) -> ()) -> FUXValue {
    return FUXValue.value({ tweenValue in valueFunc(CGPoint(x: from.x + (to.x - from.x) * CGFloat(tweenValue), y: from.y + (to.y - from.y) * CGFloat(tweenValue))) })
}

public func fromToValueFunc(_ from: Float, to: Float, valueFunc: @escaping (Float) -> ()) -> FUXValue {
    return FUXValue.value({ tweenValue in valueFunc(from + (to - from) * tweenValue) })
}

public func viewFrameValue(_ view: UIView, to: CGRect) -> FUXValue {
    let from = view.frame
    let change = CGRect(x: to.origin.x - from.origin.x, y: to.origin.y - from.origin.y, width: to.size.width - from.size.width, height: to.size.height - from.size.height)
    return FUXValue.value({ tweenValue in
        let x = from.origin.x + change.origin.x * CGFloat(tweenValue)
        let y = from.origin.y + change.origin.y * CGFloat(tweenValue)
        let width = from.size.width + change.size.width * CGFloat(tweenValue)
        let height = from.size.height + change.size.height * CGFloat(tweenValue)
        view.frame = CGRect(x: x, y: y, width: width, height: height) })
}

public func constraintValue(_ view: UIView, constraint: NSLayoutConstraint, constant: CGFloat) -> FUXValue {
    let from = constraint.constant
    let change = constant - constraint.constant
    return FUXValue.value({ tweenValue in constraint.constant = from + change * CGFloat(tweenValue); view.layoutIfNeeded() })
}

public func viewSizeValue(_ view: UIView, to: CGSize) -> FUXValue {
    let from = view.frame
    let change = CGSize(width: to.width - from.width, height: to.height - from.height)
    return FUXValue.value({ tweenValue in
        view.frame.origin.x = from.origin.x
        view.frame.origin.y = from.origin.y
        view.frame.size.width = from.size.width + change.width * CGFloat(tweenValue)
        view.frame.size.height = from.size.height + change.height * CGFloat(tweenValue) })
}

public func viewPositionValue(_ view: UIView, to: CGPoint) -> FUXValue {
    let from = view.frame
    let change = CGPoint(x: to.x - from.origin.x, y: to.y - from.origin.y)
    return FUXValue.value({ tweenValue in
        view.frame.origin.x = from.origin.x + change.x * CGFloat(tweenValue)
        view.frame.origin.y = from.origin.y + change.y * CGFloat(tweenValue)
        view.frame.size.width = from.size.width
        view.frame.size.height = from.size.height })
}

public func viewScaleValue(_ view: UIView, from: CGFloat, to: CGFloat) -> FUXValue {
    let change = to - from
    return FUXValue.value({ tweenValue in
        let scale = from + change * CGFloat(tweenValue)
        view.transform = CGAffineTransform(scaleX: scale, y: scale)
    })
}

public func viewRotationValue(_ view: UIView, from: CGFloat, to: CGFloat) -> FUXValue {
    let change = to - from
    return FUXValue.value({ tweenValue in
        let rotation = from + change * CGFloat(tweenValue)
        view.transform = CGAffineTransform(rotationAngle: rotation)
    })
}

public func backgroundColor(_ view: UIView, to: UIColor) -> FUXValue {
    let from = view.backgroundColor!
    return FUXValue.value({ tweenValue in
        let fromColors = from.cgColor.components
        let toColors = to.cgColor.components

    })
}
