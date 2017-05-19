//
//  OSDElement.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 14/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

let CHARS_PER_LINE = 30
let PAL_LINES = 16
let NTSC_LINES = 13

let SYM_VOLT = "\u{06}"
let SYM_RSSI = "\u{01}"
let SYM_AH_RIGHT = "\u{02}"
let SYM_AH_LEFT = "\u{03}"
let SYM_THR = "\u{04}"
let SYM_THR1 = "\u{05}"
let SYM_FLY_M = "\u{9C}"
let SYM_ON_M = "\u{9B}"
let SYM_AH_CENTER_LINE = "\u{26}"
let SYM_AH_CENTER_LINE_RIGHT = "\u{27}"
let SYM_AH_CENTER = "\u{7E}"
let SYM_AH_BAR9_0 = "\u{80}"
let SYM_AH_BAR9_4 = "\u{84}"
let SYM_AH_DECORATION = "\u{13}"
let SYM_LOGO = "\u{A0}"
let SYM_AMP = "\u{9A}"
let SYM_MAH = "\u{07}"
let SYM_METRE = "\u{0C}"
let SYM_FEET = "\u{0F}"
let SYM_GPS_SAT = "\u{1F}"
let SYM_PB_START = "\u{8A}"
let SYM_PB_FULL = "\u{8B}"
let SYM_PB_EMPTY = "\u{8D}"
let SYM_PB_END = "\u{8E}"
let SYM_PB_CLOSE = "\u{8F}"
let SYM_BATTERY = "\u{96}"

enum OSDElement {
    case RSSI
    case MainBattVoltage
    case Crosshairs
    case ArtificialHorizon
    case HorizonSidebars
    case OnTime
    case FlyTime
    case FlyMode
    case CraftName
    case ThrottlePosition
    case VtxChannel
    case CurrentDraw
    case MAhDrawn
    case GpsSpeed
    case GpsSats
    case Altitude
    
    case PidRoll
    case PidPitch
    case PidYaw
    case Power
    
    case PidRateProfile
    case BatteryWarning
    case AvgCellVoltage
    case GpsLongitude
    case GpsLatitude
    case Debug
    case PitchAngle
    case RollAngle
    case MainBattUsage
    
    case HomeDirection
    case HomeDistance
    case Heading
    case Vario
    case VarioNum
    
    case Unknown(index: Int)
    
    private static let betaflight31Elements = [ OSDElement.RSSI, .MainBattVoltage, .Crosshairs, .ArtificialHorizon, .HorizonSidebars, .OnTime, .FlyTime, .FlyMode, .CraftName, .ThrottlePosition, .VtxChannel, .CurrentDraw, .MAhDrawn,
                                        .GpsSpeed, .GpsSats, .Altitude, .PidRoll, .PidPitch, .PidYaw, .Power ]
    private static let inav16Elements = [ OSDElement.RSSI, .MainBattVoltage, .Crosshairs, .ArtificialHorizon, .HorizonSidebars, .OnTime, .FlyTime, .FlyMode, .CraftName, .ThrottlePosition, .VtxChannel, .CurrentDraw, .MAhDrawn,
                                        .GpsSpeed, .GpsSats, .Altitude, .PidRoll, .PidPitch, .PidYaw, .Power, .GpsLongitude, .GpsLatitude, .HomeDirection, .HomeDistance, .Heading, .Vario, .VarioNum ]
    private static let cf2Elements = [ OSDElement.RSSI, .MainBattVoltage, .Crosshairs, .ArtificialHorizon, .HorizonSidebars, .OnTime, .FlyTime, .FlyMode, .CraftName, .ThrottlePosition, .VtxChannel, .CurrentDraw, .MAhDrawn,
                                  .GpsSpeed, .GpsSats, .Altitude, .PidRoll, .PidPitch, .PidYaw, .Power, .PidRateProfile, .BatteryWarning, .AvgCellVoltage, .GpsLongitude, .GpsLatitude, .Debug, .PitchAngle, .RollAngle, .MainBattUsage ]
    
