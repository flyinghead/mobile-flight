//
//  BlinkingLabel.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 24/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
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

@IBDesignable
class BlinkingLabel: UILabel {
    @IBInspectable
    var blinks: Bool = false {
        didSet {
            if !blinks && timer != nil {
                timer!.invalidate()
                timer = nil
                self.alpha = savedAlpha
            } else if blinks && timer == nil && self.superview != nil {
                createTimer()
            }
        }
    }
    @IBInspectable
    var blinkingPeriod: Double = 0.5 {
        didSet {
            if timer != nil && blinks {
                timer!.invalidate()
                let savedAlpha = self.savedAlpha
                createTimer()
                self.savedAlpha = savedAlpha
            }
        }
    }
    
    fileprivate var timer: Timer?
    fileprivate var savedAlpha: CGFloat = 1.0
    
    fileprivate func createTimer() {
        savedAlpha = self.alpha
        timer = Timer.scheduledTimer(timeInterval: blinkingPeriod, target: self, selector: #selector(BlinkingLabel.timerDidFire), userInfo: nil, repeats: true)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if blinks {
            if self.superview == nil {
                self.alpha = savedAlpha
                timer?.invalidate()
                timer = nil
            } else {
                createTimer()
            }
        }
    }
    
    func timerDidFire() {
        self.alpha = self.alpha == 0 ? savedAlpha : 0.0
    }
}
