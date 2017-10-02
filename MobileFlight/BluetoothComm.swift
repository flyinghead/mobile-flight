//
//  BluetoothComm.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 09/12/15.
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

import UIKit
import SVProgressHUD

class BluetoothComm : NSObject, CommChannel, BluetoothDelegate {
    private let btManager : BluetoothManager
    private var peripheral: BluetoothPeripheral
    private let msp: MSPParser
    private let btQueue: dispatch_queue_t
    
    private var _closed = false
    private var _connected = true
    
    init(withBluetoothManager btManager: BluetoothManager, andPeripheral peripheral: BluetoothPeripheral, andMSP msp: MSPParser) {
        self.btManager = btManager
        self.peripheral = peripheral
        self.msp = msp
        self.btQueue = btManager.btQueue
        super.init()
        msp.openCommChannel(self)
    }
    
    func flushOut() {
        dispatch_async(btQueue, {
            var packedData = [UInt8]()
            

            while true {
                let data = self.msp.nextOutputMessage()

                if data != nil {
                    packedData.appendContentsOf(data!)
                }
                if packedData.count >= 20 || (data == nil && !packedData.isEmpty) {
                    var remainingData: ArraySlice<UInt8>?
                    if packedData.count > 20 {
                        remainingData = packedData.suffix(packedData.count - 20)
                        packedData = [UInt8](packedData[0..<20])
                    }

                    self.btManager.writeData(self.peripheral, data: packedData)
                    if remainingData != nil {
                        packedData = [UInt8](remainingData!)
                    } else {
                        packedData.removeAll()
                    }
                }
                if data == nil && packedData.isEmpty {
                    break
                }
            }
        })
    }
    
    func close() {
        _connected = false
        _closed = true
        btManager.disconnect(peripheral)
    }
    
    // MARK: BluetoothDelegate
    func foundPeripheral(peripheral: BluetoothPeripheral) {
    }
    
    func stoppedScanning() {
    }
    
    func connectedPeripheral(peripheral: BluetoothPeripheral) {
        self.peripheral = peripheral
        _connected = true
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: SVProgressHUDDidTouchDownInsideNotification, object: nil)
            SVProgressHUD.dismiss()
        })
    }
    func failedToConnectToPeripheral(peripheral: BluetoothPeripheral, error: NSError?) {
        // Same process
        disconnectedPeripheral(peripheral)
    }
    
    func disconnectedPeripheral(peripheral: BluetoothPeripheral) {
        if !_closed {
            _connected = false
            dispatch_async(dispatch_get_main_queue(), {
                VoiceMessage.theVoice.checkAlarm(CommunicationLostAlarm())
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BluetoothComm.userCancelledReconnection(_:)), name: SVProgressHUDDidTouchDownInsideNotification, object: nil)
                SVProgressHUD.showWithStatus("Connection lost. Reconnecting...", maskType: .Black)
            })
            btManager.connect(peripheral)
        }
    }
    
    func userCancelledReconnection(notification: NSNotification) {
        msp.closeCommChannel()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: SVProgressHUDDidTouchDownInsideNotification, object: nil)
        SVProgressHUD.dismiss()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func receivedData(peripheral: BluetoothPeripheral, data: [UInt8]) {
        msp.read(data)
    }
    
    var connected: Bool { return _connected }
    
    func readRssi() {
        btManager.readRssi(peripheral)
    }
}
