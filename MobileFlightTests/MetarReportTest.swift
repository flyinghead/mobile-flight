//
//  MetarReportTest.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 23/04/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
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

class MetarReportTest: XCTestCase {
    
    func testReportDescription() {
        var report = MetarReport()
        report.wx = "RA"
        XCTAssertEqual(report.description, "Rain")
        
        report = MetarReport()
        report.wx = "SHRA"
        XCTAssertEqual(report.description, "Rain showers")
        
        report = MetarReport()
        report.wx = "TSRA"
        XCTAssertEqual(report.description, "Rain thunderstorm")
        
        report = MetarReport()
        report.wx = "VCTS"
        XCTAssertEqual(report.description, "Thunderstorm")
        
        report = MetarReport()
        report.wx = "-FZDZ"
        XCTAssertEqual(report.description, "Light freezing drizzle")
        
        report = MetarReport()
        report.wx = "+VCBLSN"
        XCTAssertEqual(report.description, "Heavy blowing snow")
        
        report = MetarReport()
        report.wx = "-SHG"
        XCTAssertEqual(report.description, "Light showers")
        
        report = MetarReport()
        report.wx = "-SHRA BCFG"
        XCTAssertEqual(report.description, "Light rain showers, Fog patches")
        
        report = MetarReport()
        report.wx = "DRSA"
        XCTAssertEqual(report.description, "Blowing sand")
        
        report = MetarReport()
        report.wx = "SHSN"
        XCTAssertEqual(report.description, "Snow showers")
        
        report = MetarReport()
        report.wx = "FZFG"
        XCTAssertEqual(report.description, "Freezing fog")
    }
    
}
