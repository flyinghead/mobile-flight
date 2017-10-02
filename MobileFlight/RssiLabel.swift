//
//  RssiLabel.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 09/02/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
