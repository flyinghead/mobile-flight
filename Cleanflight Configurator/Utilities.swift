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
    let suffix = unit.isEmpty ? "" : " ".stringByAppendingString(unit)
    if reading < 10 {
        return String(format: "%.1f%@", locale: NSLocale.currentLocale(), reading, suffix)
    } else {
        return String(format: "%.0f%@", locale: NSLocale.currentLocale(), reading, suffix)
    }
}

let FEET_PER_METER = 100.0 / 2.54 / 12
let METER_PER_MILE = 1609.344
let METER_PER_NM = 1852.0

func formatDistance(meters: Double) -> String {
    switch selectedUnitSystem() {
    case .Imperial:
        if meters >= METER_PER_MILE {
            // Statute mile
            return formatWithUnit(meters / METER_PER_MILE, unit: "mi")
        } else {
            // Feet
            return formatWithUnit(meters * FEET_PER_METER, unit: "ft")
        }
        
    case .Aviation:
        if meters >= METER_PER_NM {
            // Nautical mile
            return formatWithUnit(meters / METER_PER_NM, unit: "NM")
        } else {
            // Feet
            return formatWithUnit(meters * FEET_PER_METER, unit: "ft")
        }
    default:
        if meters >= 1000 {
            // Kilometer
            return formatWithUnit(meters / 1000, unit: "km")
        } else {
            // Meter
            return formatWithUnit(meters, unit: "m")
        }
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

func formatTemperature(celsius: Double) -> String {
    if selectedUnitSystem() == .Imperial {
        return String(format: "%.0f° F", celsius * 1.8 + 32)
    } else {
        return String(format: "%.0f° C", celsius)
    }
}

func constrain(n: Double, min minimum: Double, max maximum: Double) -> Double {
    return min(maximum, max(minimum, n))
}

func constrain(n: Int, min minimum: Int, max maximum: Int) -> Int {
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

/// Returns the distance in meters between two 2D positions
func getDistance(p1: Position, _ p2: Position) -> Double {
    // Earth radius in meters
    return 6378137.0 * getArcInRadians(p1, p2)
}

private func getArcInRadians(p1: Position, _ p2: Position) -> Double {
    let latitudeArc = (p1.latitude - p2.latitude) * M_PI / 180
    let longitudeArc = (p1.longitude - p2.longitude) * M_PI / 180
    
    var latitudeH = sin(latitudeArc / 2)
    latitudeH *= latitudeH
    var longitudeH = sin(longitudeArc / 2)
    longitudeH *= longitudeH
    
    let tmp = cos(toRadians(p1.latitude)) * cos(toRadians(p2.latitude))
    
    return 2 * asin(sqrt(latitudeH + tmp * longitudeH))
}

func getHeading(from: Position, to: Position) -> Double {
    let lat1 = toRadians(from.latitude)
    let lon1 = toRadians(from.longitude)
    let lat2 = toRadians(to.latitude)
    let lon2 = toRadians(to.longitude)
    
    let x = sin(lon2 - lon1) * cos(lat2)
    let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1)
    let heading = atan2(x, y)
    return (toDegrees(heading) + 360) % 360
}

private func toRadians(a: Double) -> Double {
    return a * M_PI / 180
}

private func toDegrees(a: Double) -> Double {
    return a / M_PI * 180
}

// Swift version of the Java "synchronized" section
func synchronized(lock: AnyObject, closure: () -> Void) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

let compassPoints = [ "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW", "N" ]

func compassPoint(heading: Double) -> String {
    var localHeading = heading
    localHeading %= 360
    if localHeading < 0 {
        localHeading += 360
    }

    for i in 0..<17 {
        if localHeading < (Double(i) + 0.5) * 360 / 16 {
            return compassPoints[i]
        }
    }
    return "?"
}
