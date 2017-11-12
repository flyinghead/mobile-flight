//
//  MSPDecoder.swift
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

enum ParserState : Int { case sync1 = 0, sync2, direction, length, code, payload, checksum };

open class MSPCodec {
    var errors: Int = 0
    var gcsMode = true
    
    fileprivate var state: ParserState = .sync1
    fileprivate var directionOut: Bool = false
    fileprivate var unsupportedMSPCode = false
    fileprivate var expectedMsgLength: Int = 0
    fileprivate var checksum: UInt8 = 0
    fileprivate var messageBuffer: [UInt8]?
    fileprivate var code: UInt8 = 0
    fileprivate var jumboFrameSizeBytes = 0

    func decode(_ b: UInt8) -> (success: Bool, code: MSP_code, message: [UInt8])? {
        var bbuf = b
        let bstr = b >= 32 && b < 128 ? NSString(bytes: &bbuf, length: 1, encoding: String.Encoding.ascii.rawValue)! : NSString(format: "[%d]", b)
        //NSLog("%@", bstr)
        
        switch state {
        case .sync1:
            if b == 36 { // $
                state = .sync2
            } else {
                NSLog("MSP expected '$', got %@", bstr)
            }
        case .sync2:
            if b == 77 { // M
                state = .direction
            } else {
                NSLog("MSP expected 'M', got %@", bstr)
                state = .sync1
            }
        case .direction:
            if b == 62 { // >
                unsupportedMSPCode = false
                directionOut = false
                state = .length
            } else if b == 60 {     // <
                unsupportedMSPCode = false
                directionOut = true
                state = .length
            } else if b == 33 {     // !
                unsupportedMSPCode = true
                state = .length
            } else {
                NSLog("MSP expected '>', got %@", bstr)
                state = .sync1
            }
        case .length:
            expectedMsgLength = Int(b);
            if expectedMsgLength == 255 {
                jumboFrameSizeBytes = 2
                expectedMsgLength = 0
            } else {
                jumboFrameSizeBytes = 0
            }
            checksum = b;
            
            messageBuffer = [UInt8]()
            state = .code
        case .code:
            code = b
            checksum ^= b
            if expectedMsgLength > 0 || jumboFrameSizeBytes > 0 {
                state = .payload
            } else {
                state = .checksum       // No payload
            }
        case .payload:
            if jumboFrameSizeBytes > 0 {
                jumboFrameSizeBytes -= 1
                expectedMsgLength += Int(b) << (jumboFrameSizeBytes == 0 ? 8 : 0)
            } else {
                messageBuffer?.append(b);
                if messageBuffer != nil && messageBuffer!.count >= expectedMsgLength {
                    state = .checksum
                }
            }
            checksum ^= b
        case .checksum:
            state = .sync1
            let mspCode = MSP_code(rawValue: Int(code)) ?? .msp_UNKNOWN
            if checksum == b && mspCode != .msp_UNKNOWN && directionOut != gcsMode && !unsupportedMSPCode {
                //NSLog("Received MSP %d", mspCode.rawValue)
                return (true, mspCode, messageBuffer!)
            } else {
                if unsupportedMSPCode {
                    return (false, mspCode, messageBuffer!)
                } else {
                    let datalog = Data(bytes: UnsafePointer<UInt8>(messageBuffer!), count: expectedMsgLength)
                    if checksum != b {
                        NSLog("MSP code %d - checksum failed: %@", code, String(data: datalog, encoding: String.Encoding.utf8) ?? "?")
                    } else if directionOut {
                        NSLog("MSP code %d - received outgoing message", code)
                    } else {
                        NSLog("Unknown MSP code %d: %@", code, String(data: datalog, encoding: String.Encoding.utf8) ?? "?")
                    }
                    errors += 1
                    // 3DR radios often loose a byte. So we try to resync on the received data in case it contains the beginning of a subsequent message
                    if checksum != b && b == 36 {     // $
                        state = .sync2
                    }
                }
            }
        }
    
        return nil
    }
    
    func encode(_ mspCode: MSP_code, message: [UInt8]?) -> [UInt8] {
        let dataSize = message?.count ?? 0
        //                      $    M   < or >
        var buffer: [UInt8] = [36 , 77, gcsMode ? 60 : 62, UInt8(dataSize), UInt8(mspCode.rawValue)]
        var checksum: UInt8 = UInt8(mspCode.rawValue) ^ buffer[3]
        
        if (message != nil) {
            buffer.append(contentsOf: message!)
            for b in message! {
                checksum ^= b
            }
        }
        buffer.append(checksum)

        return buffer
    }
}
