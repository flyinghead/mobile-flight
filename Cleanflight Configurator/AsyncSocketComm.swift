//
//  AsyncSocketComm.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 21/06/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import SystemConfiguration
import Foundation
import CocoaAsyncSocket
import SVProgressHUD

class AsyncSocketComm : NSObject, CommChannel, GCDAsyncSocketDelegate {
    private let host: String
    private let port: Int
    private var msp: MSPParser
    private var socket: GCDAsyncSocket!
    private var connectCallback: ((success: Bool) -> ())?
    private var _connected = false
    private var _reachability: SCNetworkReachability!
    private var shuttingDown = false
    private var writingTag = 0
    private var writtenTag = 0
    private lazy var dispatchQueue: dispatch_queue_t = dispatch_queue_create("com.mobile-flight.socket-delegate", DISPATCH_QUEUE_SERIAL)
    
    init(msp: MSPParser, host: String, port: Int?) {
        self.msp = msp
        self.host = host
        self.port = port ?? 23
        super.init()
        msp.openCommChannel(self)
    }
    
    func connect(callback: ((success: Bool) -> ())?) {
        if _connected {
            return
        }
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatchQueue)
        shuttingDown = false
        connectCallback = callback
        do {
            try socket.connectToHost(host, onPort: UInt16(port), withTimeout: 5)
        } catch {
            callback?(success: false)
            connectCallback = nil
        }
    }
    
    func flushOut() {
        if writingTag - writtenTag > 1 {
            return
        }
        doWrite()
    }
    
    private func doWrite() {
        if !_connected {
            return
        }
        guard let msg = msp.nextOutputMessage() else {
            return
        }
        let nsdata = NSData(bytes: msg, length: msg.count)
        writingTag += 1
        socket.writeData(nsdata, withTimeout: -1, tag: writingTag)
    }
    
    func close() {
        shuttingDown = true
        socket.disconnect()
        socket.delegate = nil
        socket = nil
    }
    
    var connected: Bool {
        return _connected
    }

    @objc private func userCancelledReconnection(notification: NSNotification) {
        shuttingDown = true
        msp.closeCommChannel()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: SVProgressHUDDidTouchDownInsideNotification, object: nil)
        SVProgressHUD.dismiss()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @objc private func tryToReconnect() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if !connected && msp.communicationEstablished && appDelegate.active {
            connect({ success in
                if success {
                    NSNotificationCenter.defaultCenter().removeObserver(self, name: SVProgressHUDDidTouchDownInsideNotification, object: nil)
                    SVProgressHUD.dismiss()
                }
                else {
                    NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector:#selector(AsyncSocketComm.tryToReconnect), userInfo: nil, repeats: false)
                }
            })
        }
    }

    // MARK: GCDAsyncSocketDelegate
    
    func socket(sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        _connected = true
        dispatch_async(dispatch_get_main_queue()) {
            self.connectCallback?(success: true)
            self.connectCallback = nil
        }
        sock.readDataWithTimeout(-1, tag: 0)
    }
    
    
    func socketDidDisconnect(sock: GCDAsyncSocket, withError err: NSError?) {
        _connected = false
        if connectCallback != nil {
            dispatch_async(dispatch_get_main_queue()) {
                self.connectCallback?(success: false)
                self.connectCallback = nil
            }
        }
        else if !shuttingDown {
            dispatch_async(dispatch_get_main_queue()) {
                VoiceMessage.theVoice.checkAlarm(CommunicationLostAlarm())
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AsyncSocketComm.userCancelledReconnection(_:)), name: SVProgressHUDDidTouchDownInsideNotification, object: nil)
                if !SVProgressHUD.isVisible() {
                    SVProgressHUD.showWithStatus("Connection lost. Reconnecting...", maskType: .Black)
                }
            }
            tryToReconnect()

        }
    }
    
    func socket(sock: GCDAsyncSocket, didReadData data: NSData, withTag tag: Int) {
        var array = [UInt8](count: data.length, repeatedValue: 0)
        data.getBytes(&array, length:data.length)
        msp.read(array)
        sock.readDataWithTimeout(-1, tag: 0)
    }
    
    func socket(sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        self.writtenTag = tag
        doWrite()
    }
    
    // MARK:
    
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
    
}
