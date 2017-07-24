//
//  Settings.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 12/06/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation
import Firebase

struct BaseFlightFeature : OptionSetType, DictionaryCoding {
    let rawValue: Int
    
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
    static let Blackbox  = BaseFlightFeature(rawValue: 1 << 19)             // Unused in BF 3.2 / CF 2
    static let ChannelForwarding  = BaseFlightFeature(rawValue: 1 << 20)
    static let Transponder  = BaseFlightFeature(rawValue: 1 << 21)
    // CF 1.14.2 only
    static let OSD_CF1_14_2  = BaseFlightFeature(rawValue: 1 << 22)
    // Betaflight / CF 2.0
    static let OSD  = BaseFlightFeature(rawValue: 1 << 18)
    static let AirMode  = BaseFlightFeature(rawValue: 1 << 22)
    static let SDCard  = BaseFlightFeature(rawValue: 1 << 23)               // Unused in BF 3.2 / CF 2
    static let VTX  = BaseFlightFeature(rawValue: 1 << 24)                  // Unused in BF 3.2 / CF 2
    static let RxSpi = BaseFlightFeature(rawValue: 1 << 25)                 // Not exposed?
    static let SoftSpi = BaseFlightFeature(rawValue: 1 << 26)               // exposed in INAV config only
    static let ESCSensor = BaseFlightFeature(rawValue: 1 << 27)
    // BF 3.1.7
    static let AntiGravity = BaseFlightFeature(rawValue: 1 << 28)
    // BF 3.2
    static let DynamicFilter = BaseFlightFeature(rawValue: 1 << 29)
    
    // INav
    static let SuperExpoRates  = BaseFlightFeature(rawValue: 1 << 23)   // Not exposed (old betaflight feature)
    static let PwmServoDriver  = BaseFlightFeature(rawValue: 1 << 27)   // Exposed
    static let PwmOutputEnable  = BaseFlightFeature(rawValue: 1 << 28)
    static let OSD_INav = BaseFlightFeature(rawValue: 1 << 29)
    
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
    case GPS_HOME = "GPS HOME"
    case GPS_HOLD = "GPS HOLD"
    case PASSTHRU = "PASSTHRU"
    case BEEPER = "BEEPER"
    case LEDMAX = "LEDMAX"
    case LEDLOW = "LEDLOW"
    case LLIGHTS = "LLIGHTS"
    case CALIB = "CALIB"
    case GOVERNOR = "GOVERNOR"
    case OSD_SW = "OSD SW"
    case OSD_DISABLE_SW = "OSD DISABLE SW"  // BF 3.2
    case TELEMETRY = "TELEMETRY"
    case GTUNE = "GTUNE"
    case SONAR = "SONAR"
    case SERVO1 = "SERVO1"
    case SERVO2 = "SERVO2"
    case SERVO3 = "SERVO3"
    case BLACKBOX = "BLACKBOX"
    case FAILSAFE = "FAILSAFE"
    case AIR = "AIR MODE"
    case ANTI_GRAVITY = "ANTI GRAVITY"
    case DISABLE_3D_SWITCH = "DISABLE 3D SWITCH"    // BF 3.0, 3.1
    case DISABLE_3D = "DISABLE 3D"                  // BF 3.2 (renamed)
    case FPV_ANGLE_MIX = "FPV ANGLE MIX"
    case BLACKBOX_ERASE = "BLACKBOX ERASE (>30s)"
    case CAMERA1 = "CAMERA CONTROL 1"
    case CAMERA2 = "CAMERA CONTROL 2"
    case CAMERA3 = "CAMERA CONTROL 3"
    case DSHOT_REVERSE_MOTORS = "DSHOT REVERSE MOTORS"  // BF 3.2
    // INav
    case NAV_WP = "NAV WP"
    case NAV_ALTHOLD = "NAV ALTHOLD"
    case NAV_POSHOLD = "NAV POSHOLD"
    case NAV_RTH = "NAV RTH"
    case HEADING_HOLD = "HEADING HOLD"
    case GCS_NAV = "GCS NAV"
    
