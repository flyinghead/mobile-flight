//
//  ConfigurationTest`.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 13/06/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import XCTest
@testable import MobileFlight

class ConfigurationTest : XCTestCase {
    
    override func setUp() {
        resetAircraftModel()
    }
    
    func testMode() {
        let settings = Settings.theSettings
        settings.boxNames = [String]()
        settings.boxIds = [Int]()
        
        for i in 0 ..< 32 {
            settings.boxNames!.append(String(format: "MODE%d", i))
            settings.boxIds!.append(i)
        }
        
        let config = Configuration.theConfig
        config.mode = Int.min
    }
}
