//
//  OSD.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 14/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

enum VideoMode : Int {
    case Auto = 0
    case PAL = 1
    case NTSC = 2
    
    var lines: Int {
        switch self {
        case NTSC:
            return NTSC_LINES
        default:
            return PAL_LINES
        }
    }
    
    static let descriptions = [ "Auto", "PAL", "NTSC" ]
}

enum UnitMode : Int {
    case Imperial = 0
    case Metric = 1
    
    static let descriptions = [ "Imperial", "Metric" ]
}

enum FlightStats : Int {
    case MaxSpeed = 0
    case MinBattery = 1
    case MinRssi = 2
    case MaxCurrent = 3
    case UsedMAh = 4
    case MaxAltitude = 5
    case Blackbox = 6
    case EndBattery = 7
    case Timer1 = 8
    case Timer2 = 9
    case MaxDistance = 10
    case BlackboxNumber = 11
    
    var label: String {
        switch self {
        case .MaxSpeed:
            return "Max Speed"
        case .MinBattery:
            return "Min Battery"
        case .MinRssi:
            return "Min RSSI"
        case .MaxCurrent:
            return "Max Current"
        case .UsedMAh:
            return "Used mAh"
        case .MaxAltitude:
            return "Max Altitude"
        case .Blackbox:
            return "Blackbox"
        case .EndBattery:
            return "End Battery"
        case .Timer1:
            return "Timer1"
        case .Timer2:
            return "Timer2"
        case .MaxDistance:
            return "Max Distance"
        case .BlackboxNumber:
            return "Blackbox Log Number"
        }
    }
}

let OSDTimerSources = [ "On Time", "Total Armed Time", "Last Armed Time" ]

struct OSDTimer {
    var source: Int     // 0=On Time, 1=Total Armed Time, 2=Last Armed Time
    var precision: Int  // 0=1 second, 1=1/100 second
    var alarm: Int      // In minutes
    
    static func parse(rawValue: Int) -> OSDTimer {
        return OSDTimer(source: rawValue & 0xF, precision: (rawValue >> 4) & 0xF, alarm: (rawValue >> 8) & 0xFF)
    }
    
    var rawValue: Int {
        return (source & 0x0F) | ((precision & 0x0F) << 4) | ((alarm & 0xFF ) << 8)
    }
}

class OSD {
    static var theOSD = OSD()
    
    var supported = false
    var videoMode = VideoMode.Auto
    var unitMode = UnitMode.Imperial
    var elements = [OSDElementPosition]()
    private var _fontDefinition: FontDefinition!
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

    func loadFont(name: String) {
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
        if let url = NSBundle.mainBundle().URLForResource(fontPath, withExtension: "mcm") {
            _fontDefinition = FontDefinition.load(url)
            fontName = name
            UserDefault.OSDFont.setValue(name)
        } else {
            NSLog("Cannot load font " + fontPath)
        }
    }
}
