//
//  FUXEasingCombinators.swift
//  FUX
//
//  Created by Garrit Schaap on 06.02.15.
//  Copyright (c) 2015 Garrit UG (haftungsbeschränkt). All rights reserved.
//

import UIKit

public func easeInCubic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in time * time * time }
}

public func easeOutCubic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        let t = time - 1.0
        return t * t * t + 1
    }
}

public func easeInOutCubic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        var t = time * 2
        if t < 1 {
            return 0.5 * t * t * t
        }
        t -= 2
        return 0.5 * (t * t * t + 2)
    }
}

public func easeInCircular(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in -(sqrtf(1 - time * time) - 1) }
}

public func easeOutCircular(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        let t = time - 1.0
        return sqrtf(1 - t * t)
    }
}

public func easeInOutCircular(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        var t = time * 2
        if t < 1 {
            return -0.5 * (sqrtf(1 - t * t) - 1)
        }
        t -= 2
        return 0.5 * (sqrtf(1 - t * t) + 1)
    }
}

public func easeInSine(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in 1 - cosf(time * Float(M_PI_2)) }
}

public func easeOutSine(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in sinf(time * Float(M_PI_2)) }
}

public func easeInOutSine(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in -0.5 * (cosf(Float(M_PI) * time) - 1) }
}

public func easeInQuadratic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in time * time }
}

public func easeOutQuadratic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in -time * (time - 2) }
}

public func easeInOutQuadratic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        var t = time * 2
        if t < 1 {
            return 0.5 * t * t
        }

        t = t - 1

        return -0.5 * (t * (t - 2) - 1)
    }
}

public func easeInQuartic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in time * time * time * time }
}

public func easeOutQuartic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        let t = time - 1
        return -(t * t * t * t - 1)
    }
}

public func easeInOutQuartic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        var t = time * 2
        if t < 1 {
            return 0.5 * t * t * t * t
        }
        t = t - 2
        return -0.5 * (t * t * t * t - 2)
    }
}

public func easeInQuintic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in time * time * time * time * time }
}

public func easeOutQuintic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        let t = time - 1
        return -(t * t * t * t * t - 1)
    }
}

public func easeInOutQuintic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        var t = time * 2
        if t < 1 {
            return 0.5 * t * t * t * t * t
        }
        t -= 2
        return -0.5 * (t * t * t * t * t - 2)
    }
}

public func easeInExpo(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in time == 0 ? 0 : powf(2, 10 * (time - 1)) }
}

public func easeOutExpo(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in time == 1 ? 1 : -powf(2, -10 * time) + 1 }
}

public func easeInOutExpo(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        if time == 0 {
            return 0
        } else if time == 1 {
            return 1
        }
        var t = time * 2
        if t < 1 {
            return 0.5 * powf(2, 10 * (t - 1))
        } else {
            t = t - 1
            return 0.5 * (-powf(2, -10 * t) + 2)
        }
    }
}

let easeBackSValue: Float = 1.70158

public func easeInBack(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in time * time * ((easeBackSValue + 1) * time - easeBackSValue) }
}

public func easeOutBack(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        let t = time - 1
        return t * t * ((easeBackSValue + 1) * t + easeBackSValue) + 1
    }
}

public func easeInOutBack(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        var t = time * 2
        let s = easeBackSValue * 1.525
        if t < 1 {
            return 0.5 * (t * t * ((s + 1) * t - s))
        }
        t -= 2
        return 0.5 * (t * t * ((s + 1) * t + s) + 2)
    }
}

public func easeInBounce(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        var t = 1 - time
        if t < 1.0 / 2.75 {
            return 1 - 7.5625 * t * t
        } else if t < 2.0 / 2.75 {
            t -= (1.5 / 2.75)
            return 1 - Float(7.5625 * t * t + 0.75)
        } else if t < 2.5 / 2.75 {
            t -= (2.25 / 2.75)
            return 1 - Float(7.5625 * t * t + 0.9375)
        } else {
            t -= (2.625 / 2.75)
            return 1 - Float(7.5625 * t * t + 0.984375)
        }
    }
}

public func easeOutBounce(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        var t = time
        if t < 1.0 / 2.75 {
            return 7.5625 * t * t
        } else if t < 2.0 / 2.75 {
            t -= (1.5 / 2.75)
            return Float(7.5625 * t * t + 0.75)
        } else if t < 2.5 / 2.75 {
            t -= (2.25 / 2.75)
            return Float(7.5625 * t * t + 0.9375)
        } else {
            t -= (2.625 / 2.75)
            return Float(7.5625 * t * t + 0.984375)
        }
    }
}

public func easeInOutBounce(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        let t = time * 2
        if t < 1 {
            return (1 - easeOutBounceWithTime(1 - t, duration: 1)) * 0.5
        } else {
            return easeOutBounceWithTime(t - 1, duration: 1) * 0.5 + 0.5
        }
    }
}

func easeOutBounceWithTime(_ time: Float, duration: Float) -> Float {
    var t = time / duration
    if t < 1.0 / 2.75 {
        return 7.5625 * t * t
    } else if t < 2.0 / 2.75 {
        t -= (1.5 / 2.75)
        return Float(7.5625 * t * t + 0.75)
    } else if t < 2.5 / 2.75 {
        t -= (2.25 / 2.75)
        return Float(7.5625 * t * t + 0.9375)
    } else {
        t -= (2.625 / 2.75)
        return Float(7.5625 * t * t + 0.984375)
    }
}

var easeElasticPValue: Float = 0.3
var easeElasticSValue: Float = 0.3 / 4
var easeElasticAValue: Float = 1

public func setEaseElasticPValue(_ value: Float) {
    easeElasticPValue = value
    if easeElasticAValue < 1 {
        easeElasticSValue = easeElasticPValue / 4
    } else {
        easeElasticSValue = easeElasticPValue / (Float(M_PI) * 2) * asinf(1 / easeElasticAValue)
    }
}

public func setEaseElasticAValue(_ value: Float) {
    if easeElasticAValue >= 1 {
        easeElasticAValue = value
        easeElasticSValue = easeElasticPValue / (Float(M_PI) * 2) * asinf(1 / easeElasticAValue)
    }
}

public func easeInElastic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        if time == 0 {
            return 0
        } else if time == 1 {
            return 1
        }
        let t = time - 1
        return -(powf(2, 10 * t) * sinf((t - easeElasticSValue) * (Float(M_PI) * 2) / easeElasticPValue))
    }
}

public func easeOutElastic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        if time == 0 {
            return 0
        } else if time == 1 {
            return 1
        }
        return powf(2, (-10 * time)) * sinf((time - easeElasticSValue) * (Float(M_PI) * 2) / easeElasticPValue) + 1
    }
}

public func easeInOutElastic(_ tween: FUXTween) -> FUXTween {
    return FUXTween.easing(Box(tween)) { time in
        if time == 0 {
            return 0
        } else if time == 1 {
            return 1
        }
        var t = time * 2
        if t < 1 {
            t -= 1
            return -0.5 * (powf(2, 10 * t) * sinf((t - easeElasticSValue) * (Float(M_PI) * 2) / easeElasticPValue))
        }
        t -= 1
        return powf(2, -10 * t) * sinf((t - easeElasticSValue) * (Float(M_PI) * 2) / easeElasticPValue) * 0.5 + 1
    }
}
