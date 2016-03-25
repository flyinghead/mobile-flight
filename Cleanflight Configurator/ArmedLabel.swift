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
                blinks = false
                if !value {
                    text = "DISARMED"
                    textColor = UIColor.greenColor()
                } else {
                    text = ""
                }
            }
        }
    }
    
    func armingNow() {
        text = "ARMED"
        blinks = true
        textColor = UIColor.redColor()
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "stopBlinking:", userInfo: nil, repeats: false)
    }
    
    func stopBlinking(timer: NSTimer) {
        blinks = false
        text = ""
    }
}
