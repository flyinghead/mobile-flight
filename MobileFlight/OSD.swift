//
//  OSD.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 14/05/17.
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

import Foundation

enum VideoMode : Int {
    case auto = 0
    case pal = 1
    case ntsc = 2
    
    var lines: Int {
        switch self {
        case .ntsc:
            return NTSC_LINES
        default:
            return PAL_LINES
        }
    }
    
    static let descriptions = [ "Auto", "PAL", "NTSC" ]
}

enum UnitMode : Int {
    case imperial = 0
    case metric = 1
    
    static let descriptions = [ "Imperial", "Metric" ]
}

enum FlightStats : Int {
    case maxSpeed = 0
    case minBattery = 1
    case minRssi = 2
    case maxCurrent = 3
    case usedMAh = 4
    case maxAltitude = 5
    case blackbox = 6
    case endBattery = 7
    case timer1 = 8
    case timer2 = 9
    case maxDistance = 10
    case blackboxNumber = 11
    
    var label: String {
        switch self {
        case .maxSpeed:
            return "Max Speed"
        case .minBattery:
            return "Min Battery"
        case .minRssi:
            return "Min RSSI"
        case .maxCurrent:
            return "Max Current"
        case .usedMAh:
            return "Used mAh"
        case .maxAltitude:
            return "Max Altitude"
        case .blackbox:
            return "Blackbox"
        case .endBattery:
            return "End Battery"
        case .timer1:
            return "Timer1"
        case .timer2:
            return "Timer2"
        case .maxDistance:
            return "Max Distance"
        case .blackboxNumber:
            return "Blackbox Log Number"
        }
    }
}

let OSDTimerSources = [ "On Time", "Total Armed Time", "Last Armed Time" ]

struct OSDTimer {
    var source: Int     // 0=On Time, 1=Total Armed Time, 2=Last Armed Time
    var precision: Int  // 0=1 second, 1=1/100 second
    var alarm: Int      // In minutes
    
    static func parse(_ rawValue: Int) -> OSDTimer {
        return OSDTimer(source: rawValue & 0xF, precision: (rawValue >> 4) & 0xF, alarm: (rawValue >> 8) & 0xFF)
    }
    
    var rawValue: Int {
        return (source & 0x0F) | ((precision & 0x0F) << 4) | ((alarm & 0xFF ) << 8)
    }
}

class OSD {
    static var theOSD = OSD()
    
    var supported = false
    var videoMode = VideoMode.auto
    var unitMode = UnitMode.imperial
    var elements = [OSDElementPosition]()
    fileprivate var _fontDefinition: FontDefinition!
    var fontName: String!
    
    var rssiAlarm = 20
    var capacityAlarm = 2200
    var minutesAlarm = 10       // api < 1.36
    var altitudeAlarm = 100
    
    var displayedStats: [Bool]?
    var timers: [OSDTimer]?
    
    var fontDefinition: FontDefinition {
        if _fontDefinition == nil {
            loadFont(UserDefault.OSDFont.stringValue ?? "default")
            if _fontDefinition == nil && UserDefault.OSDFont.stringValue  != nil {
                loadFont("default")
            }
        }
        return _fontDefinition!
    }
    
    init() {
        // For Debug
        /*
        elements = [OSDElementPosition]()
        for e in OSDElement.Elements {
            let (x, y, visible, _) = e.defaultPosition()
            let position = OSDElementPosition()
            position.element = e
            position.visible = visible
            position.x = x
            position.y = y
            elements.append(position)
        }
         */
    }

    func loadFont(_ name: String) {
        if fontName != nil && fontName == name {
            return
        }
        var fontPath: String
        let config = Configuration.theConfig
        if config.isBetaflight {
            fontPath = "betaflight/" + (name == "cleanflight" ? "betaflight" : name)
        }
        else if config.isINav {
            fontPath = "inav/" + name
        } else {
            fontPath = "cleanflight/" + (name == "betaflight" ? "cleanflight" : name)
        }
        if let url = Bundle.main.url(forResource: fontPath, withExtension: "mcm") {
            _fontDefinition = FontDefinition.load(url)
            fontName = name
            UserDefault.OSDFont.setValue(name)
        } else {
            NSLog("Cannot load font " + fontPath)
        }
    }
}
