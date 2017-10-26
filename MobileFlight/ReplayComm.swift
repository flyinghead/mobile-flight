//
//  ReplayComm.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 25/12/15.
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

import Foundation
import SVProgressHUD
import Firebase

class ReplayComm : NSObject, CommChannel {
    let datalog: FileHandle
    let msp: MSPParser
    let datalogStart: Date

    var closed = false
    var array: [UInt8]?
    
    var connected: Bool { return !closed }
    
    init(datalog: FileHandle, msp: MSPParser) {
        self.datalog = datalog
        self.msp = msp
        self.datalogStart = Date()
        super.init()
        Analytics.logEvent("replay_started", parameters: nil)
        msp.openCommChannel(self)
        read()
    }
    
    func flushOut() {
        let array = [UInt8]()
        for code in msp.retriedMessages.keys {
            msp.callSuccessCallback(code, data: array)
        }
    }
    
    func close() {
        datalog.closeFile()
        closed = true
    }
    
    fileprivate func closeAndDismissViewController() {
        msp.closeCommChannel()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    func read() {
        if closed {
            return
        }
        var data = datalog.readData(ofLength: 6)
        if data.count < 6 {
            closeAndDismissViewController()
            return
        }
        var array = [UInt8](repeating: 0, count: 6)
        (data as NSData).getBytes(&array, length:array.count)
        let timestamp = readUInt32(array, index: 0)
        let size = readUInt16(array, index: 4)
        
        data = datalog.readData(ofLength: size)
        if data.count < size {
            closeAndDismissViewController()
            return
        }
        self.array = [UInt8](repeating: 0, count: size)
        (data as NSData).getBytes(&self.array!, length:size)
        
        let delay = Double(timestamp)/1000 + datalogStart.timeIntervalSinceNow
        
        if delay <= 0 {
            DispatchQueue.main.async(execute: {
                self.processData(nil)
            })
            return
        }
        _ = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(ReplayComm.processData(_:)), userInfo: nil, repeats: false)
    }
    
    func processData(_ timer: Timer?) {
        msp.read(array!)
        
        read()
    }

}
