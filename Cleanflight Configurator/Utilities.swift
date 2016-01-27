//
//  Utilities.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 15/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

func readInt8(array: [UInt8], index: Int) -> Int {
    return Int(Int8(bitPattern: array[index]));
}

func readUInt16(array: [UInt8], index: Int) -> Int {
    return Int(array[index]) + Int(array[index+1]) * 256;
}

func readInt16(array: [UInt8], index: Int) -> Int {
    return Int(array[index]) + Int(Int8(bitPattern: array[index+1])) * 256;
}

func readUInt32(array: [UInt8], index: Int) -> Int {
    var res = Int(array[index+3])
    res = res * 256 + Int(array[index+2])
    res = res * 256 + Int(array[index+1])
    res = res * 256 + Int(array[index])
    return res
}

func readInt32(array: [UInt8], index: Int) -> Int {
    var res = Int(Int8(bitPattern: array[index+3]))
    res = res * 256 + Int(array[index+2])
    res = res * 256 + Int(array[index+1])
    res = res * 256 + Int(array[index])
    return res
}

func writeUInt32(i: Int) -> [UInt8] {
    return [UInt8(i % 256), UInt8((i >> 8) % 256), UInt8((i >> 16) % 256), UInt8(i >> 24)]
}

func writeInt32(i: Int) -> [UInt8] {
    return writeUInt32(i)
}

func writeUInt16(i: Int) -> [UInt8] {
    return [UInt8(i % 256), UInt8((i >> 8) % 256)]
}

func writeInt16(i: Int) -> [UInt8] {
    let ui = UInt(bitPattern: i)
    return [UInt8(ui & 0xFF), UInt8((ui >> 8) & 0xFF)]
}

func writeInt8(i: Int) -> UInt8 {
    return UInt8(bitPattern: Int8(i))
}

// Easy formatting of a double value with 1 decimal if < 10, no decimal otherwise. Unit appended to the result.
func formatWithUnit(reading: Double, unit: String) -> String {
    if reading < 10 {
        return String(format: "%.1f%@", locale: NSLocale.currentLocale(), reading, unit)
    } else {
        return String(format: "%.0f%@", locale: NSLocale.currentLocale(), reading, unit)
    }
}

func formatDistance(meters: Double) -> String {
    if useImperialUnits() {
        // Use feet since distances are typically small. We should use nautical miles for large distances
        return formatWithUnit(meters * 100 / 2.54 / 12, unit: "ft")
    } else {
        // Meters
        return formatWithUnit(meters, unit: "m")
    }
}

func formatAltitude(meters: Double) -> String {
    if useImperialUnits() {
        // Feet
        return formatWithUnit(meters * 100 / 2.54 / 12, unit: "ft")
    } else {
        // Meters
        return formatWithUnit(meters, unit: "m")
    }
}

func formatSpeed(kmh: Double) -> String {
    if useImperialUnits() {
        // Knots
        return formatWithUnit(kmh / 1.852, unit: "kn")
    } else {
        // Meters
        return formatWithUnit(kmh, unit: "km/h")
    }
}

func useImperialUnits() -> Bool {
    switch userDefaultAsString(.UnitSystem) {
    case "imperial":
        return true
    case "metric":
        return false
    default:
        return !(NSLocale.currentLocale().objectForKey(NSLocaleUsesMetricSystem) as? Bool ?? true)
    }
    
}

func constrain(n: Double, min minimum: Double, max maximum: Double) -> Double {
    return min(maximum, max(minimum, n))
}

func applyDeadband(value: Double, width: Double) -> Double {
    if abs(value) < width {
        return 0
    } else if (value > 0) {
        return value - width
    } else {
        return value + width
    }
}
