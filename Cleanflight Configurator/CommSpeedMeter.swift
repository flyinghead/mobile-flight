//
//  CommSpeedMeter.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 08/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class CommSpeedMeter {
    static let instance = CommSpeedMeter()
    
    private var receiveStats = [(date: NSDate, size: Int)]()
    
    func received(nbytes: Int) {
        if _isDebugAssertConfiguration() {
            objc_sync_enter(self)
            receiveStats.insert((NSDate(), nbytes), atIndex: 0)
            while receiveStats.count > 500 {
                receiveStats.removeLast()
            }
            objc_sync_exit(self)
        }
    }
    
    var bytesPerSecond: Int {
        var byteCount = 0
        objc_sync_enter(self)
        for (date, size) in receiveStats {
            if -date.timeIntervalSinceNow >= 1 {
                break
            }
            byteCount += size
        }
        objc_sync_exit(self)
        
        return byteCount
    }
}