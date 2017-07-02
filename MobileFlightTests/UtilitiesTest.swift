//
//  CompassPointTest.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 04/04/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

import XCTest
@testable import MobileFlight

class UtilitiesTest: XCTestCase {
    
    func testCompassPoint() {
        XCTAssertEqual(compassPoint(0), "N")
        XCTAssertEqual(compassPoint(45), "NE")
        XCTAssertEqual(compassPoint(90), "E")
        XCTAssertEqual(compassPoint(135), "SE")
        XCTAssertEqual(compassPoint(180), "S")
        XCTAssertEqual(compassPoint(225), "SW")
        XCTAssertEqual(compassPoint(270), "W")
        XCTAssertEqual(compassPoint(315), "NW")
        
        XCTAssertEqual(compassPoint(22.5 + 11.24), "NNE")
        XCTAssertEqual(compassPoint(67.5 - 11.24), "ENE")
        XCTAssertEqual(compassPoint(337.5 + 11.24), "NNW")
    }
    
    func testGetHeading() {
        let lat = 48.0
        let lon = 2.0
        
        let from = GPSLocation(latitude: lat, longitude: lon)
        
        var to = GPSLocation(latitude: lat, longitude: lon + 1)
        XCTAssertEqualWithAccuracy(getHeading(from, to: to), 90, accuracy: 0.5)

        to = GPSLocation(latitude: lat, longitude: lon - 1)
        XCTAssertEqualWithAccuracy(getHeading(from, to: to), 270, accuracy: 0.5)
        
        to = GPSLocation(latitude: lat + 1, longitude: lon)
        XCTAssertEqualWithAccuracy(getHeading(from, to: to), 0, accuracy: 0.5)
        
        to = GPSLocation(latitude: lat - 1, longitude: lon)
        XCTAssertEqualWithAccuracy(getHeading(from, to: to), 180, accuracy: 0.5)
    }
    
    func testReadNumber() {
        XCTAssertEqual(readUInt32([ UInt8(0x3C), UInt8(0), UInt8(0), UInt8(0x80)], index: 0), Int(bitPattern: 0x8000003C))
    }
}
