//
//  Utilities.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 15/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

func readUInt16(array: [UInt8], index: Int) -> Int {
    return Int(array[index]) + Int(array[index+1]) * 256;
}

func readInt16(array: [UInt8], index: Int) -> Int {
    return Int(array[index]) + Int(Int8(bitPattern: array[index+1])) * 256;
}

func readUInt32(array: [UInt8], index: Int) -> UInt32 {
    var res = UInt32(array[index+3])
    res = res * 256 + UInt32(array[index+2])
    res = res * 256 + UInt32(array[index+1])
    res = res * 256 + UInt32(array[index])
    return res
}

func readInt32(array: [UInt8], index: Int) -> Int {
    var res = Int(Int8(bitPattern: array[index+3]))
    res = res * 256 + Int(array[index+2])
    res = res * 256 + Int(array[index+1])
    res = res * 256 + Int(array[index])
    return res
}

func writeUInt32(i: UInt32) -> [UInt8] {
    return [UInt8(i % 256), UInt8((i >> 8) % 256), UInt8((i >> 16) % 256), UInt8(i >> 24)]
}

func writeInt32(i: Int) -> [UInt8] {
    return writeUInt32(UInt32(bitPattern: Int32(i)))
}

func writeUInt16(i: Int) -> [UInt8] {
    return [UInt8(i % 256), UInt8((i >> 8) % 256)]
}

func writeInt16(i: Int) -> [UInt8] {
    let ui = UInt(bitPattern: i)
    return [UInt8(ui & 0xFF), UInt8((ui >> 8) & 0xFF)]
}

// Easy formatting of a double value with 1 decimal if < 10, no decimal otherwise. Unit appended to the result.
func formatWithUnit(reading: Double, unit: String) -> String {
    if reading < 10 {
        return String(format: "%.1f%@", locale: NSLocale.currentLocale(), reading, unit)
    } else {
        return String(format: "%.0f%@", locale: NSLocale.currentLocale(), reading, unit)
    }
}
