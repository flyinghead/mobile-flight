//
//  BlinkingLabel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 24/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class BlinkingLabel: UILabel {
    var blinks = false {
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
    var blinkingPeriod = 0.5 {
        didSet {
            if timer != nil && blinks {
                timer!.invalidate()
                let savedAlpha = self.savedAlpha
                createTimer()
                self.savedAlpha = savedAlpha
            }
        }
    }
    
    private var timer: NSTimer?
    private var savedAlpha: CGFloat = 1.0
    
    private func createTimer() {
        savedAlpha = self.alpha
        timer = NSTimer.scheduledTimerWithTimeInterval(blinkingPeriod, target: self, selector: "timerDidFire", userInfo: nil, repeats: true)
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
