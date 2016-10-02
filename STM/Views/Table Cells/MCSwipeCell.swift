//
//  MCSwipeCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/7/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

enum MCSwipeTableViewCellDirection {
    case left
    case right
    case center
}

enum MCSwipeTableViewCellState {
    case none
    case state1
    case state2
    case state3
    case state4
}

enum MCSwipeTableViewCellMode {
    case none
    case exit
    case `switch`
}

typealias MCSwipeCompletionBlock = (_ cell: MCSwipeCell, _ state: MCSwipeTableViewCellState, _ mode: MCSwipeTableViewCellMode) -> Void

// swiftlint:disable variable_name
// swiftlint:disable type_body_length
// swiftlint:disable body_length
// swiftlint:disable line_length
class MCSwipeCell: KZTableViewCell {
    let _panGestureRecognizer = UIPanGestureRecognizer()
    var _contentScreenshotView: UIImageView?
    var _colorIndicatorView: UIView?
    var _slidingView: UIView?
    var _direction = MCSwipeTableViewCellDirection.center

    var _isExited = false
    var settings_damping = CGFloat(0.6)
    var settings_velocity = CGFloat(0.9)
    var settings_animationDuration = TimeInterval(0.4)
    var currentPercentage = CGFloat(0)

    let settings_firstTrigger = CGFloat(0.15)
    let settings_secondTrigger = CGFloat(0.47)

    var defaultColor = UIColor.white

    var _view1: UIView?
    var _view2: UIView?
    var _view3: UIView?
    var _view4: UIView?

    var _color1: UIColor?
    var _color2: UIColor?
    var _color3: UIColor?
    var _color4: UIColor?

    var _modeForState1 = MCSwipeTableViewCellMode.none
    var _modeForState2 = MCSwipeTableViewCellMode.none
    var _modeForState3 = MCSwipeTableViewCellMode.none
    var _modeForState4 = MCSwipeTableViewCellMode.none

    var completionBlock1: MCSwipeCompletionBlock?
    var completionBlock2: MCSwipeCompletionBlock?
    var completionBlock3: MCSwipeCompletionBlock?
    var completionBlock4: MCSwipeCompletionBlock?

    var _activeView: UIView?

    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        _panGestureRecognizer.addTarget(self, action: #selector(MCSwipeCell.handlePanGestureRecognizer(_:)))
        self.addGestureRecognizer(_panGestureRecognizer)
        _panGestureRecognizer.delegate = self
    }

    //MARK: Init

    //MARK: Prepare For Reuse

    override func prepareForReuse() {
        super.prepareForReuse()

        uninstallSwipingView()
        _isExited = false

        _view1 = nil
        _view2 = nil
        _view3 = nil
        _view4 = nil

        _color1 = nil
        _color2 = nil
        _color3 = nil
        _color4 = nil

        _modeForState1 = .none
        _modeForState2 = .none
        _modeForState3 = .none
        _modeForState4 = .none

        completionBlock1 = nil
        completionBlock2 = nil
        completionBlock3 = nil
        completionBlock4 = nil
    }

    //MARK: View Manipulation

    func setupSwipingView() {
        if _contentScreenshotView != nil {
            return
        }

        let contentViewScreenshotImage = imageWithView(self)

        let colorIndicatorView = UIView(frame: self.bounds)
        colorIndicatorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        colorIndicatorView.backgroundColor = defaultColor
        self.addSubview(colorIndicatorView)

        let slidingView = UIView()
        slidingView.contentMode = .center
        colorIndicatorView.addSubview(slidingView)

        let contentScreenshotView = UIImageView(image: contentViewScreenshotImage)
        self.addSubview(contentScreenshotView)

        _slidingView = slidingView
        _colorIndicatorView = colorIndicatorView
        _contentScreenshotView = contentScreenshotView
    }

    func uninstallSwipingView() {
        if let contentScreenshotView = _contentScreenshotView {
            if let slidingView = _slidingView {
                slidingView.removeFromSuperview()
                _slidingView = nil
            }

            if let colorIndicatorView = _colorIndicatorView {
                colorIndicatorView.removeFromSuperview()
                _colorIndicatorView = nil
            }

            contentScreenshotView.removeFromSuperview()
            _contentScreenshotView = nil
        }
    }

