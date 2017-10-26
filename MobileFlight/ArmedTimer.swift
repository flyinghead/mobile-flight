//
//  ArmedTimer.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 22/05/16.
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

class ArmedTimer: BlinkingLabel {
    fileprivate var armTimer: Timer?
    
    func appear() {
        if armTimer == nil {
            armTimerDidFire()
            armTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(armTimerDidFire), userInfo: nil, repeats: true)
        }
    }
    
    func disappear() {
        armTimer?.invalidate()
        armTimer = nil
    }
    
    @objc
    fileprivate func armTimerDidFire() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let armedTime = Int(round(appDelegate.totalArmedTime))
        self.text = String(format: "%02d:%02d", armedTime / 60, armedTime % 60)
    }
}
