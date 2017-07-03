//
//  INavModel.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 11/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

enum INavStatusMode : DictionaryCoding {
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
    
    // MARK: DictionaryCoding
    func toDict() -> NSDictionary {
        return ["rawValue": intValue]
    }
    
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let rawValue = dict["rawValue"] as? Int
            else { return nil }
        self.init(value: rawValue)
    }
}

enum INavStatusState : DictionaryCoding {
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
    
    // MARK: DictionaryCoding
    func toDict() -> NSDictionary {
        return ["rawValue": intValue]
    }
    
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let rawValue = dict["rawValue"] as? Int
            else { return nil }
        self.init(value: rawValue)
    }
}

enum INavWaypointAction : Equatable, DictionaryCoding {
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
    
    // MARK: DictionaryCoding
    func toDict() -> NSDictionary {
        return ["rawValue": intValue]
    }
    
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let rawValue = dict["rawValue"] as? Int
            else { return nil }
        self.init(value: rawValue)
    }

}

func ==(lhs: INavWaypointAction, rhs: INavWaypointAction) -> Bool {
    return lhs.intValue == rhs.intValue
}

enum INavStatusError : DictionaryCoding {
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

    // MARK: DictionaryCoding
    func toDict() -> NSDictionary {
        return ["rawValue": intValue]
    }
    
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let rawValue = dict["rawValue"] as? Int
            else { return nil }
        self.init(value: rawValue)
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

struct INavArmingFlags : OptionSetType, DictionaryCoding {
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
    
    // MARK: DictionaryCoding
    func toDict() -> NSDictionary {
        return ["rawValue": rawValue]
    }
    
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let rawValue = dict["rawValue"] as? Int
            else { return nil }
        self.rawValue = rawValue
    }
}

enum INavSensorStatus : DictionaryCoding {
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

    // MARK: DictionaryCoding
    func toDict() -> NSDictionary {
        return ["rawValue": intValue]
    }
    
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let rawValue = dict["rawValue"] as? Int
            else { return nil }
        self.init(value: rawValue)
    }
}


struct Waypoint : DictionaryCoding {
    var number: Int
    var action: INavWaypointAction
    var position: GPSLocation
    var altitude: Double = 0.0
    var param1: Int
    var param2: Int
    var param3: Int
    var last: Bool
    
    init(number: Int, action: INavWaypointAction, position: GPSLocation?, altitude: Double, param1: Int, param2: Int, param3: Int, last: Bool) {
        self.number = number
        self.action = action
        self.position = position ?? GPSLocation(latitude: 0, longitude: 0)
        self.altitude = altitude
        self.param1 = param1
        self.param2 = param2
        self.param3 = param3
        self.last = last
    }
    
    init(position: GPSLocation, altitude: Double, speed: Int) {
        self.init(number: 0, action: .Known(.Waypoint), position: position, altitude: altitude, param1: speed, param2: 0, param3: 0, last: false)
    }
    
    static func rthWaypoint() -> Waypoint {
        return Waypoint(number: 0, action: .Known(.ReturnToHome), position: nil, altitude: 0, param1: 0, param2: 0, param3: 0, last: true)
    }
    
    // MARK: DictionaryCoding
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let number = dict["number"] as? Int,
            let action = dict["action"] as? Int,
            let position = dict["position"] as? NSDictionary,
            let altitude = dict["altitude"] as? Double,
            let param1 = dict["param1"] as? Int,
            let param2 = dict["param2"] as? Int,
            let param3 = dict["param3"] as? Int,
            let last = dict["last"] as? Bool
            else { return nil }
        
        self.init(number: number, action: INavWaypointAction(value: action), position: GPSLocation(fromDict: position), altitude: altitude, param1: param1, param2: param2, param3: param3, last: last)
    }
    
    func toDict() -> NSDictionary {
        return [ "number": number,
                 "action": action.intValue,
                 "position": position.toDict(),
                 "altitude": altitude,
                 "param1": param1,
                 "param2": param2,
                 "param3": param3,
                 "last": last
        ]
    }
}

class INavState : AutoCoded {
    var autoEncoding = [ "activeWaypoint", "accCalibAxis", "hardwareHealthy" ]
    static var theINavState = INavState()

    // MSP_NAV_STATUS
    var mode = INavStatusMode.Known(.None)
    var state = INavStatusState.Known(.None)
    var activeWaypointAction = INavWaypointAction.Known(.Waypoint)
    var activeWaypoint = 0
    var error = INavStatusError.Known(.None)

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
    
    // MSP_WP
    var waypoints = [Waypoint]()

    override init() {
        super.init()
    }
    
