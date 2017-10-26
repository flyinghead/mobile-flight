//
//  AsyncSocketComm.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 21/06/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
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

import SystemConfiguration
import Foundation
import CocoaAsyncSocket
import SVProgressHUD

class AsyncSocketComm : NSObject, CommChannel, GCDAsyncSocketDelegate {
    fileprivate let host: String
    fileprivate let port: Int
    fileprivate var msp: MSPParser
    fileprivate var socket: GCDAsyncSocket!
    fileprivate var connectCallback: ((_ success: Bool) -> ())?
    fileprivate var _connected = false
    fileprivate var _reachability: SCNetworkReachability!
    fileprivate var shuttingDown = false
    fileprivate var writingTag = 0
    fileprivate var writtenTag = 0
    fileprivate lazy var dispatchQueue: DispatchQueue = DispatchQueue(label: "com.mobile-flight.socket-delegate", attributes: [])
    
    init(msp: MSPParser, host: String, port: Int?) {
        self.msp = msp
        self.host = host
        self.port = port ?? 23
        super.init()
    }
    
    func connect(_ callback: ((_ success: Bool) -> ())?) {
        if _connected {
            return
        }
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatchQueue)
        shuttingDown = false
        connectCallback = callback
        do {
            try socket.connect(toHost: host, onPort: UInt16(port), withTimeout: 5)
        } catch {
            callback?(false)
            connectCallback = nil
        }
    }
    
    func flushOut() {
        if writingTag - writtenTag > 1 {
            return
        }
        doWrite()
    }
    
    fileprivate func doWrite() {
        if !_connected {
            return
        }
        guard let msg = msp.nextOutputMessage() else {
            return
        }
        let nsdata = Data(bytes: UnsafePointer<UInt8>(msg), count: msg.count)
        writingTag += 1
        socket.write(nsdata, withTimeout: -1, tag: writingTag)
    }
    
    func close() {
        shuttingDown = true
        socket?.disconnect()
        socket?.delegate = nil
        socket = nil
    }
    
    var connected: Bool {
        return _connected
    }

    @objc fileprivate func userCancelledReconnection(_ notification: Notification) {
        shuttingDown = true
        msp.closeCommChannel()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.SVProgressHUDDidTouchDownInside, object: nil)
        SVProgressHUD.dismiss()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func tryToReconnect() {
        if !connected && msp.communicationEstablished {
            connect({ success in
                if success {
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.SVProgressHUDDidTouchDownInside, object: nil)
                    SVProgressHUD.dismiss()
                }
                else {
                    Timer.scheduledTimer(timeInterval: 1, target:self, selector:#selector(AsyncSocketComm.tryToReconnect), userInfo: nil, repeats: false)
                }
            })
        }
    }

    // MARK: GCDAsyncSocketDelegate
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        _connected = true
        msp.openCommChannel(self)
        DispatchQueue.main.async {
            self.connectCallback?(true)
            self.connectCallback = nil
        }
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        NSLog("Socket did disconnect")
        _connected = false
        if connectCallback != nil {
            DispatchQueue.main.async {
                self.connectCallback?(false)
                self.connectCallback = nil
            }
        }
        else if !shuttingDown {
            DispatchQueue.main.async {
                VoiceMessage.theVoice.checkAlarm(CommunicationLostAlarm())
                NotificationCenter.default.addObserver(self, selector: #selector(AsyncSocketComm.userCancelledReconnection(_:)), name: NSNotification.Name.SVProgressHUDDidTouchDownInside, object: nil)
                if !SVProgressHUD.isVisible() {
                    SVProgressHUD.show(withStatus: "Connection lost. Reconnecting...", maskType: .black)
                }
            }
            tryToReconnect()

        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        var array = [UInt8](repeating: 0, count: data.count)
        (data as NSData).getBytes(&array, length:data.count)
        msp.read(array)
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        self.writtenTag = tag
        doWrite()
    }
    
    // MARK:
    
    fileprivate var reachability: SCNetworkReachability {
        if _reachability == nil {
            _reachability = SCNetworkReachabilityCreateWithName(nil, host)!
        }
        return _reachability
    }
    
    var reachable: Bool {
        if host == "localhost" || host == "127.0.0.1" {
            return true
        }
        
        var flags : SCNetworkReachabilityFlags = []
        SCNetworkReachabilityGetFlags(reachability, &flags)
        return flags.contains(.isDirect)
    }
    
}
