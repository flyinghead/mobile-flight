//
//  OSDElement.swift
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
let SYM_ARROW_SOUTH = "\u{60}"
let SYM_ARROW_NORTH_WEST = "\u{6A}"
let SYM_HEADING_W = "\u{1B}"
let SYM_HEADING_N = "\u{18}"
let SYM_HEADING_E = "\u{1A}"
let SYM_HEADING_LINE = "\u{1D}"
let SYM_HEADING_DIVIDED_LINE = "\u{1C}"
let SYM_TEMP_C = "\u{0E}"
let SYM_KMH = Configuration.theConfig.isINav ? "\u{A1}" : "\u{A5}"

enum OSDElement {
    case rssi
    case mainBattVoltage
    case crosshairs
    case artificialHorizon
    case horizonSidebars
    case onTime
    case flyTime
    case flyMode
    case craftName
    case throttlePosition
    case vtxChannel
    case currentDraw
    case mAhDrawn
    case gpsSpeed
    case gpsSats
    case altitude
    
    case pidRoll
    case pidPitch
    case pidYaw
    case power
    
    case pidRateProfile
    case batteryWarning
    case avgCellVoltage
    case gpsLongitude
    case gpsLatitude
    case debug
    case pitchAngle
    case rollAngle
    case mainBattUsage
    
    case homeDirection
    case homeDistance
    case heading
    case vario
    case varioNum
    case airSpeed
    
    case headingNum
    case disarmed
    case compassBar
    case escTemperature
    case escRpm
    
    case unknown(index: Int)
    
    fileprivate static let betaflight31Elements = [ OSDElement.rssi, .mainBattVoltage, .crosshairs, .artificialHorizon, .horizonSidebars, .onTime, .flyTime, .flyMode, .craftName, .throttlePosition, .vtxChannel, .currentDraw,
                                                .mAhDrawn, .gpsSpeed, .gpsSats, .altitude, .pidRoll, .pidPitch, .pidYaw, .power, .pidRateProfile, .batteryWarning ]
    fileprivate static let inav16Elements = [ OSDElement.rssi, .mainBattVoltage, .crosshairs, .artificialHorizon, .horizonSidebars, .onTime, .flyTime, .flyMode, .craftName, .throttlePosition, .vtxChannel, .currentDraw,
                                          .mAhDrawn, .gpsSpeed, .gpsSats, .altitude, .pidRoll, .pidPitch, .pidYaw, .power,
                                          .gpsLongitude, .gpsLatitude, .homeDirection, .homeDistance, .heading, .vario, .varioNum, .airSpeed ]
    fileprivate static let cf2Elements = [ OSDElement.rssi, .mainBattVoltage, .crosshairs, .artificialHorizon, .horizonSidebars, .onTime, .flyTime, .flyMode, .craftName, .throttlePosition, .vtxChannel, .currentDraw,
                                       .mAhDrawn, .gpsSpeed, .gpsSats, .altitude, .pidRoll, .pidPitch, .pidYaw, .power, .pidRateProfile, .batteryWarning,
                                       .avgCellVoltage, .gpsLongitude, .gpsLatitude ]
    fileprivate static let betaflight32Elements = [ OSDElement.rssi, .mainBattVoltage, .crosshairs, .artificialHorizon, .horizonSidebars, .onTime, .flyTime, .flyMode, .craftName, .throttlePosition, .vtxChannel, .currentDraw,
                                                .mAhDrawn, .gpsSpeed, .gpsSats, .altitude, .pidRoll, .pidPitch, .pidYaw, .power, .pidRateProfile, .batteryWarning,
                                                .avgCellVoltage, .gpsLongitude, .gpsLatitude, .debug, .pitchAngle, .rollAngle, .mainBattUsage, .disarmed, .homeDirection, .homeDistance, .headingNum, .varioNum,
                                                .compassBar, .escTemperature, .escRpm ]
    
    
    static var Elements: [OSDElement] {
        let config = Configuration.theConfig
        
        if config.isINav {
            return inav16Elements
        }
        else if config.isApiVersionAtLeast("1.36") {
            return betaflight32Elements
        }
        else if config.isApiVersionAtLeast("1.35") {
            return cf2Elements
        }
        else {
            return betaflight31Elements
        }
    }
    
