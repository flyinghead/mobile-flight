//
//  AircraftModel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

struct BaseFlightFeature : OptionSetType {
    let rawValue: UInt32
    
    static let None         = BaseFlightFeature(rawValue: 0)
    static let RxPpm  = BaseFlightFeature(rawValue: 1 << 0)
    static let VBat = BaseFlightFeature(rawValue: 1 << 1)
    static let InflightCal  = BaseFlightFeature(rawValue: 1 << 2)
    static let RxSerial  = BaseFlightFeature(rawValue: 1 << 3)
    static let MotorStop  = BaseFlightFeature(rawValue: 1 << 4)
    static let ServoTilt  = BaseFlightFeature(rawValue: 1 << 5)
    static let SoftSerial  = BaseFlightFeature(rawValue: 1 << 6)
    static let GPS  = BaseFlightFeature(rawValue: 1 << 7)
    static let Failsafe  = BaseFlightFeature(rawValue: 1 << 8)
    static let Sonar  = BaseFlightFeature(rawValue: 1 << 9)
    static let Telemetry  = BaseFlightFeature(rawValue: 1 << 10)
    static let CurrentMeter  = BaseFlightFeature(rawValue: 1 << 11)
    static let ThreeD  = BaseFlightFeature(rawValue: 1 << 12)
    static let RxParallel  = BaseFlightFeature(rawValue: 1 << 13)
    static let RxMsp  = BaseFlightFeature(rawValue: 1 << 14)
    static let RssiAdc  = BaseFlightFeature(rawValue: 1 << 15)
    static let LedStrip  = BaseFlightFeature(rawValue: 1 << 16)
    static let Display  = BaseFlightFeature(rawValue: 1 << 17)
    static let OneShot125  = BaseFlightFeature(rawValue: 1 << 18)
    static let Blackbox  = BaseFlightFeature(rawValue: 1 << 19)
    static let ChannelForwarding  = BaseFlightFeature(rawValue: 1 << 20)
}

enum Mode : String {
    case ARM = "ARM"
    case ANGLE = "ANGLE"
    case HORIZON = "HORIZON"
    case BARO = "BARO"
    case MAG = "MAG"
    case HEADFREE = "HEADFREE"
    case HEADADJ = "HEADADJ"
    case CAMSTAB = "CAMSTAB"
    case CAMTRIG = "CAMTRIG"
    case GPSHOME = "GPSHOME"
    case GPSHOLD = "GPSHOLD"
    case PASSTHRU = "PASSTHRU"
    case BEEPER = "BEEPER"
    case LEDMAX = "LEDMAX"
    case LEDLOW = "LEDLOW"
    case LLIGHTS = "LLIGHTS"
    case CALIB = "CALIB"
    case GOVERNOR = "GOVERNOR"
    case OSDSW = "OSD SW"
    case TELEMETRY = "TELEMETRY"
    case GTUNE = "GTUNE"
    case SONAR = "SONAR"
    case SERVO1 = "SERVO1"
    case SERVO2 = "SERVO2"
    case SERVO3 = "SERVO3"
    case BLACKBOX = "BLACKBOX"
    case FAILSAFE = "FAILSAFE"
}
struct ModeRange {
    var id = 0
    var auxChannelId = 0
    var start = 0
    var end = 0
}

enum PIDName : String {
    case Roll = "ROLL"
    case Pitch = "PITCH"
    case Yaw = "YAW"
    case Alt = "ALT"
    case Pos = "Pos"
    case PosR = "PosR"
    case NavR = "NavR"
    case Level = "LEVEL"
    case Mag = "MAG"
    case Vel = "VEL"
}

class Settings {
    static let theSettings = Settings()
    
    // MSP_ARMING_CONFIG / MSP_SET_ARMING_CONFIG
    var autoDisarmDelay: Int?
    var disarmKillSwitch = false
    
    // MSP_BF_CONFIG / MSP_SET_BF_CONFIG
    var mixerConfiguration: Int?
    var features: BaseFlightFeature?
    var serialRxType: Int?
    var boardAlignRoll: Int?
    var boardAlignPitch: Int?
    var boardAlignYaw: Int?
    var currentScale: Int?
    var currentOffset: Int?

    // MSP_BOXNAMES
    var boxNames: [String]?
    // MSP_BOXIDS
    var boxIds: [Int]?
    
    // MSP_MODE_RANGES / MSP_SET_MODE_RANGES
    var modeRanges: [ModeRange]?
    var modeRangeSlots = 0
    
    // MSP_RC_TUNING / MSP_SET_RC_TUNING
    var rcExpo = 0.0        // pitch & roll expo curve
    var yawExpo = 0.0       // yaw expo curve
    var rcRate = 0.0        // pitch & roll expo curve
    var rollRate = 0.0
    var pitchRate = 0.0
    var yawRate = 0.0
    var throttleMid = 0.0
    var throttleExpo = 0.0
    var tpaRate = 0.0
    var tpaBreakpoint = 0
    
