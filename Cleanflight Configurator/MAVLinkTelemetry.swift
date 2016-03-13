//
//  MAVLinkTelemetry.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 12/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MAVLinkTelemetry: UIViewController, UseMAVLinkVehicle {
    @IBOutlet weak var flightModeLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!

    var messageTimer: NSTimer?
    
    override func viewWillAppear(animated: Bool) {
        self.messageLabel.text = nil
        
        mavlinkVehicle.flightMode.addObserver(self) {
            self.flightModeLabel.text = $0.modeName()
        }
        
        mavlinkVehicle.autopilotMessage.addListener(self) { (severity: MAV_SEVERITY, message: String) in
            self.messageLabel.text = message
            if severity.rawValue <= MAV_SEVERITY_ERROR.rawValue {
                self.messageLabel.textColor = UIColor.redColor()
            } else if severity == MAV_SEVERITY_WARNING {
                self.messageLabel.textColor = UIColor.yellowColor()
            } else {
                self.messageLabel.textColor = UIColor.whiteColor()
            }
            self.messageTimer?.invalidate()
            self.messageTimer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: "messageTimerDidFire:", userInfo: nil, repeats: false)
        }
    }
    
    @objc
    private func messageTimerDidFire(timer: NSTimer) {
        messageLabel.text = nil
    }
    
    override func viewWillDisappear(animated: Bool) {
        mavlinkVehicle.flightMode.removeObserver(self)
        mavlinkVehicle.autopilotMessage.removeListener(self)
        messageTimer?.invalidate()
        messageTimer = nil
    }
}
