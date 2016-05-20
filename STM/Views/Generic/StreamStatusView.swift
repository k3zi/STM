//
//  StreamStatusView.swift
//  STM
//
//  Created by Kesi Maduka on 4/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

class StreamStatusView: UIView {

    var shallow = false

    var stream: STMStream? {
        didSet {
            if !shallow {
                self.status = .Offline
                timer?.fire()
            }
        }
    }

    var status = STMStreamStatus.Offline {
        didSet {
            if !shallow {
                switch status {
                case .Offline:
                    self.backgroundColor = RGB(200)
                case .Online:
                    self.backgroundColor = RGB(74, g: 237, b: 93)
                case .RecentlyOnline:
                    self.backgroundColor = RGB(237, g: 181, b: 74)
                }
            }
        }
    }

    var timer: NSTimer?

    init(stream: STMStream? = nil) {
        self.stream = stream
        super.init(frame: CGRect.zero)

        self.autoSetDimensionsToSize(CGSize(width: 10, height: 10))
        self.layer.cornerRadius = 10.0/2.0
        self.clipsToBounds = true

        timer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: #selector(self.updateStatus), userInfo: nil, repeats: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateStatus() {
        guard let stream = stream else {
            return
        }

        guard !shallow else {
            return
        }

        Constants.Network.GET("/stream/\(stream.id)/isOnline", parameters: nil) { (response, error) in
            guard let response = response, success = response["success"] as? Bool else {
                self.status = .Offline
                return
            }

            guard success else {
                self.status = .Offline
                return
            }

            guard let result = response["result"], innerResult = result as? JSON else {
                self.status = .Offline
                return
            }

            guard let online = innerResult["online"] as? Int else {
                self.status = .Offline
                return
            }

            self.status = STMStreamStatus(rawValue: online) ?? .Offline
        }
    }

    deinit {
        if let timer = timer {
            timer.invalidate()
        }
    }

}