    func setViewOfSlidingView(_ slidingView: UIView) {
        if let parentSlidingView = _slidingView {
            parentSlidingView.subviews.forEach({ $0.removeFromSuperview() })
            parentSlidingView.addSubview(slidingView)
        }
    }

    //MARK: Swipe Config

    func setSwipeGestureWith(_ view: UIView, color: UIColor, mode: MCSwipeTableViewCellMode = .none, state: MCSwipeTableViewCellState = .state1, completionBlock: @escaping MCSwipeCompletionBlock) {
        if state == .state1 {
            completionBlock1 = completionBlock
            _color1 = color
            _view1 = view
            _modeForState1 = mode
        }

        if state == .state2 {
            completionBlock2 = completionBlock
            _color2 = color
            _view2 = view
            _modeForState2 = mode
        }

        if state == .state3 {
            completionBlock3 = completionBlock
            _color3 = color
            _view3 = view
            _modeForState3 = mode
        }

        if state == .state4 {
            completionBlock4 = completionBlock
            _color4 = color
            _view4 = view
            _modeForState4 = mode
        }
    }

    //MARK: Gestures

    func handlePanGestureRecognizer(_ gesture: UIPanGestureRecognizer) {
        if _isExited {
            return
        }

        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)
        let animationDuration = animationDurationWithVelocity(velocity)
        var percentage = CGFloat(0)
        if let contentScreenshotView = _contentScreenshotView {
            percentage = percentageWithOffset(contentScreenshotView.frame.minX, relativeToWidth: (self.bounds).width)
            _direction = directionWithPercentage(percentage)
        }

        //------------------ ----------------\\

        if gesture.state == .began || gesture.state == .changed {
            setupSwipingView()

            if let contentScreenshotView = _contentScreenshotView {
                if canTravelTo(percentage) {
                    contentScreenshotView.center = CGPoint(x: contentScreenshotView.center.x + translation.x, y: contentScreenshotView.center.y)
                    animateWithOffset(contentScreenshotView.frame.minX)
                    gesture.setTranslation(CGPoint.zero, in: self)
                }
            }
        } else if gesture.state == .ended || gesture.state == .cancelled {
            _activeView = self.viewWithPercentage(percentage)
            currentPercentage = percentage

            let state = stateWithPercentage(percentage)
            var mode = MCSwipeTableViewCellMode.none

            if state == .state1 {
                mode = _modeForState1
            } else if state == .state2 {
                mode = _modeForState2
            } else if state == .state2 {
                mode = _modeForState3
            } else if state == .state4 {
                mode = _modeForState4
            }

            if mode == .exit && _direction != .center {
                self.moveWithDuration(animationDuration, direction: _direction)
            } else {
                self.swipeToOriginWithCompletion({ () -> Void in
                    self.executeCompletionBlock()
                })
            }
        }
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gesture = gestureRecognizer as? UIPanGestureRecognizer {
            let point = gesture.velocity(in: self)

            if fabs(point.x) > fabs(point.y) {
                if point.x > 0 && _modeForState1 == .none && _modeForState2 == .none {
                    return false
                }

                return true
            }
        }

