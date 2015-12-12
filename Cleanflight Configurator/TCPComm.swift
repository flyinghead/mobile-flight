//
//  TCPComm.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation
import CoreFoundation

class TCPComm : NSObject, NSStreamDelegate, CommChannel {
    var host = "192.168.1.71"
    var port: Int = 5000
    private var inStream: NSInputStream!
    private var outStream: NSOutputStream!
    
    var msp: MSPParser
    
    init(msp: MSPParser) {
        self.msp = msp
        super.init()
        msp.commChannel = self
    }
    
    func connect() {
        NSLog("Connecting...")
        
        var readStream: Unmanaged<CFReadStream>?, writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, host, UInt32(port), &readStream, &writeStream)
        self.inStream = readStream!.takeRetainedValue()
        self.outStream = writeStream!.takeRetainedValue()
        
        self.inStream.delegate = self
        self.outStream.delegate = self
        
        self.inStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        self.outStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        self.inStream.open()
        self.outStream.open()
    }
    
    private func sendIfAvailable() {
        if (outStream == nil) {
            // Probably a comm error
            return
        }
        objc_sync_enter(msp)
        if (msp.outputQueue.count == 0) {
            objc_sync_exit(msp)
        } else {
            let len = outStream.write(msp.outputQueue, maxLength: msp.outputQueue.count);
            if (len > 0) {
                msp.outputQueue.removeFirst(len);
                objc_sync_exit(msp)
            } else {
                objc_sync_exit(msp)
                if (len < 0) {
                    NSLog("Communication error")
                }
                close();
            }
        }
    }
    
    func stream(stream: NSStream, handleEvent eventCode: NSStreamEvent) {
        if (eventCode == NSStreamEvent.HasBytesAvailable && stream == inStream) {
            var buffer = [UInt8](count: 4096, repeatedValue: 0)
            let len = inStream.read(&buffer, maxLength: buffer.count)
            if (len > 0) {
                msp.read(Array<UInt8>(buffer[0..<len]))
            }
            else if (len <= 0) {
                if (len < 0) {
                    NSLog("Communication error")
                }
                close();
            }
        }
        else if (eventCode == NSStreamEvent.HasSpaceAvailable && stream == outStream) {
            // FIXME Let assume all write can proceed ... sendIfAvailable()
        }
    }
    
    func close() {
        if (inStream != nil) {
            inStream.close();
            inStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            inStream.delegate = nil
            inStream = nil
        }
        if (outStream != nil) {
            outStream.close();
            outStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            outStream.delegate = nil
            outStream = nil
        }
        NSLog("Communication closed")
    }

    func flushOut() {
        sendIfAvailable()
    }
}