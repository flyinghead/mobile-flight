//
//  MSPDecoder.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 22/02/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

enum ParserState : Int { case Sync1 = 0, Sync2, Direction, Length, Code, Payload, Checksum };

public class MSPCodec {
    var errors: Int = 0
    var gcsMode = true
    
    private var state: ParserState = .Sync1
    private var directionOut: Bool = false
    private var unsupportedMSPCode = false
    private var expectedMsgLength: Int = 0
    private var checksum: UInt8 = 0
    private var messageBuffer: [UInt8]?
    private var code: UInt8 = 0

    func decode(b: UInt8) -> (success: Bool, code: MSP_code, message: [UInt8])? {
        var bbuf = b
        let bstr = b >= 32 && b < 128 ? NSString(bytes: &bbuf, length: 1, encoding: NSASCIIStringEncoding)! : NSString(format: "[%d]", b)
        //NSLog("%@", bstr)
        
        switch state {
        case .Sync1:
            if b == 36 { // $
                state = .Sync2
            } else {
                NSLog("MSP expected '$', got %@", bstr)
            }
        case .Sync2:
            if b == 77 { // M
                state = .Direction
            } else {
                NSLog("MSP expected 'M', got %@", bstr)
                state = .Sync1
            }
        case .Direction:
            if b == 62 { // >
                unsupportedMSPCode = false
                directionOut = false
                state = .Length
            } else if b == 60 {     // <
                unsupportedMSPCode = false
                directionOut = true
                state = .Length
            } else if b == 33 {     // !
                unsupportedMSPCode = true
                state = .Length
            } else {
                NSLog("MSP expected '>', got %@", bstr)
                state = .Sync1
            }
        case .Length:
            expectedMsgLength = Int(b);
            checksum = b;
            
            messageBuffer = [UInt8]()
            state = .Code
        case .Code:
            code = b
            checksum ^= b
            if expectedMsgLength > 0 {
                state = .Payload
            } else {
                state = .Checksum       // No payload
            }
        case .Payload:
            messageBuffer?.append(b);
            checksum ^= b
            if messageBuffer?.count >= expectedMsgLength {
                state = .Checksum
            }
        case .Checksum:
            state = .Sync1
            let mspCode = MSP_code(rawValue: Int(code)) ?? .MSP_UNKNOWN
            if checksum == b && mspCode != .MSP_UNKNOWN && directionOut != gcsMode && !unsupportedMSPCode {
                //NSLog("Received MSP %d", mspCode.rawValue)
                return (true, mspCode, messageBuffer!)
            } else {
                if unsupportedMSPCode {
                    return (false, mspCode, messageBuffer!)
                } else {
                    let datalog = NSData(bytes: messageBuffer!, length: expectedMsgLength)
                    if checksum != b {
                        NSLog("MSP code %d - checksum failed: %@", code, datalog)
                    } else if directionOut {
                        NSLog("MSP code %d - received outgoing message", code)
                    } else {
                        NSLog("Unknown MSP code %d: %@", code, datalog)
                    }
                    errors += 1
                    // 3DR radios often loose a byte. So we try to resync on the received data in case it contains the beginning of a subsequent message
                    if checksum != b && b == 36 {     // $
                        state = .Sync2
                    }
                }
            }
        }
    
        return nil
    }
    
    func encode(mspCode: MSP_code, message: [UInt8]?) -> [UInt8] {
        let dataSize = message?.count ?? 0
        //                      $    M   < or >
        var buffer: [UInt8] = [36 , 77, gcsMode ? 60 : 62, UInt8(dataSize), UInt8(mspCode.rawValue)]
        var checksum: UInt8 = UInt8(mspCode.rawValue) ^ buffer[3]
        
        if (message != nil) {
            buffer.appendContentsOf(message!)
            for b in message! {
                checksum ^= b
            }
        }
        buffer.append(checksum)

        return buffer
    }
}