        return false
    }

    //MARK: Movement

    func animateWithOffset(_ offset: CGFloat) {
        let percentage = percentageWithOffset(offset, relativeToWidth: (self.bounds).width)

        if let view = viewWithPercentage(percentage) {
            setViewOfSlidingView(view)
            if let slidingView = _slidingView {
                slidingView.alpha = alphaWithPercentage(percentage)
            }
            slideViewWithPercentage(percentage, view: view, isDragging: true)
        }

        let color = colorWithPercentage(percentage)
        if let colorIndicatorView = _colorIndicatorView {
            colorIndicatorView.backgroundColor = color
        }
    }

    func slideViewWithPercentage(_ percentage: CGFloat, view: UIView?, isDragging: Bool) {
        guard let view = view else {
            return
        }

        var position = CGPoint.zero
        position.y = (self.bounds).height / 2.0

        if isDragging {
            if percentage >= 0 && percentage < settings_firstTrigger {
                position.x = offsetWithPercentage(settings_firstTrigger/2, relativeToWidth: (self.bounds).width)
            } else if percentage >= settings_firstTrigger {
                position.x = offsetWithPercentage(percentage - (settings_firstTrigger/2), relativeToWidth: (self.bounds).width)
            } else if percentage < 0 && percentage >= -settings_firstTrigger {
                position.x = (self.bounds).width - offsetWithPercentage(settings_firstTrigger/2, relativeToWidth: (self.bounds).width)
            } else if percentage < -settings_firstTrigger {
                position.x = (self.bounds).width + offsetWithPercentage(percentage + (settings_firstTrigger/2), relativeToWidth: (self.bounds).width)
            }
        } else {
            if _direction == .right {
                position.x = offsetWithPercentage(settings_firstTrigger/2, relativeToWidth: (self.bounds).width)
            } else if _direction == .left {
                position.x = (self.bounds).width - offsetWithPercentage(settings_firstTrigger/2, relativeToWidth: (self.bounds).width)
            } else {
                return
            }
        }

        let activeViewSize = view.bounds.size
        var activeViewFrame = CGRect(x: position.x - activeViewSize.width / 2.0, y: position.y - activeViewSize.height / 2.0, width: activeViewSize.width, height: activeViewSize.height)
        activeViewFrame = activeViewFrame.integral

        if let slidingView = _slidingView {
            slidingView.frame = activeViewFrame
        }
    }

    func moveWithDuration(_ duration: TimeInterval, direction: MCSwipeTableViewCellDirection) {
        _isExited = true

        var origin = CGFloat(0)
        if direction == .left {
            origin = -(self.bounds).width
        } else if direction == .right {
            origin = (self.bounds).width
        }

        guard let contentScreenshotView = _contentScreenshotView else {
            return
        }

        guard let slidingView = _slidingView else {
            return
        }

        let percentage = percentageWithOffset(origin, relativeToWidth: (self.bounds).width)
        var frame = contentScreenshotView.frame
        frame.origin.x = origin

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: { () -> Void in
            contentScreenshotView.frame = frame
            slidingView.alpha = 0
            self.slideViewWithPercentage(percentage, view: self._activeView, isDragging: true)
            }) { (finished) -> Void in
                self.executeCompletionBlock()
        }
    }

    func swipeToOriginWithCompletion(_ completion: (() -> Void)?) {
        UIView.animate(withDuration: settings_animationDuration, delay: 0.0, usingSpringWithDamping: settings_damping, initialSpringVelocity: settings_velocity, options: UIViewAnimationOptions(), animations: { () -> Void in
            if let contentScreenshotView = self._contentScreenshotView {
                contentScreenshotView.frame.origin.x = 0
            }
            if let colorIndicatorView = self._colorIndicatorView {
                colorIndicatorView.backgroundColor = self.defaultColor
            }

            if let slidingView = self._slidingView {
                slidingView.alpha = 0.0
            }

            self.slideViewWithPercentage(0, view: self._activeView, isDragging: false)
            }) { (finished) -> Void in
                self._isExited = false
                self.uninstallSwipingView()

                if let completion = completion {
                    completion()
                }
        }
    }

    func imageWithView(_ view: UIView) -> UIImage {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, scale)

        if let context = UIGraphicsGetCurrentContext() {
            view.layer.render(in: context)
            let image =  UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image!
        }

        return UIImage()
    }

    func canTravelTo(_ percentage: CGFloat) -> Bool {
        if _modeForState1 == .none && _modeForState2 == .none {
            if percentage > 0.0 {
                return false
            }
        }

        if _modeForState3 == .none && _modeForState4 == .none {
            if percentage < 0.0 {
                return false
            }
        }

        return true
    }

    //MARK: Percentage

    func offsetWithPercentage(_ percentage: CGFloat, relativeToWidth width: CGFloat) -> CGFloat {
        var offset = percentage * width
        if offset < -width {
            offset = -width
        } else if offset > width {
            offset = width
        }

        return offset
    }

    func percentageWithOffset(_ offset: CGFloat, relativeToWidth width: CGFloat) -> CGFloat {
        var percentage = offset/width
        if percentage < -1.0 {
            percentage = -1.0
        } else if percentage > 1.0 {
            percentage = 1.0
        }

        return percentage
    }

    func animationDurationWithVelocity(_ velocity: CGPoint) -> TimeInterval {
        let width = (self.bounds).width
        let animationDurationDiff = CGFloat(0.1 - 0.25)
        var horizontalVelocity = velocity.x

        if horizontalVelocity < -width {
            horizontalVelocity = -width
        } else if horizontalVelocity > width {
            horizontalVelocity = width
        }

        return (0.1 + 0.25) - TimeInterval(((horizontalVelocity / width) * animationDurationDiff))
    }

    func directionWithPercentage(_ percentage: CGFloat) -> MCSwipeTableViewCellDirection {
        if percentage < 0 {
            return .left
        } else if percentage > 0 {
            return .right
        }

        return .center
    }

    func viewWithPercentage(_ percentage: CGFloat) -> UIView? {
        var view: UIView?

        if percentage >= 0 && _modeForState1 != .none {
            view = _view1
        }

        if percentage >= settings_secondTrigger && _modeForState2 != .none {
            view = _view2
        }

        if percentage < 0 && _modeForState3 != .none {
            view = _view3
        }

        if percentage <= -settings_secondTrigger && _modeForState4 != .none {
            view = _view4
        }

        return view
    }

    func alphaWithPercentage(_ percentage: CGFloat) -> CGFloat {
        var alpha = CGFloat(1.0)

        if percentage >= 0 && percentage < settings_firstTrigger {
            alpha = percentage / settings_firstTrigger
        } else if percentage < 0 && percentage > -settings_firstTrigger {
            alpha = fabs(percentage / settings_firstTrigger)
        } else {
            alpha = 1.0
        }

        return alpha
    }

    func colorWithPercentage(_ percentage: CGFloat) -> UIColor {
        var color = defaultColor

        if percentage > settings_firstTrigger && _modeForState1 != .none {
            color = _color1 ?? color
        }

        if percentage > settings_secondTrigger && _modeForState2 != .none {
            color = _color2 ?? color
        }

        if percentage < -settings_firstTrigger && _modeForState3 != .none {
            color = _color3 ?? color
        }

        if percentage <= -settings_secondTrigger && _modeForState4 != .none {
            color = _color4 ?? color
        }

        return color
    }

    func stateWithPercentage(_ percentage: CGFloat) -> MCSwipeTableViewCellState {
        var state = MCSwipeTableViewCellState.none

        if percentage > settings_firstTrigger && _modeForState1 != .none {
            state = .state1
        }

        if percentage >= settings_secondTrigger && _modeForState2 != .none {
            state = .state2
        }

        if percentage <= -settings_firstTrigger && _modeForState3 != .none {
            state = .state3
        }

        if percentage <= -settings_secondTrigger && _modeForState4 != .none {
            state = .state4
        }

        return state
    }

    class func viewWithImageName(_ name: String) -> UIView {
        let image = UIImage(named: name)
        let imageView = UIImageView(image: image)
        imageView.contentMode = UIViewContentMode.center
        return imageView
    }

    func executeCompletionBlock() {
        let state = stateWithPercentage(currentPercentage)
        var mode = MCSwipeTableViewCellMode.none
        var completionBlock: MCSwipeCompletionBlock?

        switch state {
        case .state1:
            mode = _modeForState1
            completionBlock = completionBlock1
            break
        case .state2:
            mode = _modeForState2
            completionBlock = completionBlock2
            break
        case .state3:
            mode = _modeForState3
            completionBlock = completionBlock3
            break
        case .state4:
            mode = _modeForState4
            completionBlock = completionBlock4
            break

        default:
            break
        }

        if let completionBlock = completionBlock {
            completionBlock(self, state, mode)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