    static var Elements: [OSDElement] {
        let config = Configuration.theConfig
        
        if config.isApiVersionAtLeast("1.35") {
            return cf2Elements
        }
        else if config.isINav {
            return inav16Elements
        }
        else {
            return betaflight31Elements
        }
    }
    
    var positionable: Bool {
        switch self {
        case .Crosshairs, .ArtificialHorizon, .HorizonSidebars:
            return false
        default:
            return true
        }
    }
    
    var preview: String {
        switch self {
        case .RSSI:
            return SYM_RSSI + "99"
        case .MainBattVoltage:
            return SYM_BATTERY + "16.8" + SYM_VOLT
        case .OnTime:
            return SYM_ON_M + "05:42"
        case .FlyTime:
            return SYM_FLY_M + "04:11"
        case .FlyMode:
            return "STAB"
        case .CraftName:
            return "CRAFT_NAME"
        case .ThrottlePosition:
            return SYM_THR + SYM_THR1 + " 69"
        case .VtxChannel:
            return "R:2:1"
        case .CurrentDraw:
            return SYM_AMP + "42.0"
        case .MAhDrawn:
            return SYM_MAH + "690"
        case .GpsSpeed:
            return "40"
        case .GpsSats:
            return SYM_GPS_SAT + "14"
        case .Altitude:
            return "399.7" + (OSD.theOSD.unitMode == .Metric ? SYM_METRE : SYM_FEET)
        case .ArtificialHorizon:
            return SYM_AH_BAR9_4 + SYM_AH_BAR9_4 + SYM_AH_BAR9_4 + SYM_AH_BAR9_4 + SYM_AH_BAR9_4 + SYM_AH_BAR9_4 + SYM_AH_BAR9_4 + SYM_AH_BAR9_4 + SYM_AH_BAR9_4
        case .Crosshairs:
            return SYM_AH_CENTER_LINE + SYM_AH_CENTER + SYM_AH_CENTER_LINE_RIGHT
        
        case .PidRoll:
            return "ROL  43  40  20"
        case .PidPitch:
            return "PIT  58  50  22"
        case .PidYaw:
            return "YAW  70  45  20"
        case .Power:
            return "142W"
        
        case .PidRateProfile:
            return "1-2"
        case .BatteryWarning:
            return "LOW VOLTAGE"
        case .AvgCellVoltage:
            return SYM_BATTERY + "3.98" + SYM_VOLT
        case .GpsLongitude:
            return "-00.0"
        case .GpsLatitude:
            return "-00.0"
        case .Debug:
            return "DBG     0     0     0     0"
        case .PitchAngle:
            return "-00.0"
        case .RollAngle:
            return "-00.0"
        case .MainBattUsage:
            return SYM_PB_START + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_END + SYM_PB_EMPTY + SYM_PB_CLOSE
        
        case .HomeDirection:
            return "165"
        case .HomeDistance:
            return "300m"
        case .Heading:
            return "175"
        case .Vario:
            return "-"
        case .VarioNum:
            return "2"
        
        case .Unknown(let index):
            return String(format: "UNKNOWN%d", index)
            
        default:        // No preview
            return ""
        }
    }
    
