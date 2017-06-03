//
//  EnumTest.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 11/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import XCTest
@testable import Cleanflight_Configurator

class EnumTest: XCTestCase {
    
    func testBaudRate() {
        XCTAssertEqual(BaudRate(value: 999).intValue, 999)
        XCTAssertEqual(BaudRate(value: 0), BaudRate.Auto)
        XCTAssertEqual(BaudRate(value: 0).description, "Auto")
        XCTAssertEqual(BaudRate(value: 1), BaudRate.Baud9600)
        XCTAssertEqual(BaudRate(value: 1).description, "9600")
        XCTAssertEqual(BaudRate(value: 7), BaudRate.Baud250000)
    }
    
}
