//
//  BatteryVoltageLabel.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 09/01/16.
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

class BatteryVoltageLabel: BlinkingLabel {
    fileprivate var _defaultColor: UIColor?
    
    var displayUnit = true
    
    var voltage = 0.0 {
        didSet {
            if _defaultColor == nil {
                _defaultColor = self.textColor
            }
            let batteryStatus = BatteryLowAlarm().batteryStatus()
            switch batteryStatus {
            case .good:
                blinks = false
                textColor = _defaultColor
                
            case .warning:
                blinks = false
                textColor = UIColor.yellow
                
            case .critical:
                blinks = true
                textColor = UIColor.red
            }

            self.text = String(format:"%@%@", formatNumber(self.voltage, precision: 1), displayUnit ? " V" : "")
        }
    }
}
