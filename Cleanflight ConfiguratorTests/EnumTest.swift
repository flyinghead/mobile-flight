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
/*
enum BaudRate {
    enum Internal : Int {
        case Auto = 0
        case Baud9600 = 1
        case Baud19200 = 2
        case Baud38400 = 3
        case Baud57600 = 4
        case Baud115200 = 5
        case Baud230400 = 6
        case Baud250000 = 7
    }
    case Known(Internal)
    case Unknown(Int)
    
    init(value: Int) {
        if let intern = Internal(rawValue: value) {
            self = .Known(intern)
        } else {
            self = .Unknown(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .Known(let intern):
            return intern.rawValue
        case .Unknown(let value):
            return value
        }
    }
}
*/