    // MARK: NSCoding

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        mode = INavStatusMode(fromDict: aDecoder.decodeObjectForKey("mode") as? NSDictionary)!
        state = INavStatusState(fromDict: aDecoder.decodeObjectForKey("state") as? NSDictionary)!
        activeWaypointAction = INavWaypointAction(fromDict: aDecoder.decodeObjectForKey("activeWaypointAction") as? NSDictionary)!
        error = INavStatusError(fromDict: aDecoder.decodeObjectForKey("error") as? NSDictionary)!
        armingFlags = INavArmingFlags(fromDict: aDecoder.decodeObjectForKey("armingFlags") as? NSDictionary)!
        gyroStatus = INavSensorStatus(fromDict: aDecoder.decodeObjectForKey("gyroStatus") as? NSDictionary)!
        accStatus = INavSensorStatus(fromDict: aDecoder.decodeObjectForKey("accStatus") as? NSDictionary)!
        magStatus = INavSensorStatus(fromDict: aDecoder.decodeObjectForKey("magStatus") as? NSDictionary)!
        baroStatus = INavSensorStatus(fromDict: aDecoder.decodeObjectForKey("baroStatus") as? NSDictionary)!
        gpsStatus = INavSensorStatus(fromDict: aDecoder.decodeObjectForKey("gpsStatus") as? NSDictionary)!
        sonarStatus = INavSensorStatus(fromDict: aDecoder.decodeObjectForKey("sonarStatus") as? NSDictionary)!
        pitotStatus = INavSensorStatus(fromDict: aDecoder.decodeObjectForKey("pitotStatus") as? NSDictionary)!
        flowStatus = INavSensorStatus(fromDict: aDecoder.decodeObjectForKey("flowStatus") as? NSDictionary)!
        if let waypointDicts = aDecoder.decodeObjectForKey("waypoints") as? [NSDictionary] {
            waypoints = [Waypoint]()
            for dict in waypointDicts {
                waypoints.append(Waypoint(fromDict: dict)!)
            }
        }
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        
        aCoder.encodeObject(mode.toDict(), forKey: "mode")
        aCoder.encodeObject(state.toDict(), forKey: "state")
        aCoder.encodeObject(activeWaypointAction.toDict(), forKey: "activeWaypointAction")
        aCoder.encodeObject(error.toDict(), forKey: "error")
        aCoder.encodeObject(armingFlags.toDict(), forKey: "armingFlags")
        aCoder.encodeObject(gyroStatus.toDict(), forKey: "gyroStatus")
        aCoder.encodeObject(accStatus.toDict(), forKey: "accStatus")
        aCoder.encodeObject(magStatus.toDict(), forKey: "magStatus")
        aCoder.encodeObject(baroStatus.toDict(), forKey: "baroStatus")
        aCoder.encodeObject(gpsStatus.toDict(), forKey: "gpsStatus")
        aCoder.encodeObject(sonarStatus.toDict(), forKey: "sonarStatus")
        aCoder.encodeObject(pitotStatus.toDict(), forKey: "pitotStatus")
        aCoder.encodeObject(flowStatus.toDict(), forKey: "flowStatus")
        var waypointDicts = [NSDictionary]()
        for waypoint in waypoints {
            waypointDicts.append(waypoint.toDict())
        }
        aCoder.encodeObject(waypointDicts, forKey: "waypoints")
    }
    
    var navStateDescription: (label: String, spoken: String, exception: Bool)? {
        let emergency: Bool
        switch mode {
        case .Known(.Emergency):
            emergency = true
        default:
            emergency = false
        }
        switch state {
        case .Known(let intern):
            switch intern {
            case .ReturnToHomeStart, .ReturnToHomeEnRoute:
                switch error {
                case .Known(.WaitForRthAlt):
                    return ("Return to Home - Climbing", "Return to Home. Climbing", false)
                default:
                    return ("Return to Home", "Return to Home", false)
                }
            case .LandStart, .LandSettle, .LandStartDescent, .Landing:
                return ("Landing", "Landing", emergency)
            case .Landed:
                return ("Landed", "Landed", emergency)
            case .WaypointEnRoute:
                switch error {
                case .Known(.Finish):
                    return ("Navigation Finished", "Navigation Finished", false)
                default:
                    return (String(format: "Navigating to WP #%d", activeWaypoint), String(format: "Navigating to waypoint %d", activeWaypoint), false)
                }
            case .HoldInfinite, .HoldTimed:
                return ("Holding Position", "Holding Position", false)
            case .None:
                return ("", "", false)
            default:
                return nil
            }
        case .Unknown(_):
            return emergency ? ("Emergency", "Emergency", true) : ("", "", false)
        }
    }
    
    func setWaypoint(waypoint: Waypoint) {
        for (idx, wp) in waypoints.enumerate() {
            if wp.number == waypoint.number {
                waypoints[idx] = waypoint
                return
            }
        }
        waypoints.append(waypoint)
    }
}

class INavConfig {
    static var theINavConfig = INavConfig()
    
    // MSP_NAV_POSHOLD
    var userControlMode = INavUserControlMode.Known(.Attitude)
    var maxSpeed = 3.0
    var maxClimbRate = 5.0
    var maxManualSpeed = 5.0
    var maxManualClimbRate = 2.0
    var maxBankAngle = 30                    // (deg)
    var useThrottleMidForAltHold = false
    var hoverThrottle = 1500
    
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

    // MSP_WP_GETINFO
    var maxWaypoints = 15
    var waypointListValid = true
    var waypointCount = 0
    
    init() {
    }
    
    init(copyOf: INavConfig) {
        self.userControlMode = copyOf.userControlMode
        self.maxSpeed = copyOf.maxSpeed
        self.maxClimbRate = copyOf.maxClimbRate
        self.maxManualSpeed = copyOf.maxManualSpeed
        self.maxManualClimbRate = copyOf.maxManualClimbRate
        self.maxBankAngle = copyOf.maxBankAngle
        self.useThrottleMidForAltHold = copyOf.useThrottleMidForAltHold
        self.hoverThrottle = copyOf.hoverThrottle
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
        self.maxWaypoints = copyOf.maxWaypoints
        self.waypointListValid = copyOf.waypointListValid
        self.waypointCount = copyOf.waypointCount
    }
}
