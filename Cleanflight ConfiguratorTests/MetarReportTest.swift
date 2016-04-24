//
//  MetarReportTest.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 23/04/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import XCTest
@testable import Cleanflight_Configurator

class MetarReportTest: XCTestCase {
    
    func testReportDescription() {
        let report = MetarReport()
        
        report.cover = "RA"
        XCTAssertEqual(report.description, "Rain")
        
        report.cover = "SHRA"
        XCTAssertEqual(report.description, "Rain showers")
        
        report.cover = "TSRA"
        XCTAssertEqual(report.description, "Rain thunderstorm")
        
        report.cover = "VCTS"
        XCTAssertEqual(report.description, "Thunderstorm")
        
        report.cover = "-FZDZ"
        XCTAssertEqual(report.description, "Light freezing drizzle")
        
        report.cover = "+VCBLSN"
        XCTAssertEqual(report.description, "Heavy blowing snow")
        
        report.cover = "-SHG"
        XCTAssertEqual(report.description, "Light showers")
        
        report.cover = "-SHRA BCFG"
        XCTAssertEqual(report.description, "Light rain showers, Fog patches")
        
        report.cover = "DRSA"
        XCTAssertEqual(report.description, "Blowing sand")
        
        report.cover = "SHSN"
        XCTAssertEqual(report.description, "Snow showers")
        
        report.cover = "FZFG"
        XCTAssertEqual(report.description, "Freezing fog")
    }
    
}
