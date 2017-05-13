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
func getDistance(p1: GPSLocation, _ p2: GPSLocation) -> Double {
    // Earth radius in meters
    return 6378137.0 * getArcInRadians(p1, p2)
}

private func getArcInRadians(p1: GPSLocation, _ p2: GPSLocation) -> Double {
    let latitudeArc = toRadians(p1.latitude - p2.latitude)
    let longitudeArc = toRadians(p1.longitude - p2.longitude)
    
    var latitudeH = sin(latitudeArc / 2)
    latitudeH *= latitudeH
    var longitudeH = sin(longitudeArc / 2)
    longitudeH *= longitudeH
    
    let tmp = cos(toRadians(p1.latitude)) * cos(toRadians(p2.latitude))
    
    return 2 * asin(sqrt(latitudeH + tmp * longitudeH))
}

func getHeading(from: GPSLocation, to: GPSLocation) -> Double {
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

func chainMspCalls(msp: MSPParser, calls: [MSP_code], callback: (success: Bool) -> Void) {
    if calls.isEmpty {
        callback(success: true)
        return
    }
    msp.sendMessage(calls[0], data: nil, retry: 2) { success in
        if !success {
            callback(success: false)
        } else {
            chainMspCalls(msp, calls: Array(calls.suffixFrom(1)), callback: callback)
        }
    }
}

typealias SendCommand = ((Bool) -> Void) -> Void

func chainMspSend(calls: [SendCommand], callback:(success: Bool) -> Void) {
    if calls.isEmpty {
        callback(success: true)
        return
    }
    calls[0]() { success in
        if !success {
            callback(success: false)
        } else {
            chainMspSend(Array(calls.suffixFrom(1)), callback: callback)
        }
    }
}