    var spokenName: String {
        switch self {
        case .ARM:
            return "armed"
        case .ANGLE:
            return "angle mode"
        case .HORIZON:
            return "horizon mode"
        case .BARO:
            return "barometer mode"
        case .MAG, .HEADING_HOLD:
            return "heading mode"
        case .HEADFREE:
            return "head free mode"
        case .HEADADJ:
            return "head adjust mode"
        case .CAMSTAB:
            return "camera stabilization"
        case .CAMTRIG:
            return "camera trigger"
        case .GPS_HOME, .NAV_RTH:
            return "return to home mode"
        case .GPS_HOLD:
            return "GPS hold mode"
        case .PASSTHRU:
            return "Pass-through mode"
        case .BEEPER:
            return "beeper"
        case .LEDMAX:
            return "max led"
        case .LEDLOW:
            return "low led"
        case .LLIGHTS:
            return "led lights"
        case .CALIB:
            return "calibration mode"
        case .GOVERNOR:
            return "governor mode"
        case .OSD_SW, .OSD_DISABLE_SW:
            return "OSD disabled"
        case .TELEMETRY:
            return "telemetry"
        case .GTUNE:
            return "g-tune mode"
        case .SONAR:
            return "sonar mode"
        case .SERVO1:
            return "servo one mode"
        case .SERVO2:
            return "servo two mode"
        case .SERVO3:
            return "servo three mode"
        case .BLACKBOX:
            return "blackbox"
        case .FAILSAFE:
            return "failsafe mode"
        case .AIR:
            return "air mode"
        case .ANTI_GRAVITY:
            return "anti gravity"
        case .DISABLE_3D_SWITCH, .DISABLE_3D:
            return "3D disabled"
        case .FPV_ANGLE_MIX:
            return "FPV angle mix"
        case .BLACKBOX_ERASE:
            return "blackbox erase"
        case .NAV_WP:
            return "waypoint mode"
        case .NAV_ALTHOLD:
            return "altitude hold"
        case .NAV_POSHOLD:
            return "position hold"
        case .GCS_NAV:
            return "ground countrol station"
        case .CAMERA1:
            return "camera wi-fi"
        case .CAMERA2:
            return "camera power"
        case .CAMERA3:
            return "camera change mode"
        case .DSHOT_REVERSE_MOTORS:
            return "motors reversed"
        }
    }
    
    func impliedBy(other: Mode) -> Bool {
        if other == .FAILSAFE {
            return true
        }
        if self != .FAILSAFE && other == .ARM {
            return true
        }
        switch self {
        case .ANGLE:
            return other == .NAV_WP || other == .NAV_RTH || other == .NAV_POSHOLD
        case .NAV_ALTHOLD:
            return other == .NAV_WP || other == .NAV_RTH
        default:
            return false
        }
        
    }
    
    var altitudeHold: Bool {
        switch self {
        case .BARO, .NAV_ALTHOLD, .NAV_WP, .SONAR:
            return true
        default:
            return false
        }
    }
    
    var positionHold: Bool {
        switch self {
        case .GPS_HOLD, .NAV_POSHOLD:
            return true
        default:
            return false
        }
    }
    
    var headingHold: Bool {
        switch self {
        case .MAG, .HEADING_HOLD:
            return true
        default:
            return false
        }
    }
    
    var returnToHome: Bool {
        switch self {
        case .GPS_HOME, .NAV_RTH:
            return true
        default:
            return false
        }
    }
}

struct ModeRange : DictionaryCoding {
    var id = 0
    var auxChannelId = 0
    var start = 0
    var end = 0
    
    init(id: Int, auxChannelId: Int, start: Int, end: Int) {
        self.id = id
        self.auxChannelId = auxChannelId
        self.start = start
        self.end = end
    }
    
