//
//  INavModel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 11/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

enum INavStatusMode {
    enum Internal : Int {
        case None = 0
        case Hold = 1
        case ReturnToHome = 2
        case Navigation = 3
        case Emergency = 15
    }
    case Known(Internal)
    case Unknown(Int)
    
    init(value: Int) {
        if let mode = Internal(rawValue: value) {
            self = .Known(mode)
        } else {
            self = .Unknown(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .Known(let mode):
            return mode.rawValue
        case .Unknown(let value):
            return value
        }
    }
}

enum INavStatusState {
    enum Internal : Int {
        case None = 0
        case ReturnToHomeStart = 1
        case ReturnToHomeEnRoute = 2
        case HoldInfinite = 3
        case HoldTimed = 4
        case WaypointEnRoute = 5
        case ProcessNext = 6
        case DoJump = 7
        case LandStart = 8
        case Landing = 9
        case Landed = 10
        case LandSettle = 11
        case LandStartDescent = 12
    }
    case Known(Internal)
    case Unknown(Int)
    
    init(value: Int) {
        if let mode = Internal(rawValue: value) {
            self = .Known(mode)
        } else {
            self = .Unknown(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .Known(let mode):
            return mode.rawValue
        case .Unknown(let value):
            return value
        }
    }
}

enum INavWaypointAction : Equatable {
    enum Internal : Int {
        case Waypoint = 1
        case ReturnToHome = 4
    }
    case Known(Internal)
    case Unknown(Int)
    
    init(value: Int) {
        if let mode = Internal(rawValue: value) {
            self = .Known(mode)
        } else {
            self = .Unknown(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .Known(let intern):
            return intern.rawValue
        case .Unknown(let value):
            return value
        }
    }
}

func ==(lhs: INavWaypointAction, rhs: INavWaypointAction) -> Bool {
    return lhs.intValue == rhs.intValue
}

enum INavStatusError {
    enum Internal : Int {
        case None = 0
        case TooFar = 1
        case GpsSpoiled = 2
        case WaypointCRC = 3
        case Finish = 4
        case TimeWait = 5
        case InvalidJump = 6
        case InvalidData = 7
        case WaitForRthAlt = 8
        case GpsFixLost = 9
        case Disarmed = 10
        case Landing = 11
    }
    case Known(Internal)
    case Unknown(Int)
    
    init(value: Int) {
        if let intern = Internal(rawValue: value) {
            self = .Known(intern)
        } else {
            self = .Unknown(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .Known(let mode):
            return mode.rawValue
        case .Unknown(let value):
            return value
        }
    }
}

enum INavUserControlMode {
    enum Internal : Int {
        case Attitude = 0
        case Velocity = 1
    }
    case Known(Internal)
    case Unknown(Int)
    
    init(value: Int) {
        if let mode = Internal(rawValue: value) {
            self = .Known(mode)
        } else {
            self = .Unknown(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .Known(let mode):
            return mode.rawValue
        case .Unknown(let value):
            return value
        }
    }
}

class INavConfig {
    static var theINavConfig = INavConfig()
    
    // MSP_NAV_STATUS
    var mode = INavStatusMode.Known(.None)
    var state = INavStatusState.Known(.None)
    var activeWaypointAction = INavWaypointAction.Known(.Waypoint)
    var activeWaypoint = 0
    var error = INavStatusError.Known(.None)
    
    // MSP_NAV_POSHOLD
    var userControlMode = INavUserControlMode.Known(.Attitude)
    var maxSpeed = 3.0
    var maxClimbRate = 5.0
    var maxManualSpeed = 5.0
    var maxManualClimbRate = 2.0
    var maxBankAngle = 30                    // (deg)
    var useThrottleMidForAltHold = false
    var hoverThrottle = 1500
    
}
