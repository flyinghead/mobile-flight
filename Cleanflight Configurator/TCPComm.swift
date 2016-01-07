//
//  TCPComm.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation
import CoreFoundation
import SVProgressHUD
import SystemConfiguration

class TCPComm : NSObject, NSStreamDelegate, CommChannel {
    let host: String
    let port: Int
    private var inStream: NSInputStream!
    private var outStream: NSOutputStream!
    
    var msp: MSPParser
    var connectCallback: ((success: Bool) -> ())?
    var _connected = false
    var networkLost = false
    var _reachability: SCNetworkReachability!
    
    init(msp: MSPParser, host: String, port: Int?) {
        self.msp = msp
        self.host = host
        self.port = port ?? 23
        super.init()
        msp.openCommChannel(self)
    }
    
    func connect(callback: ((success: Bool) -> ())?) {
        NSLog("Connecting...")
        connectCallback = callback
        
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
        
        startReachabilityNotifier()
    }
    
    private var reachability: SCNetworkReachability {
        if _reachability == nil {
            _reachability = SCNetworkReachabilityCreateWithName(nil, host)!
        }
        return _reachability
    }
    
    var reachable: Bool {
        var flags : SCNetworkReachabilityFlags = []
        SCNetworkReachabilityGetFlags(reachability, &flags)
        return flags.contains(.IsDirect)
    }
    
    private func startReachabilityNotifier() {
        // Start NetworkReachability notifications
        var context = SCNetworkReachabilityContext(version: 0, info: UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque()), retain: nil, release: nil, copyDescription: nil)
        SCNetworkReachabilitySetCallback(reachability, { (_, flags, info) in
            //let isDirect = (flags.rawValue & UInt32(kSCNetworkFlagsIsDirect)) != 0
            let isDirect = flags.contains(.IsDirect)
            let myself = Unmanaged<TCPComm>.fromOpaque(COpaquePointer(info)).takeUnretainedValue()
            let hadLostNetwork = myself.networkLost
            myself.networkLost = !isDirect
            
            if myself.networkLost {
                NSLog("Network lost")
            } else {
                NSLog("Network restored")
            }
            if hadLostNetwork && !myself.networkLost && !myself._connected {
                myself.connect({ success in
                    if success {
                        NSNotificationCenter.defaultCenter().removeObserver(myself, name: SVProgressHUDDidTouchDownInsideNotification, object: nil)
                        SVProgressHUD.dismiss()
                    }
                })
            }
        }, &context)
        SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes)
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
                //close();
            }
        }
    }
    
    func stream(stream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch eventCode {
        case NSStreamEvent.None:
            _connected = false
            connectCallback?(success: false)
            connectCallback = nil
            
        case NSStreamEvent.OpenCompleted:
            _connected = true
            connectCallback?(success: true)
            connectCallback = nil
            
        case NSStreamEvent.HasBytesAvailable:
            if stream == inStream {
                var buffer = [UInt8](count: 4096, repeatedValue: 0)
                let len = inStream.read(&buffer, maxLength: buffer.count)
                if (len > 0) {
                    msp.read(Array<UInt8>(buffer[0..<len]))
                }
                else if (len <= 0) {
                    if (len < 0) {
                        NSLog("Communication error")
                    }
                    //close()
                }
            }
            
        case NSStreamEvent.HasSpaceAvailable:
            if stream == outStream {
                // FIXME Let assume all write can proceed ... sendIfAvailable()
            }
            
        case NSStreamEvent.ErrorOccurred,
             NSStreamEvent.EndEncountered:
            NSLog("NSStreamEvent.ErrorOccurred")
            _connected = false
            VoiceMessage.theVoice.checkAlarm(CommunicationLostAlarm())
            if !SVProgressHUD.isVisible() {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "userCancelledReconnection:", name: SVProgressHUDDidTouchDownInsideNotification, object: nil)
                SVProgressHUD.showWithStatus("Connection lost. Reconnecting...", maskType: .Black)
            }
            closeStreams()
            if !networkLost {
                connect({ success in
                    if success {
                        NSNotificationCenter.defaultCenter().removeObserver(self, name: SVProgressHUDDidTouchDownInsideNotification, object: nil)
                        SVProgressHUD.dismiss()
                    }
                })
            }
            
        default:
            break
        }
    }
    
    func userCancelledReconnection(notification: NSNotification) {
        msp.closeCommChannel()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: SVProgressHUDDidTouchDownInsideNotification, object: nil)
        SVProgressHUD.dismiss()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    func close() {
        closeStreams()
        if _reachability != nil {
            SCNetworkReachabilityUnscheduleFromRunLoop(_reachability!, CFRunLoopGetMain(), kCFRunLoopCommonModes)
            _reachability = nil
        }
    }
    
    private func closeStreams() {
        _connected = false
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
    
    var connected: Bool { return _connected }
}