    // MARK: DictionaryCoding
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let id = dict["id"] as? Int,
            let auxChannelId = dict["auxChannelId"] as? Int,
            let start = dict["start"] as? Int,
            let end = dict["end"] as? Int
            else { return nil }
        
        self.init(id: id, auxChannelId: auxChannelId, start: start, end: end)
    }
    
    func toDict() -> NSDictionary {
        return [ "id": id, "auxChannelId": auxChannelId, "start": start, "end": end ]
    }
    
}

struct ServoConfig : DictionaryCoding {
    var minimumRC = 0
    var middleRC = 0
    var maximumRC = 0
    var rate = 0
    var minimumAngle = 0
    var maximumAngle = 0
    var rcChannel: Int?
    var reversedSources = 0
    
    init(minimumRC: Int, middleRC: Int, maximumRC: Int, rate: Int, minimumAngle: Int, maximumAngle: Int, rcChannel: Int?, reversedSources: Int) {
        self.minimumRC = minimumRC
        self.middleRC = middleRC
        self.maximumRC = maximumRC
        self.rate = rate
        self.minimumAngle = minimumAngle
        self.maximumAngle = maximumAngle
        self.rcChannel = rcChannel
        self.reversedSources = reversedSources
    }
    
    // MARK: DictionaryCoding
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let minimumRC = dict["minimumRC"] as? Int,
            let middleRC = dict["middleRC"] as? Int,
            let maximumRC = dict["maximumRC"] as? Int,
            let rate = dict["rate"] as? Int,
            let minimumAngle = dict["minimumAngle"] as? Int,
            let maximumAngle = dict["maximumAngle"] as? Int,
            let reversedSources = dict["reversedSources"] as? Int
            else { return nil }
        
        self.init(minimumRC: minimumRC, middleRC: middleRC, maximumRC: maximumRC, rate: rate, minimumAngle: minimumAngle, maximumAngle: maximumAngle, rcChannel: dict["rcChannel"] as? Int, reversedSources: reversedSources)
    }
    
    func toDict() -> NSDictionary {
        var dict = [ "minimumRC": minimumRC, "middleRC": middleRC, "maximumRC": maximumRC, "rate": rate, "minimumAngle": minimumAngle, "maximumAngle": maximumAngle, "reversedSources": reversedSources ]
        if rcChannel != nil {
            dict["rcChannel"] = rcChannel!
        }
        
        return dict
    }
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


/*
 enum MotorPwmProtocol : Int {
 case PWM = 0
 case Oneshot125 = 1
 case Oneshot42 = 2
 case Multishot = 3
 case Brushed = 4
 }
 */

