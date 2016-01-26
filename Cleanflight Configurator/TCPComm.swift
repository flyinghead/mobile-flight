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

    private var outStream: NSOutputStream!
    
    var msp: MSPParser
    var connectCallback: ((success: Bool) -> ())?
    var _connected = false
    var networkLost = false
    var _reachability: SCNetworkReachability!
    var _reachabilityContext: SCNetworkReachabilityContext?
    var thread: NSThread!
    
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
        
        startReachabilityNotifier()
        
        thread = NSThread(target: self, selector: "threadRun", object: nil)
        thread.start()
    }
    
    // Entry point of the background thread on which streams are scheduled
    func threadRun() {
        var readStream: Unmanaged<CFReadStream>?, writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, host, UInt32(port), &readStream, &writeStream)

        let inStream = readStream!.takeRetainedValue() as NSInputStream
        let outStream = writeStream!.takeRetainedValue() as NSOutputStream
        self.outStream = outStream
        
        inStream.delegate = self
        outStream.delegate = self
        
        inStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        outStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        
        inStream.open()
        outStream.open()
        
        while true {
            NSRunLoop.currentRunLoop().runUntilDate(NSDate().dateByAddingTimeInterval(0.5))
            if NSThread.currentThread().cancelled {
                break
            }
        }
        
        inStream.close();
        outStream.close();
        inStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        outStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        inStream.delegate = nil
        outStream.delegate = nil
        NSLog("Communication closed")

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
        if _reachabilityContext != nil {
            return
        }
        
        // Start NetworkReachability notifications
        _reachabilityContext = SCNetworkReachabilityContext(version: 0, info: UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque()), retain: nil, release: nil, copyDescription: nil)
        SCNetworkReachabilitySetCallback(reachability, { (_, flags, info) in

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
        }, &(_reachabilityContext!))
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
            }
        }
    }
    
    func stream(stream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch eventCode {
        case NSStreamEvent.None:
            NSLog("NSStreamEvent.None")
            _connected = false
            dispatch_async(dispatch_get_main_queue(), {
                self.connectCallback?(success: false)
                self.connectCallback = nil
            })
            
        case NSStreamEvent.OpenCompleted:
            NSLog("NSStreamEvent.OpenCompleted")
            _connected = true
            dispatch_async(dispatch_get_main_queue(), {
                self.connectCallback?(success: true)
                self.connectCallback = nil
            })
            
        case NSStreamEvent.HasBytesAvailable:
            var buffer = [UInt8](count: 4096, repeatedValue: 0)
            let len = (stream as! NSInputStream).read(&buffer, maxLength: buffer.count)
            if (len > 0) {
                msp.read(Array<UInt8>(buffer[0..<len]))
            }
            else if (len <= 0) {
                if (len < 0) {
                    NSLog("Communication error")
                }
            }
        
        case NSStreamEvent.HasSpaceAvailable:
            // FIXME Let's assume that all writes complete in sendIfAvailable()
            break
            
        case NSStreamEvent.ErrorOccurred,
             NSStreamEvent.EndEncountered:
            if stream is NSOutputStream {
                NSLog("NSStreamEvent.ErrorOccurred: %@", stream)
                closeStreams()
                if connectCallback != nil {
                    // Connection failed
                    dispatch_async(dispatch_get_main_queue(), {
                        self.connectCallback?(success: false)
                        self.connectCallback = nil
                    })
                }
                else {
                    // Connection was lost. Try to reconnect.
                    dispatch_async(dispatch_get_main_queue(), {
                        VoiceMessage.theVoice.checkAlarm(CommunicationLostAlarm())
                        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userCancelledReconnection:", name: SVProgressHUDDidTouchDownInsideNotification, object: nil)
                        SVProgressHUD.showWithStatus("Connection lost. Reconnecting...", maskType: .Black)
                    })
                    if !networkLost {
                        connect({ success in
                            if success {
                                NSNotificationCenter.defaultCenter().removeObserver(self, name: SVProgressHUDDidTouchDownInsideNotification, object: nil)
                                SVProgressHUD.dismiss()
                            }
                        })
                    }
                }
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
            _reachabilityContext = nil
        }
    }
    
    private func closeStreams() {
        _connected = false
        self.outStream = nil
        thread.cancel()
    }

    func flushOut() {
        sendIfAvailable()
    }
    
    var connected: Bool { return _connected }
}