    // MSP_PIDNAMES
    var pidNames: [String]?
    
    // MSP_PID
    var pidValues: [[Double]]?
    
    // MSP_PID_CONTROLLER
    var pidController = 0
    
    private init() {
        
    }
    init(copyOf: Settings) {
        self.autoDisarmDelay = copyOf.autoDisarmDelay
        self.disarmKillSwitch = copyOf.disarmKillSwitch
        
        self.mixerConfiguration = copyOf.mixerConfiguration
        self.features = copyOf.features
        self.serialRxType = copyOf.serialRxType
        self.boardAlignRoll = copyOf.boardAlignRoll
        self.boardAlignPitch = copyOf.boardAlignPitch
        self.boardAlignYaw = copyOf.boardAlignYaw
        self.currentScale = copyOf.currentScale
        self.currentOffset = copyOf.currentOffset
        
        self.boxNames = copyOf.boxNames
        self.boxIds = copyOf.boxIds
        self.modeRanges = copyOf.modeRanges
        self.modeRangeSlots = copyOf.modeRangeSlots
        
        self.rcExpo = copyOf.rcExpo
        self.yawExpo = copyOf.yawExpo
        self.rcRate = copyOf.rcRate
        self.rollRate = copyOf.rollRate
        self.pitchRate = copyOf.pitchRate
        self.yawRate = copyOf.yawRate
        self.tpaRate = copyOf.tpaRate
        self.throttleMid = copyOf.throttleMid
        self.throttleExpo = copyOf.throttleExpo
        self.tpaBreakpoint = copyOf.tpaBreakpoint
    }
    
    func isModeOn(mode: Mode, forStatus status: UInt32) -> Bool {
        if boxNames == nil {
            return false
        }
        for (i, m) in boxNames!.enumerate() {
            if (mode.rawValue == m) {
                return status & (1 << UInt32(i)) != 0
            }
        }
        return false
    }
    
    func getPID(name: PIDName) -> [Double]? {
        if let index = pidNames?.indexOf(name.rawValue) {
            return pidValues?[index]
        } else {
            return nil
        }
    }
}

class Misc {
    static let theMisc = Misc()
    
    // MSP_MISC / MSP_SET_MISC
    var midRC = 1500            // rxConfig.midrc [1401 - 1599], also set by RX_CONFIG (but then no range is enforced...)
    var minThrottle = 1150      // escAndServoConfig.minthrottle    // Used when motors are armed is !MOTOR_STOP
    var maxThrottle = 1850      // escAndServoConfig.maxthrottle    // Motor output always constrained by this limit. Will reduce other motors if one is above limit
    var minCommand = 1000       // escAndServoConfig.mincommand     // Used to disarm motors
    var failsafeThrottle = 0
    var gpsType = 0
    var gpsBaudRate = 0
    var gpsUbxSbas = 0
    var multiwiiCurrentOutput = 0
    var rssiChannel = 0
    var placeholder2 = 0
    var magDeclination = 0.0
    var vbatScale = 0
    var vbatMinCellVoltage = 0.0
    var vbatMaxCellVoltage = 0.0
    var vbatWarningCellVoltage = 0.0
    
    private init() {
    }
    
    init(copyOf: Misc) {
        self.midRC = copyOf.midRC
        self.minThrottle = copyOf.minThrottle
        self.maxThrottle = copyOf.maxThrottle
        self.minCommand = copyOf.minCommand
        self.failsafeThrottle = copyOf.failsafeThrottle
        self.gpsType = copyOf.gpsType
        self.gpsBaudRate = copyOf.gpsBaudRate
        self.gpsUbxSbas = copyOf.gpsUbxSbas
        self.multiwiiCurrentOutput = copyOf.multiwiiCurrentOutput
        self.rssiChannel = copyOf.rssiChannel
        self.placeholder2 = copyOf.placeholder2
        self.magDeclination = copyOf.magDeclination
        self.vbatScale = copyOf.vbatScale
        self.vbatMinCellVoltage = copyOf.vbatMinCellVoltage
        self.vbatMaxCellVoltage = copyOf.vbatMaxCellVoltage
        self.vbatWarningCellVoltage = copyOf.vbatWarningCellVoltage
    }
}

class Configuration {
    static let theConfig = Configuration()
    
    // MSP_IDENT
    var version: String?
    var multiType: Int?
    var mspVersion: Int?
    var capability: UInt32?
    
    // MSP_API_VERSION
    var msgProtocolVersion: Int?
    var apiVersion: String?
    
    // MSP_BUILD_INFO
    var buildInfo: String?
    
    // MSP_FC_VARIANT
    var fcIdentifier: String?
    // MSP_FC_VERSION
    var fcVersion: String?
    