class Settings : AutoCoded {
    var autoEncoding = [ "autoDisarmDelay", "disarmKillSwitch", "mixerConfiguration", "yawMotorsReversed", "boardAlignRoll", "boardAlignPitch", "boardAlignYaw", "boxNames", "boxIds",
                         "modeRangeSlots", "rcExpo", "yawExpo", "rcRate", "yawRate",
                         "rollSuperRate", "pitchSuperRate", "yawSuperRate", "throttleMid", "throttleExpo", "tpaRate", "tpaBreakpoint", "pidNames", "pidValues", "pidController", "serialRxType", "maxCheck", "midRC", "minCheck",
                         "spektrumSatBind",
                         "rxMinUsec", "rxMaxUsec", "rcInterpolation", "rcInterpolationInterval", "airmodeActivateThreshold", "rxSpiProtocol", "rxSpiId", "rxSpiChannelCount", "fpvCamAngleDegrees",
                         "failsafeDelay", "failsafeOffDelay", "failsafeThrottleLowDelay", "failsafeThrottle", "failsafeKillSwitch", "failsafeProcedure", "rxFailMode", "rxFailValue", "loopTime", "gyroSyncDenom",
                         "pidProcessDenom", "useUnsyncedPwm", "motorPwmProtocol", "motorPwmRate", "digitalIdleOffsetPercent", "gyroUses32KHz", "servoPwmRate", "syncLoopWithGyro", "gyroLowpassFrequency",
                         "dTermLowpassFrequency", "yawLowpassFrequency", "gyroNotchFrequency", "gyroNotchCutoff", "dTermNotchFrequency", "dTermNotchCutoff", "gyroNotchFrequency2", "gyroNotchCutoff2", "vbatPidCompensation",
                         "setpointRelaxRatio", "dTermSetpointWeight", "rateAccelLimit", "yawRateAccelLimit", "levelAngleLimit", "levelSensitivity", "accelerometerDisabled", "barometerDisabled", "magnetometerDisabled", "pitotDisabled", "sonarDisabled",
                         "rssiChannel",
                         "vbatScale", "vbatMinCellVoltage", "vbatMaxCellVoltage", "vbatWarningCellVoltage", "vbatMeterType", "vbatMeterId", "vbatResistorDividerValue", "vbatResistorDividerMultiplier", "batteryCapacity",
                         "voltageMeterSource", "currentMeterSource", "currentMeterId", "currentMeterType", "currentScale", "currentOffset", "minThrottle", "maxThrottle", "minCommand", "magDeclination",
                         "gpsType", "gpsUbxSbas", "gpsAutoConfig", "gpsAutoBaud", "rcDeadband", "yawDeadband", "altHoldDeadband", "throttle3dDeadband", "craftName"]
    static var theSettings = Settings()
    
    // MSP_ARMING_CONFIG / MSP_SET_ARMING_CONFIG
    var autoDisarmDelay = 5       // sec
    var disarmKillSwitch = false
    
    // MSP_MIXER_CONFIG
    var mixerConfiguration = 3              // Quad X by default
    var yawMotorsReversed = false           // BF 3.2
    
    // MSP_FEATURE
    var features = BaseFlightFeature.None {
        didSet(oldValue) {
            if oldValue != features {
                Analytics.logEvent("features", parameters: ["features" : features.rawValue])
            }
        }
    }
    
    // MSP_BOARD_ALIGNMENT
    var boardAlignRoll = 0
    var boardAlignPitch = 0
    var boardAlignYaw = 0
    
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
    var rcRate = 1.0        // pitch & roll rate
    var yawRate = 1.0       // yaw rate
    var rollSuperRate = 0.7
    var pitchSuperRate = 0.7
    var yawSuperRate = 0.7
    var throttleMid = 0.5
    var throttleExpo = 0.0
    var tpaRate = 0.0
    var tpaBreakpoint = 1500
    
    // MSP_PIDNAMES
    var pidNames: [String]?
    
    // MSP_PID
    var pidValues: [[Double]]?
    
    // MSP_PID_CONTROLLER
    var pidController = 0
    
    // MSP_SERVO_CONFIGURATIONS / MSP_SET_SERVO_CONFIGURATION
    var servoConfigs: [ServoConfig]?
    
    // MSP_CF_SERIAL_CONFIG / MSP_SET_CF_SERIAL_CONFIG
    var portConfigs: [PortConfig]?
    
    // MSP_RX_CONFIG / MSP_SET_RX_CONFIG
    var serialRxType = 0
    var maxCheck = 1100
    var midRC = 1500
    var minCheck = 1900
    var spektrumSatBind = 0
    var rxMinUsec = 885
    var rxMaxUsec = 2115
    // betaflight
    var rcInterpolation = 0
    var rcInterpolationInterval = 0
    var airmodeActivateThreshold = 0
    var rxSpiProtocol = 0
    var rxSpiId = 0
    var rxSpiChannelCount = 0
    var fpvCamAngleDegrees = 0
    
