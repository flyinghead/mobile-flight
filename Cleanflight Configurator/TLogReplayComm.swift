//
//  TLogReplayComm.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 22/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class TLogReplayComm : ReplayComm {
    var timeOffset: Double?
    
    override func read() {
        if closed {
            return
        }
        var data = datalog.readDataOfLength(14)
        if data.length < 14 {
            closeAndDismissViewController()
            return
        }
        var buffer = [UInt8](count: 14, repeatedValue: 0)
        data.getBytes(&buffer, length:14)

        let timestamp = TLogReplayComm.getTimestamp(buffer)
        let size = Int(buffer[9]) + 2
        
        data = datalog.readDataOfLength(size)
        if data.length < size {
            closeAndDismissViewController()
            return
        }
        self.array = [UInt8](buffer.suffix(6))
        
        buffer = [UInt8](count: size, repeatedValue: 0)
        data.getBytes(&buffer, length:size)
        self.array! += buffer
        
        if timeOffset == nil {
            timeOffset =  Double(timestamp)/1000000 + datalogStart.timeIntervalSinceNow
        }
        
        let delay = -timeOffset! + Double(timestamp)/1000000 + datalogStart.timeIntervalSinceNow
        
        if delay <= 0 {
            dispatch_async(dispatch_get_main_queue(), {
                self.processData(nil)
            })
            return
        }
        _ = NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: "processData:", userInfo: nil, repeats: false)
    }
    
    class func getTimestamp(data: [UInt8]) -> UInt64 {
        return fromByteArray(data.prefix(sizeof(UInt64)).reverse(), UInt64.self)
/*        var timestamp = UInt64(data[offset]) << 56 + UInt64(data[offset + 1]) << 48
        timestamp += UInt64(data[offset + 2]) << 40 + UInt64(data[offset + 3]) << 32
        timestamp += UInt64(data[offset + 4]) << 24 + UInt64(data[offset + 5]) << 16
        timestamp += UInt64(data[offset + 6]) << 8 + UInt64(data[offset + 7])
        return timestamp
*/
    }
}