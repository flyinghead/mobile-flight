//
//  INavModel.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 11/05/17.
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

enum INavStatusMode : DictionaryCoding {
    enum Internal : Int {
        case none = 0
        case hold = 1
        case returnToHome = 2
        case navigation = 3
        case emergency = 15
    }
    case known(Internal)
    case unknown(Int)
    
    init(value: Int) {
        if let mode = Internal(rawValue: value) {
            self = .known(mode)
        } else {
            self = .unknown(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .known(let mode):
            return mode.rawValue
        case .unknown(let value):
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
        case none = 0
        case returnToHomeStart = 1
        case returnToHomeEnRoute = 2
        case holdInfinite = 3
        case holdTimed = 4
        case waypointEnRoute = 5
        case processNext = 6
        case doJump = 7
        case landStart = 8
        case landing = 9
        case landed = 10
        case landSettle = 11
        case landStartDescent = 12
    }
    case known(Internal)
    case unknown(Int)
    
    init(value: Int) {
        if let mode = Internal(rawValue: value) {
            self = .known(mode)
        } else {
            self = .unknown(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .known(let mode):
            return mode.rawValue
        case .unknown(let value):
            return value
        }
    }
    
    var description: String {
        switch self {
        case .known(let intern):
            switch intern {
            case .none:
                return ""
            case .returnToHomeStart, .returnToHomeEnRoute:
                return "Return To Home"
            case .holdInfinite, .holdTimed:
                return "Position Hold"
            case .waypointEnRoute, .processNext,.doJump:
                return "Waypoint"
            case .landStart, .landing, .landSettle, .landStartDescent:
                return "Landing"
            case .landed:
                return "Landed"
            }
        case .unknown:
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
        case waypoint = 1
        case returnToHome = 4
    }
    case known(Internal)
    case unknown(Int)
    
    init(value: Int) {
        if let mode = Internal(rawValue: value) {
            self = .known(mode)
        } else {
            self = .unknown(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .known(let intern):
            return intern.rawValue
        case .unknown(let value):
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
        case none = 0
        case tooFar = 1
        case gpsSpoiled = 2
        case waypointCRC = 3
        case finish = 4
        case timeWait = 5
        case invalidJump = 6
        case invalidData = 7
        case waitForRthAlt = 8
        case gpsFixLost = 9
        case disarmed = 10
        case landing = 11
    }
    case known(Internal)
    case unknown(Int)
    
    init(value: Int) {
        if let intern = Internal(rawValue: value) {
            self = .known(intern)
        } else {
            self = .unknown(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .known(let mode):
            return mode.rawValue
        case .unknown(let value):
            return value
        }
    }
    
    var description: String {
        switch self {
        case .unknown:
            return "Unknown error"
        case .known(let intern):
            switch intern {
            case .none:
                return ""
            case .tooFar:
                return "Waypoint too far"
            case .gpsSpoiled:
                return "Bad GPS reception"
            case .waypointCRC:
                return "Error reading waypoint"
            case .finish:
                return "Navigation finished"
            case .timeWait:
                return "Waiting"
            case .invalidJump:
                return "Invalid jump"
            case .invalidData:
                return "Invalid waypoint data"
            case .waitForRthAlt:
                return "Reaching RTH altitude"
            case .gpsFixLost:
                return "GPS fix lost"
            case .disarmed:
                return "Disarmed"
            case .landing:
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
        case attitude = 0
        case velocity = 1
    }
    case known(Internal)
    case unknown(Int)
    
    init(value: Int) {
        if let mode = Internal(rawValue: value) {
            self = .known(mode)
        } else {
            self = .unknown(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .known(let mode):
            return mode.rawValue
        case .unknown(let value):
            return value
        }
    }
}

struct INavArmingFlags : OptionSet, DictionaryCoding {
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
        case none = 0
        case healthy = 1
        case unavailable = 2
        case unhealthy = 3
    }
    case known(Internal)
    case unknown(Int)
    
    init(value: Int) {
        if let mode = Internal(rawValue: value) {
            self = .known(mode)
        } else {
            self = .unknown(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .known(let mode):
            return mode.rawValue
        case .unknown(let value):
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
        self.init(number: 0, action: .known(.waypoint), position: position, altitude: altitude, param1: speed, param2: 0, param3: 0, last: false)
    }
    
    static func rthWaypoint() -> Waypoint {
        return Waypoint(number: 0, action: .known(.returnToHome), position: nil, altitude: 0, param1: 0, param2: 0, param3: 0, last: true)
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
    var mode = INavStatusMode.known(.none)
    var state = INavStatusState.known(.none)
    var activeWaypointAction = INavWaypointAction.known(.waypoint)
    var activeWaypoint = 0
    var error = INavStatusError.known(.none)

    // MSP_STATUS_EX
    var armingFlags = INavArmingFlags(rawValue: 1)
    var accCalibAxis = 0
    
    // MSP_SENSOR_STATUS
    var hardwareHealthy = true
    var gyroStatus = INavSensorStatus.known(.none)
    var accStatus = INavSensorStatus.known(.none)
    var magStatus = INavSensorStatus.known(.none)
    var baroStatus = INavSensorStatus.known(.none)
    var gpsStatus = INavSensorStatus.known(.none)
    var sonarStatus = INavSensorStatus.known(.none)
    var pitotStatus = INavSensorStatus.known(.none)
    var flowStatus = INavSensorStatus.known(.none)
    
    // MSP_WP
    var waypoints = [Waypoint]()

    override init() {
        super.init()
    }
    
    // MARK: NSCoding

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        mode = INavStatusMode(fromDict: aDecoder.decodeObject(forKey: "mode") as? NSDictionary)!
        state = INavStatusState(fromDict: aDecoder.decodeObject(forKey: "state") as? NSDictionary)!
        activeWaypointAction = INavWaypointAction(fromDict: aDecoder.decodeObject(forKey: "activeWaypointAction") as? NSDictionary)!
        error = INavStatusError(fromDict: aDecoder.decodeObject(forKey: "error") as? NSDictionary)!
        armingFlags = INavArmingFlags(fromDict: aDecoder.decodeObject(forKey: "armingFlags") as? NSDictionary)!
        gyroStatus = INavSensorStatus(fromDict: aDecoder.decodeObject(forKey: "gyroStatus") as? NSDictionary)!
        accStatus = INavSensorStatus(fromDict: aDecoder.decodeObject(forKey: "accStatus") as? NSDictionary)!
        magStatus = INavSensorStatus(fromDict: aDecoder.decodeObject(forKey: "magStatus") as? NSDictionary)!
        baroStatus = INavSensorStatus(fromDict: aDecoder.decodeObject(forKey: "baroStatus") as? NSDictionary)!
        gpsStatus = INavSensorStatus(fromDict: aDecoder.decodeObject(forKey: "gpsStatus") as? NSDictionary)!
        sonarStatus = INavSensorStatus(fromDict: aDecoder.decodeObject(forKey: "sonarStatus") as? NSDictionary)!
        pitotStatus = INavSensorStatus(fromDict: aDecoder.decodeObject(forKey: "pitotStatus") as? NSDictionary)!
        flowStatus = INavSensorStatus(fromDict: aDecoder.decodeObject(forKey: "flowStatus") as? NSDictionary)!
        if let waypointDicts = aDecoder.decodeObject(forKey: "waypoints") as? [NSDictionary] {
            waypoints = [Waypoint]()
            for dict in waypointDicts {
                waypoints.append(Waypoint(fromDict: dict)!)
            }
        }
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        
        aCoder.encode(mode.toDict(), forKey: "mode")
        aCoder.encode(state.toDict(), forKey: "state")
        aCoder.encode(activeWaypointAction.toDict(), forKey: "activeWaypointAction")
        aCoder.encode(error.toDict(), forKey: "error")
        aCoder.encode(armingFlags.toDict(), forKey: "armingFlags")
        aCoder.encode(gyroStatus.toDict(), forKey: "gyroStatus")
        aCoder.encode(accStatus.toDict(), forKey: "accStatus")
        aCoder.encode(magStatus.toDict(), forKey: "magStatus")
        aCoder.encode(baroStatus.toDict(), forKey: "baroStatus")
        aCoder.encode(gpsStatus.toDict(), forKey: "gpsStatus")
        aCoder.encode(sonarStatus.toDict(), forKey: "sonarStatus")
        aCoder.encode(pitotStatus.toDict(), forKey: "pitotStatus")
        aCoder.encode(flowStatus.toDict(), forKey: "flowStatus")
        var waypointDicts = [NSDictionary]()
        for waypoint in waypoints {
            waypointDicts.append(waypoint.toDict())
        }
        aCoder.encode(waypointDicts, forKey: "waypoints")
    }
    
    var navStateDescription: (label: String, spoken: String, exception: Bool)? {
        let emergency: Bool
        switch mode {
        case .known(.emergency):
            emergency = true
        default:
            emergency = false
        }
        switch state {
        case .known(let intern):
            switch intern {
            case .returnToHomeStart, .returnToHomeEnRoute:
                switch error {
                case .known(.waitForRthAlt):
                    return ("Return to Home - Climbing", "Return to Home. Climbing", false)
                default:
                    return ("Return to Home", "Return to Home", false)
                }
            case .landStart, .landSettle, .landStartDescent, .landing:
                return ("Landing", "Landing", emergency)
            case .landed:
                return ("Landed", "Landed", emergency)
            case .waypointEnRoute:
                switch error {
                case .known(.finish):
                    return ("Navigation Finished", "Navigation Finished", false)
                default:
                    return (String(format: "Navigating to WP #%d", activeWaypoint), String(format: "Navigating to waypoint %d", activeWaypoint), false)
                }
            case .holdInfinite, .holdTimed:
                return ("Holding Position", "Holding Position", false)
            case .none:
                return ("", "", false)
            default:
                return nil
            }
        case .unknown(_):
            return emergency ? ("Emergency", "Emergency", true) : ("", "", false)
        }
    }
    
    func setWaypoint(_ waypoint: Waypoint) {
        for (idx, wp) in waypoints.enumerated() {
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
    var userControlMode = INavUserControlMode.known(.attitude)
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