    // MSP_FAILSAFE_CONFIG / MSP_SET_FAILSAFE_CONFIG
    var failsafeDelay = 0.0         // Guard time for failsafe activation after signal loss (0 - 20 secs)
    var failsafeOffDelay = 0.0      // Time for landing before motor stop (0 - 20 secs)
    var failsafeThrottleLowDelay = 0.0  // If throtlle has been below minCheck for that much time, just disarm (0 - 30 secs)
    var failsafeThrottle = 0
    var failsafeKillSwitch = false  // If true, failsafe switch will disarm aircraft instantly instead of doing the failsafe procedure
    var failsafeProcedure = 0       // 0: land, 1: drop
    
    // MSP_RX_FAIL_CONFIG / MSP_SET_RX_FAIL_CONFIG
    var rxFailMode: [Int]?          // 0: Auto, 1: Hold, 2: Set
    var rxFailValue: [Int]?         // For mode 2 (Set)
    
    // MSP_LOOP_TIME / MSP_SET_LOOP_TIME
    var loopTime = 0
    
    // Betaflight
    
    // MSP_ADVANCED_CONFIG / MSP_SET_ADVANCED_CONFIG
    var gyroSyncDenom = 8
    var pidProcessDenom = 1
    var useUnsyncedPwm = false
    var motorPwmProtocol = 0        // PWM = 0, Oneshot125 = 1, Oneshot42 = 2, Multishot = 3, Brushed = 4, DShot150 = 5, DShot 300 = 6, DShot 600 = 7
    var motorPwmRate = 400
    var digitalIdleOffsetPercent = 0.0
    var gyroUses32KHz = false
    var servoPwmRate = 50           // INAV
    var syncLoopWithGyro = false    // INAV
    
    // MSP_FILTER_CONFIG / MSP_SET_FILTER_CONFIG
    var gyroLowpassFrequency = 90
    var dTermLowpassFrequency = 100
    var yawLowpassFrequency = 0
    var gyroNotchFrequency = 400
    var gyroNotchCutoff = 300
    var dTermNotchFrequency = 260
    var dTermNotchCutoff = 160
    var gyroNotchFrequency2 = 200
    var gyroNotchCutoff2 = 100
    
    // MSP_PID_ADVANCED / MSP_SET_PID_ADVANCED
    var vbatPidCompensation = false
    var setpointRelaxRatio = 100
    var dTermSetpointWeight = 60
    var rateAccelLimit = 0
    var yawRateAccelLimit = 100
    var levelAngleLimit = 55
    var levelSensitivity = 55
    
    // MSP_SENSOR_CONFIG / MSP_SET_SENSOR_CONFIG
    var accelerometerDisabled = false
    var barometerDisabled = true
    var magnetometerDisabled = true
    var pitotDisabled = false
    var sonarDisabled = false
    
    // MSP_RSSI_CONFIG / MSP_SET_RSSI_CONFIG
    var rssiChannel = 0
    
    // MSP_VOLTAGE_METER_CONFIG / MSP_BATTERY_CONFIG
    var vbatScale = 110
    var vbatMinCellVoltage = 3.3     // V
    var vbatMaxCellVoltage = 4.3     // V
    var vbatWarningCellVoltage = 3.5 // V
    var vbatMeterType = 0
    
    var vbatMeterId = 0
    var vbatResistorDividerValue = 10
    var vbatResistorDividerMultiplier = 1
    var batteryCapacity = 0         // mAh
    var voltageMeterSource = 0      // 0=none, 1=ADC, 2=ESC
    var currentMeterSource = 0      // 0=none, 1=ADC, 3=virtual, 4=ESC
    
    // MSP_CURRENT_METER_CONFIG
    var currentMeterId = 0          // 0=none, 10=battery 1, 50=ESC combined, 60=ESC 1, 61=ESC 2, ..., 71=ESC 12, 80=virtual 1, 90=MSP 1
    var currentMeterType = 0        // <1.35: 0=none, 1=ADC, 2=virtual
                                    // >=1.31:                     ... , 3=ESC
                                    // >= 1.35: 0=virtual, 1=ADC, 2=ESC, 3=MSP
    var currentScale = 400
    var currentOffset = 0
    