    var positionable: Bool {
        switch self {
        case .crosshairs, .artificialHorizon, .horizonSidebars:
            return false
        default:
            return true
        }
    }
    
    var preview: String {
        switch self {
        case .rssi:
            return SYM_RSSI + "99"
        case .mainBattVoltage:
            return SYM_BATTERY + "16.8" + SYM_VOLT
        case .onTime:
            return SYM_ON_M + "05:42"
        case .flyTime:
            return SYM_FLY_M + "04:11"
        case .flyMode:
            return "STAB"
        case .craftName:
            return "CRAFT_NAME"
        case .throttlePosition:
            return SYM_THR + SYM_THR1 + " 69"
        case .vtxChannel:
            return "R:2:1"
        case .currentDraw:
            return SYM_AMP + "42.0"
        case .mAhDrawn:
            return SYM_MAH + "690"
        case .gpsSpeed:
            return "40"
        case .gpsSats:
            return SYM_GPS_SAT + "14"
        case .altitude:
            return "399.7" + (OSD.theOSD.unitMode == .metric ? SYM_METRE : SYM_FEET)
        case .artificialHorizon:
            return SYM_AH_BAR9_4 + SYM_AH_BAR9_4 + SYM_AH_BAR9_4 + SYM_AH_BAR9_4 + SYM_AH_BAR9_4 + SYM_AH_BAR9_4 + SYM_AH_BAR9_4 + SYM_AH_BAR9_4 + SYM_AH_BAR9_4
        case .crosshairs:
            return SYM_AH_CENTER_LINE + SYM_AH_CENTER + SYM_AH_CENTER_LINE_RIGHT
        
        case .pidRoll:
            return "ROL  43  40  20"
        case .pidPitch:
            return "PIT  58  50  22"
        case .pidYaw:
            return "YAW  70  45  20"
        case .power:
            return "142W"
        
        case .pidRateProfile:
            return "1-2"
        case .batteryWarning:
            return "LOW VOLTAGE"
        case .avgCellVoltage:
            return SYM_BATTERY + "3.98" + SYM_VOLT
        case .gpsLongitude:
            return "-00.0"
        case .gpsLatitude:
            return "-00.0"
        case .debug:
            return "DBG     0     0     0     0"
        case .pitchAngle:
            return "-00.0"
        case .rollAngle:
            return "-00.0"
        case .mainBattUsage:
            return SYM_PB_START + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_FULL + SYM_PB_END + SYM_PB_EMPTY + SYM_PB_CLOSE
        
        case .homeDirection:
            return SYM_ARROW_NORTH_WEST
        case .homeDistance:
            return "300m"
        case .heading:
            return "175"
        case .vario:
            return "-"
        case .varioNum:
            return SYM_ARROW_SOUTH + "2.2"
        case .airSpeed:
            return " 34" + SYM_KMH
        case .compassBar:
            return SYM_HEADING_W + SYM_HEADING_LINE + SYM_HEADING_DIVIDED_LINE + SYM_HEADING_LINE + SYM_HEADING_N + SYM_HEADING_LINE + SYM_HEADING_DIVIDED_LINE + SYM_HEADING_LINE + SYM_HEADING_E
        case .disarmed:
            return "DISARMED"
        case .escTemperature:
            return SYM_TEMP_C + "37"
        case .escRpm:
            return "29000"
            
        case .unknown(let index):
            return String(format: "UNKNOWN%d", index)
            
        default:        // No preview
            return ""
        }
    }
    
