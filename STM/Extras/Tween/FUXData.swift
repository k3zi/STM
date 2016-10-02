//
//  FUXData.swift
//  FUX
//
//  Created by Garrit Schaap on 03.02.15.
//  Copyright (c) 2015 Garrit UG (haftungsbeschränkt). All rights reserved.
//

import Foundation

open class Box<T> {
    let unbox: T
    public init(_ value: T) { self.unbox = value }
}

public enum FUXTween {
    case tween(Float, FUXValue)
    case easing(Box<FUXTween>, (Float) -> Float)
    case delay(Float, Box<FUXTween>)
    case speed(Float, Box<FUXTween>)
    case reverse(Box<FUXTween>)
    case yoYo(Box<FUXTween>)
    case `repeat`(Int, Box<FUXTween>)
    //case After(Box<FUXTween>, Box<FUXTween>)
    case onComplete(Box<FUXTween>, () -> ())
    //case OnStart(Box<FUXTween>, () -> ())
    //case OnUpdate(Box<FUXTween>, (Float, Float) -> ())
}

public enum FUXValue {
    case value((Float) -> ())
    case values([ Box<FUXValue> ])
}