    // MSP_MOTOR_CONFIG (CF 2.0) or MSP_MISC
    var minThrottle = 1150      // escAndServoConfig.minthrottle    // Used when motors are armed in !MOTOR_STOP
    var maxThrottle = 1850      // escAndServoConfig.maxthrottle    // Motor output always constrained by this limit. Will reduce other motors if one is above limit
    var minCommand = 1000       // escAndServoConfig.mincommand     // Used to disarm motors

    // MSP_COMPASS_CONFIG (CF 2.0) or MSP_MISC
    var magDeclination = 0.0         // degree

    // MSP_GPS_CONFIG (CF 2.0) or MSP_MISC
    var gpsType = 0
    var gpsUbxSbas = 0
    var gpsAutoConfig = false
    var gpsAutoBaud = false

    // MSP_RC_DEADBAND
    var rcDeadband = 0
    var yawDeadband = 0
    var altHoldDeadband = 0
    var throttle3dDeadband = 0
    
    // MSP_NAME
    var craftName = ""
    
    override init() {
        super.init()
    }

    init(copyOf: Settings) {
        self.autoDisarmDelay = copyOf.autoDisarmDelay
        self.disarmKillSwitch = copyOf.disarmKillSwitch
        
        self.mixerConfiguration = copyOf.mixerConfiguration
        self.yawMotorsReversed = copyOf.yawMotorsReversed
        
        self.features = copyOf.features
        self.serialRxType = copyOf.serialRxType
        self.boardAlignRoll = copyOf.boardAlignRoll
        self.boardAlignPitch = copyOf.boardAlignPitch
        self.boardAlignYaw = copyOf.boardAlignYaw
        
        self.boxNames = copyOf.boxNames
        self.boxIds = copyOf.boxIds
        self.modeRanges = copyOf.modeRanges
        self.modeRangeSlots = copyOf.modeRangeSlots
        
        self.rcExpo = copyOf.rcExpo
        self.yawExpo = copyOf.yawExpo
        self.yawRate = copyOf.yawRate
        self.rcRate = copyOf.rcRate
        self.rollSuperRate = copyOf.rollSuperRate
        self.pitchSuperRate = copyOf.pitchSuperRate
        self.yawSuperRate = copyOf.yawSuperRate
        self.tpaRate = copyOf.tpaRate
        self.throttleMid = copyOf.throttleMid
        self.throttleExpo = copyOf.throttleExpo
        self.tpaBreakpoint = copyOf.tpaBreakpoint
        
        self.pidNames = copyOf.pidNames
        self.pidValues = copyOf.pidValues
        self.pidController = copyOf.pidController
        
        self.servoConfigs = copyOf.servoConfigs
        self.portConfigs = copyOf.portConfigs
        
        self.maxCheck = copyOf.maxCheck
        self.midRC = copyOf.midRC
        self.minCheck = copyOf.minCheck
        self.spektrumSatBind = copyOf.spektrumSatBind
        self.rxMinUsec = copyOf.rxMinUsec
        self.rxMaxUsec = copyOf.rxMaxUsec
        self.rcInterpolation = copyOf.rcInterpolation
        self.rcInterpolationInterval = copyOf.rcInterpolationInterval
        self.airmodeActivateThreshold = copyOf.airmodeActivateThreshold
        self.rxSpiProtocol = copyOf.rxSpiProtocol
        self.rxSpiId = copyOf.rxSpiId
        self.rxSpiChannelCount = copyOf.rxSpiChannelCount
        self.fpvCamAngleDegrees = copyOf.fpvCamAngleDegrees

        self.failsafeDelay = copyOf.failsafeDelay
        self.failsafeOffDelay = copyOf.failsafeOffDelay
        self.failsafeThrottleLowDelay = copyOf.failsafeThrottleLowDelay
        self.failsafeThrottle = copyOf.failsafeThrottle
        self.failsafeKillSwitch = copyOf.failsafeKillSwitch
        self.failsafeProcedure = copyOf.failsafeProcedure
        
        self.rxFailMode = copyOf.rxFailMode
        self.rxFailValue = copyOf.rxFailValue
        
        self.loopTime = copyOf.loopTime
        self.gyroSyncDenom = copyOf.gyroSyncDenom
        self.pidProcessDenom = copyOf.pidProcessDenom
        self.useUnsyncedPwm = copyOf.useUnsyncedPwm
        self.motorPwmProtocol = copyOf.motorPwmProtocol
        self.motorPwmRate = copyOf.motorPwmRate
        self.digitalIdleOffsetPercent = copyOf.digitalIdleOffsetPercent
        self.gyroUses32KHz = copyOf.gyroUses32KHz
        self.servoPwmRate = copyOf.servoPwmRate
        self.syncLoopWithGyro = copyOf.syncLoopWithGyro
        
        self.gyroLowpassFrequency = copyOf.gyroLowpassFrequency
        self.dTermLowpassFrequency = copyOf.dTermLowpassFrequency
        self.yawLowpassFrequency = copyOf.yawLowpassFrequency
        self.gyroNotchFrequency = copyOf.gyroNotchFrequency
        self.gyroNotchCutoff = copyOf.gyroNotchCutoff
        self.dTermNotchFrequency = copyOf.dTermNotchFrequency
        self.dTermNotchCutoff = copyOf.dTermNotchCutoff
        self.gyroNotchFrequency2 = copyOf.gyroNotchFrequency2
        self.gyroNotchCutoff2 = copyOf.gyroNotchCutoff2
        
        self.vbatPidCompensation = copyOf.vbatPidCompensation
        self.setpointRelaxRatio = copyOf.setpointRelaxRatio
        self.rateAccelLimit = copyOf.rateAccelLimit
        self.yawRateAccelLimit = copyOf.yawRateAccelLimit
        self.levelAngleLimit = copyOf.levelAngleLimit
        self.levelSensitivity = copyOf.levelSensitivity

        self.accelerometerDisabled = copyOf.accelerometerDisabled
        self.barometerDisabled = copyOf.barometerDisabled
        self.magnetometerDisabled = copyOf.magnetometerDisabled
        self.pitotDisabled = copyOf.pitotDisabled
        self.sonarDisabled = copyOf.sonarDisabled
        
        self.rssiChannel = copyOf.rssiChannel
        
        self.vbatScale = copyOf.vbatScale
        self.vbatMinCellVoltage = copyOf.vbatMinCellVoltage
        self.vbatMaxCellVoltage = copyOf.vbatMaxCellVoltage
        self.vbatWarningCellVoltage = copyOf.vbatWarningCellVoltage
        self.vbatMeterType = copyOf.vbatMeterType
        self.vbatMeterId = copyOf.vbatMeterId
        self.vbatResistorDividerValue = copyOf.vbatResistorDividerValue
        self.vbatResistorDividerMultiplier = copyOf.vbatResistorDividerMultiplier
        self.batteryCapacity = copyOf.batteryCapacity
        self.voltageMeterSource = copyOf.voltageMeterSource
        self.currentMeterSource = copyOf.currentMeterSource

        self.currentMeterId = copyOf.currentMeterId
        self.currentMeterType = copyOf.currentMeterType
        self.currentScale = copyOf.currentScale
        self.currentOffset = copyOf.currentOffset

        self.minThrottle = copyOf.minThrottle
        self.maxThrottle = copyOf.maxThrottle
        self.minCommand = copyOf.minCommand

        self.magDeclination = copyOf.magDeclination
        
        self.gpsType = copyOf.gpsType
        self.gpsUbxSbas = copyOf.gpsUbxSbas
        self.gpsAutoConfig = copyOf.gpsAutoConfig
        self.gpsAutoBaud = copyOf.gpsAutoBaud
        
        self.rcDeadband = copyOf.rcDeadband
        self.yawDeadband = copyOf.yawDeadband
        self.altHoldDeadband = copyOf.altHoldDeadband
        self.throttle3dDeadband = copyOf.throttle3dDeadband

        self.craftName = copyOf.craftName
        
        super.init()
    }
    
