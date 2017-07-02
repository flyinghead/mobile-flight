//
//  MetarReportTest.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 23/04/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

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
