//
//  FUXEngine.swift
//  FUX
//
//  Created by Garrit Schaap on 03.02.15.
//  Copyright (c) 2015 Garrit UG (haftungsbeschränkt). All rights reserved.
//

import UIKit
import QuartzCore

precedencegroup FUXAdditivePrecedence {
    associativity: left
}

infix operator +: FUXAdditivePrecedence
public func + (left: FUXEngine, right: FUXTween) -> FUXTween {
    return left.addTween(right)
}

class FUXTweenStorage {
    let tween: FUXTween
    var totalRunningTime: Float = 0
    var currentTime: Float = 0
    var currentRelativeTime: Float = 0
    var currentTweenValue: Float = 0
    var speed: Float = 1
    var isFinished = false
    var repeatCount: Int = 0
    var repeatTotal: Int = 0
    var yoyo = false
    var speedSet = false
    var name = ""

    init(_ value: FUXTween, _ name: String) {
        self.tween = value
        self.name = name
    }
}

open class FUXEngine: NSObject {

    fileprivate var _displayLink: CADisplayLink!
    fileprivate var _tweens = [FUXTweenStorage]()
    fileprivate var _isRunning = false

    override public init () {
        super.init()
    }

    open func addTween(_ tween: FUXTween, name: String = "") -> FUXTween {
        let storedTween = FUXTweenStorage(tween, name)
        _tweens.append(storedTween)

        if _tweens.count > 0 && !_isRunning {
            setupDisplayLink()
        }
        return tween
    }

    open func removeTweenByName(_ name: String) {
        var index = 0
        for tween in _tweens {
            if tween.name == name {
                _tweens.remove(at: index)
                break
            }
            index += 1
        }
        if _tweens.count == 0 && _isRunning {
            stopDisplayLink()
        }
    }

    open func pause() {
        stopDisplayLink()
    }

    open func resume() {
        setupDisplayLink()
    }

    fileprivate func setupDisplayLink() {
        _displayLink = CADisplayLink(target: self, selector: #selector(FUXEngine.update(_:)))
        _displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        _isRunning = true
    }

    fileprivate func stopDisplayLink() {
        _displayLink.invalidate()
        _isRunning = false
    }

    @objc func update(_ displayLink: CADisplayLink) {

        var index = 0
        for storedTween in _tweens {
            if !storedTween.isFinished {
                storedTween.totalRunningTime += Float(displayLink.duration) * Float(displayLink.frameInterval) * fabsf(storedTween.speed)
                storedTween.currentTweenValue = storedTween.currentRelativeTime
                parseTween(storedTween.tween, storedTween)
                index += 1
            } else {
                _tweens.remove(at: index)
            }
        }

        if _tweens.count == 0 && _isRunning {
            stopDisplayLink()
        }
    }

    fileprivate func parseTween(_ tween: FUXTween, _ storedTween: FUXTweenStorage) {

        switch tween {
            case .tween(let duration, let value):
                parseValue(value, storedTween.currentTweenValue)
                var runFinished = false
                if storedTween.currentRelativeTime == 1 && storedTween.speed > 0 {
                    runFinished = true
                    if storedTween.repeatTotal > 0 {
                        storedTween.repeatCount += 1
                    }
                } else if storedTween.currentRelativeTime == 0 && storedTween.speed < 0 {
                    runFinished = true
                }

                storedTween.currentTime += Float(_displayLink.duration) * Float(_displayLink.frameInterval) * storedTween.speed
                let time = fmaxf(0, storedTween.currentTime) / duration
                let checkedTime = fminf(1, fmaxf(0, time))
                storedTween.currentRelativeTime = checkedTime

                if runFinished {
                    if !storedTween.yoyo {
                        if storedTween.repeatCount == storedTween.repeatTotal {
                            storedTween.isFinished = true
                        } else {
                            storedTween.totalRunningTime = 0
                            storedTween.currentRelativeTime = 0
                            storedTween.currentTime = 0
                        }
                    } else {
                        if storedTween.currentRelativeTime == 1 {
                            storedTween.speed *= -1
                            storedTween.currentRelativeTime = 1
                            storedTween.currentTime = duration
                        } else {
                            if storedTween.repeatCount == storedTween.repeatTotal {
                                storedTween.isFinished = true
                            }
                            storedTween.totalRunningTime = 0
                            storedTween.speed *= -1
                            storedTween.currentRelativeTime = 0
                            storedTween.currentTime = 0
                        }
                    }
                }
        case .easing(let boxedTween, let easing):
            storedTween.currentTweenValue = easing(storedTween.currentTweenValue)
            parseTween(boxedTween.unbox, storedTween)
        case .delay(let delay, let boxedTween):
            if storedTween.totalRunningTime > delay {
                parseTween(boxedTween.unbox, storedTween)
            }
        case .onComplete(let boxedTween, let onComplete):
            if storedTween.currentRelativeTime == 1 {
                onComplete()
            }
            parseTween(boxedTween.unbox, storedTween)
        case .repeat(let repeatTotal, let boxedTween):
            storedTween.repeatTotal = repeatTotal
            parseTween(boxedTween.unbox, storedTween)
        case .yoYo(let boxedTween):
            storedTween.yoyo = true
            parseTween(boxedTween.unbox, storedTween)
        case .speed(let speed, let boxedTween):
            if !storedTween.speedSet {
                storedTween.speedSet = true
                storedTween.speed = speed
            }
            parseTween(boxedTween.unbox, storedTween)
        default:
            print("FUX Tween Engine")
        }
    }

    fileprivate func parseValue(_ value: FUXValue, _ tweenValue: Float) {

        switch value {
            case .value(let valueFunc):
                valueFunc(tweenValue)
            case .values(let values):
                for boxedValue in values {
                    parseValue(boxedValue.unbox, tweenValue)
                }
        }
    }

}