    func isModeOn(mode: Mode, forStatus status: Int) -> Bool {
        if boxNames == nil {
            return false
        }
        for (i, m) in boxNames!.enumerate() {
            if (mode.rawValue == m) {
                return status & (1 << i) != 0
            }
        }
        return false
    }
    
    var armed: Bool {
        return isModeOn(.ARM, forStatus: Configuration.theConfig.mode)
    }
    
    var altitudeHoldMode: Bool {
        return hasModeWithCondition({ $0.altitudeHold })
    }
    
    var positionHoldMode: Bool {
        return hasModeWithCondition({ $0.positionHold })
    }
    
    var headingHoldMode: Bool {
        return hasModeWithCondition({ $0.headingHold })
    }
    
    var returnToHomeMode: Bool {
        return hasModeWithCondition({ $0.returnToHome })
    }
    
    private func hasModeWithCondition(condition: (mode: Mode) -> Bool) -> Bool {
        if boxNames == nil {
            return false
        }
        let status = Configuration.theConfig.mode
        for (i, m) in boxNames!.enumerate() {
            if status & (1 << i) != 0 {
                if let mode = Mode(rawValue: m) where condition(mode: mode) {
                    return true
                }
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
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        features = BaseFlightFeature(fromDict: aDecoder.decodeObjectForKey("features") as? NSDictionary)!
        
        if let modeRangesDicts = aDecoder.decodeObjectForKey("modeRanges") as? [NSDictionary] {
            modeRanges = [ModeRange]()
            for dict in modeRangesDicts {
                modeRanges!.append(ModeRange(fromDict: dict)!)
            }
        }
        
        if let servoConfigsDicts = aDecoder.decodeObjectForKey("servoConfigs") as? [NSDictionary] {
            servoConfigs = [ServoConfig]()
            for dict in servoConfigsDicts {
                servoConfigs!.append(ServoConfig(fromDict: dict)!)
            }
        }
        
        if let portConfigsDicts = aDecoder.decodeObjectForKey("portConfigs") as? [NSDictionary] {
            portConfigs = [PortConfig]()
            for dict in portConfigsDicts {
                portConfigs!.append(PortConfig(fromDict: dict)!)
            }
        }
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        
        aCoder.encodeObject(features.toDict(), forKey: "features")
        
        var modeRangesDicts: [NSDictionary]?
        if modeRanges != nil {
            modeRangesDicts = [NSDictionary]()
            for modeRange in modeRanges! {
                modeRangesDicts?.append(modeRange.toDict())
            }
        }
        aCoder.encodeObject(modeRangesDicts, forKey: "modeRanges")
        
        var servoConfigsDicts: [NSDictionary]?
        if servoConfigs != nil {
            servoConfigsDicts = [NSDictionary]()
            for servoConfig in servoConfigs! {
                servoConfigsDicts?.append(servoConfig.toDict())
            }
        }
        aCoder.encodeObject(servoConfigsDicts, forKey: "servoConfigs")
        
        var portConfigsDicts: [NSDictionary]?
        if portConfigs != nil {
            portConfigsDicts = [NSDictionary]()
            for portConfig in portConfigs! {
                portConfigsDicts?.append(portConfig.toDict())
            }
        }
        aCoder.encodeObject(portConfigsDicts, forKey: "portConfigs")
    }
}
