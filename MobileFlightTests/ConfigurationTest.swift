//
//  ConfigurationTest`.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 13/06/17.
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
