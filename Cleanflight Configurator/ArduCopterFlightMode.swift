//
//  ArduCopterFlightMode.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 13/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

enum ArduCopterFlightMode : Int {
    case STABILIZE = 0
    case ACRO = 1
    case ALT_HOLD = 2
    case AUTO = 3
    case GUIDED = 4
    case LOITER = 5
    case RTL = 6
    case CIRCLE = 7
    case LAND = 9
    case DRIFT = 11
    case SPORT = 13
    case FLIP = 14
    case AUTOTUNE = 15
    case POSHOLD = 16
    case BRAKE = 17
    case THROW = 18
    case UNKNOWN = 999
    
    func modeName() -> String {
        switch self {
        case .STABILIZE:
            return "STABILIZE"
        case .ACRO:
            return "ACRO"
        case .ALT_HOLD:
            return "ALT HOLD"
        case .AUTO:
            return "AUTO"
        case .GUIDED:
            return "GUIDED"
        case .LOITER:
            return "LOITER"
        case .RTL:
            return "RTL"
        case .CIRCLE:
            return "CIRCLE"
        case .LAND:
            return "LAND"
        case .DRIFT:
            return "DRIFT"
        case .SPORT:
            return "SPORT"
        case .FLIP:
            return "FLIP"
        case .AUTOTUNE:
            return "AUTOTUNE"
        case .POSHOLD:
            return "POS HOLD"
        case .BRAKE:
            return "BRAKE"
        case .THROW:
            return "THROW"
        case .UNKNOWN:
            return ""
        }
    }
    
    func spokenModeName() -> String {
        switch self {
        case .STABILIZE:
            return "Stabilize mode"
        case .ACRO:
            return "Acro mode"
        case .ALT_HOLD:
            return "Altitude Hold mode"
        case .AUTO:
            return "Auto mode"
        case .GUIDED:
            return "Guided mode"
        case .LOITER:
            return "Loiter mode"
        case .RTL:
            return "Return to Launch mode"
        case .CIRCLE:
            return "Circle mode"
        case .LAND:
            return "Land mode"
        case .DRIFT:
            return "Drift mode"
        case .SPORT:
            return "Sport mode"
        case .FLIP:
            return "Flip mode"
        case .AUTOTUNE:
            return "Autotune mode"
        case .POSHOLD:
            return "Position Hold mode"
        case .BRAKE:
            return "Brake mode"
        case .THROW:
            return "Throw mode"
        case .UNKNOWN:
            return "Unknown mode"
        }
    }
}

