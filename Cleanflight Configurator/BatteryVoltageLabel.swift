//
//  BatteryVoltageLabel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 09/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class BatteryVoltageLabel: BlinkingLabel {
    private var _defaultColor: UIColor?
    
    var displayUnit = true
    
    var voltage = 0.0 {
        didSet {
            if _defaultColor == nil {
                _defaultColor = self.textColor
            }
            let batteryStatus = BatteryLowAlarm().batteryStatus()
            switch batteryStatus {
            case .Good:
                blinks = false
                textColor = _defaultColor
                
            case .Warning:
                blinks = false
                textColor = UIColor.yellowColor()
                
            case .Critical:
                blinks = true
                textColor = UIColor.redColor()
            }

            self.text = String(format:"%.1f%@", locale: NSLocale.currentLocale(), self.voltage, displayUnit ? "V" : "")
        }
    }
}
