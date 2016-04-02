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
    return [UInt8(i & 0xFF), UInt8((i >> 8) & 0xFF), UInt8((i >> 16) & 0xFF), UInt8((i >> 24) & 0xFF)]
}

func writeInt32(i: Int) -> [UInt8] {
    return writeUInt32(i)
}

func writeUInt16(i: Int) -> [UInt8] {
    return [UInt8(i & 0xFF), UInt8((i >> 8) & 0xFF)]
}

func writeInt16(i: Int) -> [UInt8] {
    return writeUInt16(i)
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

let FEET_PER_METER = 100.0 / 2.54 / 12
let METER_PER_MILE = 1609.344
let METER_PER_NM = 1852.0

func formatDistance(meters: Double) -> String {
    switch selectedUnitSystem() {
    case .Imperial:
        if meters >= METER_PER_MILE {
            // Use statute mile
            return formatWithUnit(meters / METER_PER_MILE, unit: "mi")
        } else {
            // Use feet
            return formatWithUnit(meters * FEET_PER_METER, unit: "ft")
        }
        
    case .Aviation:
        if meters >= METER_PER_NM {
            // Use nautical mile
            return formatWithUnit(meters / METER_PER_NM, unit: "NM")
        } else {
            // Use feet
            return formatWithUnit(meters * FEET_PER_METER, unit: "ft")
        }
    default:
        // Meters
        return formatWithUnit(meters, unit: "m")
    }
}

func formatAltitude(meters: Double, appendUnit: Bool = true) -> String {
    if selectedUnitSystem() != .Metric {
        // Feet
        return formatWithUnit(meters * FEET_PER_METER, unit: appendUnit ? "ft" : "")
    } else {
        // Meters
        return formatWithUnit(meters, unit: appendUnit ? "m" : "")
    }
}

func formatSpeed(kmh: Double) -> String {
    switch selectedUnitSystem() {
    case .Imperial:
        // mile/h
        return formatWithUnit(kmh * 1000 / METER_PER_MILE, unit: "mph")
    case .Aviation:
        // Knots
        return formatWithUnit(kmh * 1000 / METER_PER_NM, unit: "kn")
    default:
        // km/h
        return formatWithUnit(kmh, unit: "km/h")
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
