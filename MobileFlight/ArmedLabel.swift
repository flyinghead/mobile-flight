//
//  ArmedLabel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 09/02/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class ArmedLabel: BlinkingLabel {
    var armed = false {
        willSet(value) {
            if value != armed {
                if !value {
                    text = "DISARMED"
                    blinks = false
                    textColor = UIColor.greenColor()
                } else {
                    text = "ARMED"
                    blinks = true
                    textColor = UIColor.redColor()
                    NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(ArmedLabel.stopBlinking(_:)), userInfo: nil, repeats: false)
                }
            }
        }
    }
    
    func stopBlinking(timer: NSTimer) {
        blinks = false
        text = ""
    }
}
