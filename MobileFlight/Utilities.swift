//
//  Utilities.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 15/12/15.
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

import Foundation

func readInt8(_ array: [UInt8], index: Int) -> Int {
    return Int(Int8(bitPattern: array[index]));
}

func readUInt16(_ array: [UInt8], index: Int) -> Int {
    return Int(array[index]) + Int(array[index+1]) << 8;
}

func readInt16(_ array: [UInt8], index: Int) -> Int {
    return Int(array[index]) + Int(Int8(bitPattern: array[index+1])) << 8;
}

func readUInt32(_ array: [UInt8], index: Int) -> Int {
    var res = Int(array[index+3])
    res = res << 8 + Int(array[index+2])
    res = res << 8 + Int(array[index+1])
    res = res << 8 + Int(array[index])
    return res
}

func readInt32(_ array: [UInt8], index: Int) -> Int {
    var res = Int(Int8(bitPattern: array[index+3]))
    res = res << 8 + Int(array[index+2])
    res = res << 8 + Int(array[index+1])
    res = res << 8 + Int(array[index])
    return res
}

func writeUInt32(_ i: Int) -> [UInt8] {
    return [UInt8(i & 0xFF), UInt8((i >> 8) & 0xFF), UInt8((i >> 16) & 0xFF), UInt8((i >> 24) & 0xFF)]
}

func writeInt32(_ i: Int) -> [UInt8] {
    return writeUInt32(i)
}

func writeUInt16(_ i: Int) -> [UInt8] {
    return [UInt8(i & 0xFF), UInt8((i >> 8) & 0xFF)]
}

func writeInt16(_ i: Int) -> [UInt8] {
    return writeUInt16(i)
}

func writeInt8(_ i: Int) -> UInt8 {
    return UInt8(bitPattern: Int8(i))
}

func constrain(_ n: Double, min minimum: Double, max maximum: Double) -> Double {
    return min(maximum, max(minimum, n))
}

func constrain(_ n: Int, min minimum: Int, max maximum: Int) -> Int {
    return min(maximum, max(minimum, n))
}

func applyDeadband(_ value: Double, width: Double) -> Double {
    if abs(value) < width {
        return 0
    } else if (value > 0) {
        return value - width
    } else {
        return value + width
    }
}

/// Returns the distance in meters between two 2D positions
func getDistance(_ p1: GPSLocation, _ p2: GPSLocation) -> Double {
    // Earth radius in meters
    return 6378137.0 * getArcInRadians(p1, p2)
}

private func getArcInRadians(_ p1: GPSLocation, _ p2: GPSLocation) -> Double {
    let latitudeArc = toRadians(p1.latitude - p2.latitude)
    let longitudeArc = toRadians(p1.longitude - p2.longitude)
    
    var latitudeH = sin(latitudeArc / 2)
    latitudeH *= latitudeH
    var longitudeH = sin(longitudeArc / 2)
    longitudeH *= longitudeH
    
    let tmp = cos(toRadians(p1.latitude)) * cos(toRadians(p2.latitude))
    
    return 2 * asin(sqrt(latitudeH + tmp * longitudeH))
}

func getHeading(_ from: GPSLocation, to: GPSLocation) -> Double {
    let lat1 = toRadians(from.latitude)
    let lon1 = toRadians(from.longitude)
    let lat2 = toRadians(to.latitude)
    let lon2 = toRadians(to.longitude)
    
    let x = sin(lon2 - lon1) * cos(lat2)
    let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1)
    let heading = atan2(x, y)
    return (toDegrees(heading) + 360).truncatingRemainder(dividingBy: 360)
}

private func toRadians(_ a: Double) -> Double {
    return a * .pi / 180
}

private func toDegrees(_ a: Double) -> Double {
    return a / .pi * 180
}

// Swift version of the Java "synchronized" section
func synchronized(_ lock: AnyObject, closure: () -> Void) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

let compassPoints = [ "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW", "N" ]

func compassPoint(_ heading: Double) -> String {
    var localHeading = heading
    localHeading = localHeading.truncatingRemainder(dividingBy: 360)
    if localHeading < 0 {
        localHeading += 360
    }

    for i in 0 ..< 17 {
        if localHeading < (Double(i) + 0.5) * 360 / 16 {
            return compassPoints[i]
        }
    }
    return "?"
}

func chainMspCalls(_ msp: MSPParser, calls: [MSP_code], ignoreFailure: Bool = false, callback: @escaping (_ success: Bool) -> Void) {
    if calls.isEmpty {
        callback(true)
        return
    }
    msp.sendMessage(calls[0], data: nil, retry: 2) { success in
        if !success && !ignoreFailure {
            callback(false)
        } else {
            chainMspCalls(msp, calls: Array(calls.suffix(from: 1)), ignoreFailure: ignoreFailure, callback: callback)
        }
    }
}

typealias SendCommand = (@escaping (Bool) -> Void) -> Void

func chainMspSend(_ calls: [SendCommand], callback: @escaping (_ success: Bool) -> Void) {
    if calls.isEmpty {
        callback(true)
        return
    }
    calls[0]() { success in
        if !success {
            callback(false)
        } else {
            chainMspSend(Array(calls.suffix(from: 1)), callback: callback)
        }
    }
}
