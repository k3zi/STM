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
                self.status = .offline
                timer?.fire()
            }
        }
    }

    var status = STMStreamStatus.offline {
        didSet {
            if !shallow {
                switch status {
                case .offline:
                    self.backgroundColor = RGB(200)
                case .online:
                    self.backgroundColor = RGB(74, g: 237, b: 93)
                case .recentlyOnline:
                    self.backgroundColor = RGB(237, g: 181, b: 74)
                }
            }
        }
    }

    var timer: Timer?

    init(stream: STMStream? = nil) {
        self.stream = stream
        super.init(frame: CGRect.zero)

        self.autoSetDimensions(to: CGSize(width: 10, height: 10))
        self.layer.cornerRadius = 10.0/2.0
        self.clipsToBounds = true

        timer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(self.updateStatus), userInfo: nil, repeats: true)
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
            guard let response = response, let success = response["success"] as? Bool else {
                self.status = .offline
                return
            }

            guard success else {
                self.status = .offline
                return
            }

            guard let result = response["result"], let innerResult = result as? JSON else {
                self.status = .offline
                return
            }

            guard let online = innerResult["online"] as? Int else {
                self.status = .offline
                return
            }

            self.status = STMStreamStatus(rawValue: online) ?? .offline
        }
    }

    deinit {
        if let timer = timer {
            timer.invalidate()
        }
    }

}
