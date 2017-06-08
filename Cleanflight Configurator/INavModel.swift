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
    
    var description: String {
        switch self {
        case .Known(let intern):
            switch intern {
            case .None:
                return ""
            case .ReturnToHomeStart, .ReturnToHomeEnRoute:
                return "Return To Home"
            case .HoldInfinite, .HoldTimed:
                return "Position Hold"
            case .WaypointEnRoute, .ProcessNext,.DoJump:
                return "Waypoint"
            case .LandStart, .Landing, .LandSettle, .LandStartDescent:
                return "Landing"
            case .Landed:
                return "Landed"
            }
        case .Unknown:
            return "Unknown"
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
    
    var description: String {
        switch self {
        case .Unknown:
            return "Unknown error"
        case .Known(let intern):
            switch intern {
            case .None:
                return ""
            case .TooFar:
                return "Waypoint too far"
            case .GpsSpoiled:
                return "Bad GPS reception"
            case .WaypointCRC:
                return "Error reading waypoint"
            case .Finish:
                return "Navigation finished"
            case .TimeWait:
                return "Waiting"
            case .InvalidJump:
                return "Invalid jump"
            case .InvalidData:
                return "Invalid waypoint data"
            case .WaitForRthAlt:
                return "Reaching RTH altitude"
            case .GpsFixLost:
                return "GPS fix lost"
            case .Disarmed:
                return "Disarmed"
            case .Landing:
                return "Landing"
            }
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

struct INavArmingFlags : OptionSetType {
    let rawValue: Int
    
    static let OkToArm              = INavArmingFlags(rawValue: 1 << 0)
    static let PreventArming        = INavArmingFlags(rawValue: 1 << 1)
    static let Armed                = INavArmingFlags(rawValue: 1 << 2)
    static let WasArmed             = INavArmingFlags(rawValue: 1 << 3)
    static let NotLevel             = INavArmingFlags(rawValue: 1 << 8)
    static let SensorsCalibrating   = INavArmingFlags(rawValue: 1 << 9)
    static let SystemOverloaded     = INavArmingFlags(rawValue: 1 << 10)
    static let NavigationSafety     = INavArmingFlags(rawValue: 1 << 11)
    static let CompassNotCalibrated = INavArmingFlags(rawValue: 1 << 12)
    static let AccNotCalibrated     = INavArmingFlags(rawValue: 1 << 13)
    static let HardwareFailure      = INavArmingFlags(rawValue: 1 << 15)

    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
}

enum INavSensorStatus {
    enum Internal : Int {
        case None = 0
        case Healthy = 1
        case Unavailable = 2
        case Unhealthy = 3
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
    
    // MSP_STATUS_EX
    var armingFlags = INavArmingFlags(rawValue: 1)
    var accCalibAxis = 0
    
    // MSP_SENSOR_STATUS
    var hardwareHealthy = true
    var gyroStatus = INavSensorStatus.Known(.None)
    var accStatus = INavSensorStatus.Known(.None)
    var magStatus = INavSensorStatus.Known(.None)
    var baroStatus = INavSensorStatus.Known(.None)
    var gpsStatus = INavSensorStatus.Known(.None)
    var sonarStatus = INavSensorStatus.Known(.None)
    var pitotStatus = INavSensorStatus.Known(.None)
    var flowStatus = INavSensorStatus.Known(.None)
    
    // MSP_RTH_AND_LAND_CONFIG
    var minRthDistance = 5.0            // m
    var rthClimbFirst = true
    var rthClimbIgnoreEmergency = false
    var rthTailFirst = false
    var rthAllowLanding = true
    var rthAltControlMode = 0
    var rthAbortThreshold = 500.0       // m
    var rthAltitude = 10.0
    var landDescendRate = 2.0           // m/s
    var landSlowdownMinAlt = 5.0        // m
    var landSlowdownMaxAlt = 20.0       // m
    var emergencyDescendRate = 5.0      // m/s
    
    // MSP_FW_CONFIG
    var fwCruiseThrottle = 1400
    var fwMinThrottle = 1200
    var fwMaxThrottle = 1700
    var fwMaxBankAngle = 20             // deg
    var fwMaxClimbAngle = 20            // deg
    var fwMaxDiveAngle = 15             // deg
    var fwPitchToThrottle = 10
    var fwLoiterRadius = 50.0           // m

    init() {
    }
    
    init(copyOf: INavConfig) {
        self.mode = copyOf.mode
        self.state = copyOf.state
        self.activeWaypointAction = copyOf.activeWaypointAction
        self.activeWaypoint = copyOf.activeWaypoint
        self.error = copyOf.error
        self.userControlMode = copyOf.userControlMode
        self.maxSpeed = copyOf.maxSpeed
        self.maxClimbRate = copyOf.maxClimbRate
        self.maxManualSpeed = copyOf.maxManualSpeed
        self.maxManualClimbRate = copyOf.maxManualClimbRate
        self.maxBankAngle = copyOf.maxBankAngle
        self.useThrottleMidForAltHold = copyOf.useThrottleMidForAltHold
        self.hoverThrottle = copyOf.hoverThrottle
        self.armingFlags = copyOf.armingFlags
        self.accCalibAxis = copyOf.accCalibAxis
        self.hardwareHealthy = copyOf.hardwareHealthy
        self.gyroStatus = copyOf.gyroStatus
        self.accStatus = copyOf.accStatus
        self.magStatus = copyOf.magStatus
        self.baroStatus = copyOf.baroStatus
        self.gpsStatus = copyOf.gpsStatus
        self.sonarStatus = copyOf.sonarStatus
        self.pitotStatus = copyOf.pitotStatus
        self.flowStatus = copyOf.flowStatus
        self.minRthDistance = copyOf.minRthDistance
        self.rthClimbFirst = copyOf.rthClimbFirst
        self.rthClimbIgnoreEmergency = copyOf.rthClimbIgnoreEmergency
        self.rthTailFirst = copyOf.rthTailFirst
        self.rthAllowLanding = copyOf.rthAllowLanding
        self.rthAltControlMode = copyOf.rthAltControlMode
        self.rthAbortThreshold = copyOf.rthAbortThreshold
        self.rthAltitude = copyOf.rthAltitude
        self.landDescendRate = copyOf.landDescendRate
        self.landSlowdownMinAlt = copyOf.landSlowdownMinAlt
        self.landSlowdownMaxAlt = copyOf.landSlowdownMaxAlt
        self.emergencyDescendRate = copyOf.emergencyDescendRate
        self.fwCruiseThrottle = copyOf.fwCruiseThrottle
        self.fwMinThrottle = copyOf.fwMinThrottle
        self.fwMaxThrottle = copyOf.fwMaxThrottle
        self.fwMaxBankAngle = copyOf.fwMaxBankAngle
        self.fwMaxClimbAngle = copyOf.fwMaxClimbAngle
        self.fwMaxDiveAngle = copyOf.fwMaxDiveAngle
        self.fwPitchToThrottle = copyOf.fwPitchToThrottle
        self.fwLoiterRadius = copyOf.fwLoiterRadius
    }
}