    // MSP_BOARD_INFO
    var boardInfo: String?
    var boardVersion: Int?
    
    // MSP_UID
    var uid: String?

    // MSP_STATUS
    var cycleTime: Int?
    var i2cError: Int?
    var activeSensors: Int?
    var mode: UInt32?
    var profile: Int?
    
    // MSP_ANALOG
    var voltage = 0.0
    var mAhDrawn = 0
    var rssi = 0
    var amperage = 0.0
    
    // MSP_ACC_TRIM / MSP_SET_ACC_TRIM
    // FIXME Move this to Settings or elsewhere
    var accelerometerTrimPitch = 0
    var accelerometerTrimRoll = 0

    func isGyroAndAccActive() -> Bool {
        return activeSensors != nil && activeSensors! & 1 > 0;
    }
    func isBarometerActive() -> Bool {
        return activeSensors != nil && activeSensors! & 2 > 0;
    }
    
    func isMagnetometerActive() -> Bool {
        return activeSensors != nil && activeSensors! & 4 > 0;
    }
    
    func isGPSActive() -> Bool {
        return activeSensors != nil && activeSensors! & 8 > 0;
    }
    
    func isSonarActive() -> Bool {
        return activeSensors != nil && activeSensors! & 16 > 0;
    }
    
    func isApiVersionAtLeast(version: String) -> Bool {
        if apiVersion == nil {
            return false
        }
        let currentVersion = apiVersion!.componentsSeparatedByString(".")
        let refVersion = version.componentsSeparatedByString(".")
        for var i = 0; ;i++ {
            if i >= currentVersion.count {
                return false
            }
            if i >= refVersion.count {
                return true
            }
            let curVersionPart = Int(currentVersion[i])
            let refVersionPart = Int(refVersion[i])
            
            if curVersionPart > refVersionPart {
                return true
            }
            if curVersionPart < refVersionPart {
                return false
            }
        }
    }
}

struct GpsSatQuality : OptionSetType {
    let rawValue: UInt8
    
    static let none = GpsSatQuality(rawValue: 0)
    static let svUsed = GpsSatQuality(rawValue: 1 << 0)         // Used for navigation
    static let diffCorr = GpsSatQuality(rawValue: 1 << 1)       // Differential correction data is available for this SV
    static let orbitAvail = GpsSatQuality(rawValue: 1 << 2)     // Orbit information is available for this SV (Ephemeris or Almanach)
    static let orbitEph = GpsSatQuality(rawValue: 1 << 3)       // Orbit information is Ephemeris
    static let unhealthy = GpsSatQuality(rawValue: 1 << 4)      // SV is unhealthy / shall not be used
    static let orbitAlm = GpsSatQuality(rawValue: 1 << 5)       // Orbit information is Almanac Plus
    static let orbitAop = GpsSatQuality(rawValue: 1 << 6)       // Orbit information is AssistNow Autonomous
    static let smoothed = GpsSatQuality(rawValue: 1 << 7)       // Carrier smoothed pseudorange used (see PPP for details)
    
}

struct Satellite {
    var channel: Int    // Channel number
    var svid: Int       // Satellite ID
    var quality: GpsSatQuality    // Bitfield Quality
    var cno: Int        // Carrier to Noise Ratio (Signal Strength 0-99 dB)
}

class GPSData {
    static let theGPSData = GPSData()
    
    var fix = false
    var latitude = 0.0
    var longitude = 0.0
    var altitude = 0
    var speed = 0
    var headingOverGround = 0
    var numSat = 0
    
    var distanceToHome = 0
    var directionToHome = 0
    var update = 0
    
    private var _satellites = [Satellite]()
    
    var satellites: [Satellite] {
        get {
            return [Satellite](_satellites)
        }
        set(value) {
            _satellites = value
        }
    }
}

class Receiver {
    static let theReceiver = Receiver()
    
    var activeChannels = 0
    var channels = [Int](count: 18, repeatedValue: 0)   // Length must match MAX_SUPPORTED_RC_CHANNEL_COUNT in cleanflight
    
    var map = [Int](count: 8, repeatedValue: 0)         // Length must match MAX_MAPPABLE_RX_INPUTS in cleanflight
}

class SensorData {
    static let theSensorData = SensorData()
    
    var accelerometerX = 0.0, accelerometerY = 0.0, accelerometerZ = 0.0
    var gyroscopeX = 0.0, gyroscopeY = 0.0, gyroscopeZ = 0.0
    var magnetometerX = 0.0, magnetometerY = 0.0, magnetometerZ = 0.0
    var altitude = 0.0
    var sonar = 0
    var kinematicsX = 0.0, kinematicsY = 0.0, kinematicsZ = 0.0
}

class MotorData {
    static let theMotorData = MotorData()
    
    var nMotors = 8
    var throttle = [Int](count: 8, repeatedValue: 0)
}

