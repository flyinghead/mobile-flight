//
//  ArmedTimer.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 22/05/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class ArmedTimer: BlinkingLabel {
    private var armTimer: NSTimer?
    
    func appear() {
        if armTimer == nil {
            armTimerDidFire()
            armTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(armTimerDidFire), userInfo: nil, repeats: true)
        }
    }
    
    func disappear() {
        armTimer?.invalidate()
        armTimer = nil
    }
    
    @objc
    private func armTimerDidFire() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let armedTime = Int(round(appDelegate.totalArmedTime))
        self.text = String(format: "%02d:%02d", armedTime / 60, armedTime % 60)
    }
}
