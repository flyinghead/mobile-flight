//
//  RssiLabel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 09/02/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class RssiLabel: BlinkingLabel {
    private var _defaultColor: UIColor?

    var rssi = 0 {
        didSet {
            if _defaultColor == nil {
                _defaultColor = self.textColor
            }
            if sikRssi == 0 {
                setRssiValue(rssi)
            }
        }
    }
    var sikRssi = 0 {
        didSet {
            if _defaultColor == nil {
                _defaultColor = self.textColor
            }
            if rssi == 0 {
                setRssiValue(sikRssi)
            }
        }
    }
    
    private func setRssiValue(value: Int) {
        if value <= userDefaultAsInt(.RSSIAlarmCritical) {
            blinks = true
            textColor = UIColor.redColor()
        } else if value <= userDefaultAsInt(.RSSIAlarmLow) {
            blinks = false
            textColor = UIColor.yellowColor()
        } else {
            blinks = false
            textColor = _defaultColor
        }
        
        self.text = String(format:"%d%%", value)
    }
}
