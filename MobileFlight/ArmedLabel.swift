//
//  ArmedLabel.swift
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
