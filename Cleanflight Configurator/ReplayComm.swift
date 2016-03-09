//
//  ReplayComm.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 25/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation
import SVProgressHUD

class ReplayComm : NSObject, CommChannel {
    let datalog: NSFileHandle
    let datalogStart: NSDate

    var protocolHandler: ProtocolHandler?
    var closed = false
    var array: [UInt8]?
    
    var connected: Bool { return !closed }
    
    init(datalog: NSFileHandle, protocolHandler: ProtocolHandler) {
        self.datalog = datalog
        self.protocolHandler = protocolHandler
        self.datalogStart = NSDate()
        super.init()
        protocolHandler.openCommChannel(self)
        read()
    }
    
    func flushOut() {
        if let msp = protocolHandler as? MSPParser {
            let array = [UInt8]()
            for code in msp.retriedMessages.keys {
                msp.callSuccessCallback(code, data: array)
            }
        }
    }
    
    func close() {
        datalog.closeFile()
        closed = true
    }
    
    private func closeAndDismissViewController() {
        protocolHandler!.closeCommChannel()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func read() {
        if closed {
            return
        }
        var data = datalog.readDataOfLength(6)
        if data.length < 6 {
            closeAndDismissViewController()
            return
        }
        var array = [UInt8](count: 6, repeatedValue: 0)
        data.getBytes(&array, length:array.count)
        let timestamp = readUInt32(array, index: 0)
        let size = readUInt16(array, index: 4)
        
        data = datalog.readDataOfLength(size)
        if data.length < size {
            closeAndDismissViewController()
            return
        }
        self.array = [UInt8](count: size, repeatedValue: 0)
        data.getBytes(&self.array!, length:size)
        
        let delay = Double(timestamp)/1000 + datalogStart.timeIntervalSinceNow
        
        if delay <= 0 {
            dispatch_async(dispatch_get_main_queue(), {
                self.processData(nil)
            })
            return
        }
        _ = NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: "processData:", userInfo: nil, repeats: false)
    }
    
    func processData(timer: NSTimer?) {
        protocolHandler!.read(array!)
        
        read()
    }

}