    func defaultPosition() -> (x: Int, y: Int, visible: Bool) {
        switch self {
        case .mainBattVoltage:
            return (12, 1, true)
        case .rssi:
            return (8, 1, true)
        case .artificialHorizon:
            return (10, 6, true)
        case .crosshairs:
            return (13, 6, true)
        case .onTime:
            return (22, 1, true)
        case .flyTime:
            return (1, 1, true)
        case .flyMode:
            return (13, 11, true)
        case .craftName:
            return (10, 12, true)
        case .throttlePosition:
            return (1, 7, true)
        case .vtxChannel:
            return (24, 11, true)
        case .currentDraw:
            return (1, 12, true)
        case .mAhDrawn:
            return (1, 11, true)
        case .gpsSpeed:
            return (26, 6, true)
        case .gpsSats:
            return (19, 1, true)
        case .altitude:
            return (23, 7, true)
            
        case .pidRoll:
            return (7, 13, true)
        case .pidPitch:
            return (7, 14, true)
        case .pidYaw:
            return (7, 15, true)
        case .power:
            return (1, 10, true)
            
        case .pidRateProfile:
            return (25, 10, true)
        case .avgCellVoltage:
            return (12, 2, true)
        case .batteryWarning:
            return (9, 10, true)
        case .debug:
            return (7, 12, false)
        case .pitchAngle:
            return (1, 8, true)
        case .rollAngle:
            return (1, 9, true)
        
        case .homeDistance:
            return (15, 9, true)
        case .heading:
            return (12, 1, false)
        case .vario:
            return (22, 5, false)
        case .varioNum:
            return (23, 8, true)
        case .homeDirection:
            return (14, 9, true)
        case .gpsLatitude:
            return (25, 14, true)
        case .gpsLongitude:
            return (25, 15, true)
        case .mainBattUsage:
            return (8, 12, true)
        case .compassBar:
            return (10, 8, true)
        case .disarmed:
            return (10, 4, true)
        case .headingNum:
            return (23, 9, true)
        case .escTemperature:
            return (18, 2, true)
        case .escRpm:
            return (19, 2, true)
        case .airSpeed:
            return (1, 13, false)
        default:
            return (10, 10, true)
        }
    }
    
    func multiplePreviews() -> [(x: Int, y: Int, s: String)]? {
        switch self {
        case .horizonSidebars:
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
        case .rssi:
            return "RSSI"
        case .mainBattVoltage:
            return "Battery Voltage"
        case .crosshairs:
            return "Crosshairs"
        case .artificialHorizon:
            return "Artificial Horizon"
        case .horizonSidebars:
            return "Horizon Sidebars"
        case .onTime:
            return "On Time"
        case .flyTime:
            return "Fly Time"
        case .flyMode:
            return "Fly Mode"
        case .craftName:
            return "Craft Name"
        case .throttlePosition:
            return "Throttle Position"
        case .vtxChannel:
            return "VTX Channel"
        case .currentDraw:
            return "Current Draw"
        case .mAhDrawn:
            return "mAh Drawn"
        case .gpsSpeed:
            return "GPS Speed"
        case .gpsSats:
            return "GPS Sats"
        case .altitude:
            return "Altitude"
            
        case .pidRoll:
            return "Roll PID"
        case .pidPitch:
            return "Pitch PID"
        case .pidYaw:
            return "Yaw PID"
        case .power:
            return "Power"
            
        case .pidRateProfile:
            return "PID Rate Profile"
        case .batteryWarning:
            return "Battery Warning"
        case .avgCellVoltage:
            return "Average Cell Voltage"
        case .gpsLongitude:
            return "GPS Longitude"
        case .gpsLatitude:
            return "GPS Latitude"
        case .debug:
            return "Debug"
        case .pitchAngle:
            return "Pitch Angle"
        case .rollAngle:
            return "Roll Angle"
        case .mainBattUsage:
            return "Battery Usage"
            
        case .homeDirection:
            return "Home Direction"
        case .homeDistance:
            return "Home Distance"
        case .heading:
            return "Heading"
        case .vario:
            return "Variometer"
        case .varioNum:
            return "Digital Variometer"
        case .airSpeed:
            return "Air Speed"
            
        case .headingNum:
            return "Digital Heading"
        case .compassBar:
            return "Compass Bar"
        case .disarmed:
            return "Disarmed"
        case .escTemperature:
            return "ESC Temperature"
        case .escRpm:
            return "ESC RPM"
            
        case .unknown(let index):
            return String(format: "Unknown %d", index)

        }
    }
}

func encodePos(_ x: Int, y: Int, visible: Bool = true) -> Int {
    let v = 0x800 * (visible ? 1 : 0)
    return v
        + (y << 5)
        + x
}

func decodePos(_ v: Int) -> (x: Int, y: Int, visible: Bool) {
    let visible = (v & 0x800) != 0
    let y = (v >> 5) & 0x1F
    let x = v & 0x1F
    
    return (x, y, visible)
}
