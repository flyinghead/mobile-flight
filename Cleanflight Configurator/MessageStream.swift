//
//  MessageStream.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 30/04/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class MessageStream {
    private var bytes: [UInt8]
    private var index = 0
    
    init(bytes: [UInt8]) {
        self.bytes = bytes
    }
    
    var count: Int {
        return bytes.count - index
    }
    
    func byteAvailable() -> Bool {
        return index < bytes.count - 1
    }
    
    func readByte() -> Int {
        let byte = bytes[index]
        index += 1
        return Int(byte)
    }
    
    func shortAvailable() -> Bool {
        return index < bytes.count - 2
    }
    
    func readShort() -> Int {
        let i = readInt16(bytes, index: index)
        index += 2
        return i
    }
    
    func readUShort() -> Int {
        let i = readUInt16(bytes, index: index)
        index += 2
        return i
    }
    
    func intAvailable() -> Bool {
        return index < bytes.count - 4
    }
    
    func readInt() -> Int {
        let i = readInt32(bytes, index: index)
        index += 4
        return i
    }
    
    func readUInt() -> Int {
        let i = readUInt32(bytes, index: index)
        index += 4
        return i
    }
}
