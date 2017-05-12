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
        XCTAssertEqual(BaudRate.Known(.Auto).intValue, 0)
        let e1 = BaudRate(value: 0)
        XCTAssertEqual(e1.intValue, 0)
        switch e1 {
        case .Known(let intern):
            switch intern {
            case .Auto:
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }

        let e2 = BaudRate(value: 10)
        XCTAssertEqual(e2.intValue, 10)
        switch e2 {
        case .Unknown(let value):
            XCTAssertEqual(value, 10)
        default:
            XCTFail()
        }
    }
    
}
