//
//  BatteryVoltageLabel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 09/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class BatteryVoltageLabel: BlinkingLabel {
    var voltage = 0.0 {
        didSet {
            let batteryStatus = BatteryLowAlarm().batteryStatus()
            switch batteryStatus {
            case .Good:
                blinks = false
                textColor = UIColor.blackColor()
                
            case .Warning:
                blinks = false
                textColor = UIColor.orangeColor()
                
            case .Critical:
                blinks = true
                textColor = UIColor.redColor()
            }

            self.text = String(format:"%.1fV", locale: NSLocale.currentLocale(), self.voltage)
        }
    }
}