    func defaultPosition() -> (x: Int, y: Int, visible: Bool) {
        switch self {
        case .MainBattVoltage:
            return (12, 1, true)
        case .RSSI:
            return (8, 1, true)
        case .ArtificialHorizon:
            return (10, 6, true)
        case .Crosshairs:
            return (13, 6, true)
        case .OnTime:
            return (22, 1, true)
        case .FlyTime:
            return (1, 1, true)
        case .FlyMode:
            return (13, 11, true)
        case .CraftName:
            return (10, 12, true)
        case .ThrottlePosition:
            return (1, 7, true)
        case .VtxChannel:
            return (24, 11, true)
        case .CurrentDraw:
            return (1, 12, true)
        case .MAhDrawn:
            return (1, 11, true)
        case .GpsSpeed:
            return (26, 6, true)
        case .GpsSats:
            return (19, 1, true)
        case .Altitude:
            return (23, 7, true)
            
        case .PidRoll:
            return (7, 13, true)
        case .PidPitch:
            return (7, 14, true)
        case .PidYaw:
            return (7, 15, true)
        case .Power:
            return (1, 10, true)
            
        case .PidRateProfile:
            return (25, 10, true)
        case .AvgCellVoltage:
            return (12, 2, true)
        case .BatteryWarning:
            return (9, 10, true)
        case .Debug:
            return (7, 12, true)
        case .PitchAngle:
            return (1, 8, true)
        case .RollAngle:
            return (1, 9, true)
        
        case .HomeDistance:
            return (1, 1, false)
        case .Heading:
            return (12, 1, false)
        case .Vario:
            return (22, 5, false)
        case .VarioNum:
            return (23, 7, false)
        case .HomeDirection:
            return (14, 11, false)
        case .GpsLatitude:
            return (18, 14, true)
        case .GpsLongitude:
            return (18, 15, true)
        case .MainBattUsage:
            return (15, 10, true)

        default:
            return (10, 10, true)
        }
    }
    
    func multiplePreviews() -> [(x: Int, y: Int, s: String)]? {
        switch self {
        case .HorizonSidebars:
            // center: 14, 6
            var strings = [(x: Int, y: Int, s: String)]()
            for i in -3 ..< 4 {
                strings.append((7, 6 + i, SYM_AH_DECORATION))
                strings.append((21, 6 + i, SYM_AH_DECORATION))
            }
            strings.append((7, 6, SYM_AH_LEFT))
            strings.append((21, 6, SYM_AH_RIGHT))
            return strings
        default:
            return nil
        }
    }
    
    var description: String {
        switch self {
        case .RSSI:
            return "RSSI"
        case .MainBattVoltage:
            return "Battery Voltage"
        case .Crosshairs:
            return "Crosshairs"
        case .ArtificialHorizon:
            return "Artificial Horizon"
        case .HorizonSidebars:
            return "Horizon Sidebars"
        case .OnTime:
            return "On Time"
        case .FlyTime:
            return "Fly Time"
        case .FlyMode:
            return "Fly Mode"
        case .CraftName:
            return "Craft Name"
        case .ThrottlePosition:
            return "Throttle Position"
        case .VtxChannel:
            return "VTX Channel"
        case .CurrentDraw:
            return "Current Draw"
        case .MAhDrawn:
            return "mAh Drawn"
        case .GpsSpeed:
            return "GPS Speed"
        case .GpsSats:
            return "GPS Sats"
        case .Altitude:
            return "Altitude"
            
        case .PidRoll:
            return "Roll PID"
        case .PidPitch:
            return "Pitch PID"
        case .PidYaw:
            return "Yaw PID"
        case .Power:
            return "Power"
            
        case .PidRateProfile:
            return "PID Rate Profile"
        case .BatteryWarning:
            return "Battery Warning"
        case .AvgCellVoltage:
            return "Average Cell Voltage"
        case .GpsLongitude:
            return "GPS Longitude"
        case .GpsLatitude:
            return "GPS Latitude"
        case .Debug:
            return "Debug"
        case .PitchAngle:
            return "Pitch Angle"
        case .RollAngle:
            return "Roll Angle"
        case .MainBattUsage:
            return "Battery Usage"
            
        case .HomeDirection:
            return "Home Direction"
        case .HomeDistance:
            return "Home Distance"
        case .Heading:
            return "Heading"
        case .Vario:
            return "Variometer"
        case .VarioNum:
            return "Digital Variometer"
            
        case .Unknown(let index):
            return String(format: "Unknown %d", index)

        }
    }
}

func encodePos(x: Int, y: Int, visible: Bool = true) -> Int {
    let v = 0x800 * (visible ? 1 : 0)
    return v
        + (y << 5)
        + x
}

func decodePos(v: Int) -> (x: Int, y: Int, visible: Bool) {
    let visible = (v & 0x800) != 0
    let y = (v >> 5) & 0x1F
    let x = v & 0x1F
    
    return (x, y, visible)
}
