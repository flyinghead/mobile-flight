//
//  CleanflightSimulator.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 22/02/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
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
import CocoaAsyncSocket
import XCTest
@testable import MobileFlight

class CleanflightSimulator : NSObject, StreamDelegate, GCDAsyncSocketDelegate {
    static let instance = CleanflightSimulator()
    
    let port: UInt16 = 8777
    
    fileprivate var mode: UInt32 = 0        // Flight modes
    var voltage = 0.0
    var amps = 0.0
    var mAh = 0
    var rssi = 0
    var roll = 0.0
    var pitch = 0.0
    var heading = 0
    var altitude = 0.0
    var variometer = 0.0
    var numSats = 0
    var speed = 0.0
    var distanceToHome = 0
    
    fileprivate var boxnames: [Mode] = [ .ANGLE, .ARM, .GTUNE, .BARO, .BEEPER, .BLACKBOX, .CALIB, .CAMSTAB, .CAMTRIG, .FAILSAFE, .GOVERNOR, .GPS_HOLD, .GPS_HOME, .GTUNE, .HEADADJ, .HEADFREE, .HORIZON, .LEDLOW, .LEDMAX, .LLIGHTS, .MAG, .OSD_SW, .PASSTHRU, .SERVO1, .SERVO2, .SERVO3, .SONAR, .TELEMETRY, .AIR ]
    
    fileprivate var socket: GCDAsyncSocket!
    fileprivate lazy var dispatchQueue: DispatchQueue = DispatchQueue(label: "com.mobile-flight.testsim-socket-delegate", attributes: [])
    fileprivate var connectedSockets = [GCDAsyncSocket]()
    
    fileprivate var codec = MSPCodec()
    
    func start() -> Bool {
        codec.gcsMode = false
        
        socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatchQueue)
        
        do {
            try socket.accept(onPort: port)
        } catch let error {
            NSLog("GCDAsyncSocket.accept failed: " + error.localizedDescription)
            return false
        }
        
        return true
    }
    
    func stop() {
        socket.delegate = nil
        socket.disconnect()
        socket = nil
        resetValues()
    }
    
    func resetValues() {
        mode = 0
        voltage = 0.0
        amps = 0
        mAh = 0
        rssi = 0
        roll = 0.0
        pitch = 0.0
        heading = 0
        altitude = 0.0
        variometer = 0.0
        numSats = 0
        speed = 0.0
        distanceToHome = 0
    }
    
    fileprivate func receiveData(_ data: [UInt8], fromSocket sock: GCDAsyncSocket) {
        for b in data {
            if let (status, mspCode, message) = codec.decode(b) {
                if status {
                    operation(mspCode, message: message, fromSocket: sock)
                }
            }
        }
    }
    
    fileprivate func short(_ v: Int) -> NSNumber {
        return NSNumber(value: Int16(v) as Int16)
    }
    
    fileprivate func byte(_ v: Int) -> NSNumber {
        return NSNumber(value: Int8(v) as Int8)
    }
    
    fileprivate func uint(_ v: Int) -> NSNumber {
        return NSNumber(value: UInt32(v) as UInt32)
    }
    
    fileprivate func int(_ v: Int) -> NSNumber {
        return NSNumber(value: Int32(v) as Int32)
    }
    
    fileprivate func operation(_ mspCode: MSP_code, message: [UInt8], fromSocket sock: GCDAsyncSocket) {
        NSLog("CleanflightSimulator: operation %d", mspCode.rawValue)
        switch mspCode {
        case .msp_FC_VARIANT:
            send(to: sock, mspCode: mspCode, "CLFL")
        case .msp_API_VERSION:
            send(to: sock, mspCode: mspCode, byte(0), byte(1), byte(16))
        case .msp_ATTITUDE:
            send(to: sock, mspCode: mspCode, short(Int(roll * 10)), short(Int(pitch * 10)), short(heading))
        case .msp_ALTITUDE:
            send(to: sock, mspCode: mspCode, int(Int(altitude * 100)), short(Int(variometer * 100)))
        case .msp_UID:
            send(to: sock, mspCode: mspCode, uint(0xBAADF00D), uint(0xBAADF00D), uint(0xBAADF00D))
        case .msp_BOXNAMES:
            var boxnamesString = ""
            for name in boxnames {
                boxnamesString += name.rawValue + ";"
            }
            send(to: sock, mspCode: mspCode, boxnamesString);
        case .msp_STATUS, .msp_STATUS_EX:
            send(to: sock, mspCode: mspCode, short(3500), short(0), short(0x7FFF), uint(Int(bitPattern: UInt(mode))), byte(0))
        case .msp_ANALOG:
            send(to: sock, mspCode: mspCode, byte(Int(voltage * 10.0)), short(mAh), short(rssi), short(Int(amps * 100)))
        case .msp_RAW_GPS:
            send(to: sock, mspCode: mspCode, byte(1), byte(numSats), int(0), int(0), short(0), short(Int(speed * 100000 / 3600)), short(heading * 10))
        case .msp_COMP_GPS:
            send(to: sock, mspCode: mspCode, short(distanceToHome), short(0), byte(1))
        case .msp_VOLTAGE_METER_CONFIG:
            send(to: sock, mspCode: mspCode, byte(110), byte(33), byte(43), byte(36))
        case .msp_CURRENT_METER_CONFIG:
            send(to: sock, mspCode: mspCode, short(1), short(0), byte(1), short(1500))
        default:
            NSLog("CleanflightSimulator: Unhandled operation %d", mspCode.rawValue)
        }
    }
    
    fileprivate func send(to: GCDAsyncSocket, mspCode: MSP_code, _ args: Any...) {
        var message = [UInt8]()
        for n in args {
            if n is NSNumber {
                switch CFNumberGetType(n as! CFNumber) {
                case .sInt8Type:
                    message.append((n as! NSNumber).uint8Value);
                case .sInt16Type:
                    message.append(contentsOf: writeInt16((n as! NSNumber).intValue))
                    break
                case .sInt32Type, .sInt64Type:
                    message.append(contentsOf: writeInt32((n as! NSNumber).intValue))
                    break
                default:
                    XCTFail("Unsupported MSP message number argument type")
                }
            } else if n is String {
                message.append(contentsOf: (n as! String).utf8)
            } else {
                XCTFail("Unsupported MSP message argument type")
            }
        }
        let data = codec.encode(mspCode, message: message)

        to.write(Data(bytes: data), withTimeout: -1, tag: 0)
    }
    
    func setMode(_ mode: Mode) {
        if let index = boxnames.index(of: mode) {
            self.mode = self.mode | UInt32(1 << index)
        } else {
            XCTFail("Unknown mode")
        }
    }
    func unsetMode(_ mode: Mode) {
        if let index = boxnames.index(of: mode) {
            self.mode = self.mode & ~UInt32(1 << index)
        } else {
            XCTFail("Unknown mode")
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        NSLog("New socket accepted")
        connectedSockets.append(newSocket)
        newSocket.readData(withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        NSLog("didRead: " + data.debugDescription)
        let array = [UInt8](data)
        receiveData(array, fromSocket: sock)
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        if let i = connectedSockets.index(of: sock) {
            connectedSockets.remove(at: i)
        }
    }
}
