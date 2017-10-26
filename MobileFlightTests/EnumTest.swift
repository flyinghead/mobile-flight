//
//  EnumTest.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 11/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
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

import XCTest
@testable import MobileFlight

class EnumTest: XCTestCase {
    
    func testBaudRate() {
        XCTAssertEqual(BaudRate(value: 999).intValue, 999)
        XCTAssertEqual(BaudRate(value: 0), BaudRate.auto)
        XCTAssertEqual(BaudRate(value: 0).description, "Auto")
        XCTAssertEqual(BaudRate(value: 1), BaudRate.baud9600)
        XCTAssertEqual(BaudRate(value: 1).description, "9600")
        XCTAssertEqual(BaudRate(value: 7), BaudRate.baud250000)
    }
    
}
