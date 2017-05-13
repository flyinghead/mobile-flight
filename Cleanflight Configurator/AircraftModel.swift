//
//  AircraftModel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation
import MapKit

protocol DictionaryCoding {
    func toDict() -> NSDictionary
    init?(fromDict: NSDictionary?)
}

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
    static let Blackbox  = BaseFlightFeature(rawValue: 1 << 19)
    static let ChannelForwarding  = BaseFlightFeature(rawValue: 1 << 20)
    static let Transponder  = BaseFlightFeature(rawValue: 1 << 21)

    // Betaflight / CF 2.0
    static let OSD  = BaseFlightFeature(rawValue: 1 << 18)
    static let AirMode  = BaseFlightFeature(rawValue: 1 << 22)
    static let SDCard  = BaseFlightFeature(rawValue: 1 << 23)
    static let VTX  = BaseFlightFeature(rawValue: 1 << 24)      // Not exposed in BF?
    static let RxSpi = BaseFlightFeature(rawValue: 1 << 25)     // Not exposed?
    static let SoftSpi = BaseFlightFeature(rawValue: 1 << 26)   // exposed in INAV only?
    static let ESCSensor = BaseFlightFeature(rawValue: 1 << 27)
    static let AntiGravity = BaseFlightFeature(rawValue: 1 << 28) // Not exposed?

    // INav
    static let SuperExpoRates  = BaseFlightFeature(rawValue: 1 << 23)   // Not exposed?
    static let PwmServoDriver  = BaseFlightFeature(rawValue: 1 << 27)
    static let PwmOutputEnable  = BaseFlightFeature(rawValue: 1 << 27)
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
    case GPSHOME = "GPS HOME"
    case GPSHOLD = "GPS HOLD"
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
    case AIR = "AIR MODE"
    case ANTIGRAVITY = "ANTI GRAVITY"
    case DISABLE3DSWITCH = "DISABLE 3D SWITCH"
    case FPVANGLEMIX = "FPV ANGLE MIX"
    case BLACKBOXERASE = "BLACKBOX ERASE (>30s)"
    // INav
    case NAVWP = "NAV WP"
    
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
        case .MAG:
            return "heading mode"
        case .HEADFREE:
            return "head free mode"
        case .HEADADJ:
            return "head adjust mode"
        case .CAMSTAB:
            return "camera stabilization"
        case .CAMTRIG:
            return "camera trigger"
        case .GPSHOME:
            return "return to home mode"
        case .GPSHOLD:
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
        case .OSDSW:
            return "on-screen display"
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
        case .ANTIGRAVITY:
            return "anti gravity"
        case .DISABLE3DSWITCH:
            return "disable 3D switch"
        case .FPVANGLEMIX:
            return "FPV angle mix"
        case .BLACKBOXERASE:
            return "blackbox erase"
        case .NAVWP:
            return "waypoint mode"
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

struct PortFunction : OptionSetType, DictionaryCoding {
    let rawValue: Int
    
    static let None = PortFunction(rawValue: 0)
    static let MSP  = PortFunction(rawValue: 1 << 0)
    static let GPS = PortFunction(rawValue: 1 << 1)
    static let TelemetryFrsky  = PortFunction(rawValue: 1 << 2)
    static let TelemetryHott  = PortFunction(rawValue: 1 << 3)
    static let TelemetryLTM  = PortFunction(rawValue: 1 << 4)           // MSP telemetry for CF < 1.11, LTM telemetry for CF >= 1.11
    static let TelemetrySmartPort  = PortFunction(rawValue: 1 << 5)
    static let RxSerial  = PortFunction(rawValue: 1 << 6)
    static let Blackbox  = PortFunction(rawValue: 1 << 7)
    static let TelemetryMAVLinkOld  = PortFunction(rawValue: 1 << 8)
    static let TelemetryMAVLink  = PortFunction(rawValue: 1 << 9)
    static let MSPClient  = PortFunction(rawValue: 1 << 9)
    static let ESCSensor = PortFunction(rawValue: 1 << 10)
    static let VTXSmartAudio = PortFunction(rawValue: 1 << 11)
    static let TelemetryIBus  = PortFunction(rawValue: 1 << 12)
    static let VTXTramp  = PortFunction(rawValue: 1 << 13)
    
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

enum PortIdentifier {
    enum Internal : Int {
        case None = -1
        case USART1 = 0
        case USART2 = 1
        case USART3 = 2
        case USART4 = 3
        case USB_VCP = 20
        case SoftSerial1 = 30
        case SoftSerial2 = 31
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
        case .Known(let intern):
            return intern.rawValue
        case .Unknown(let value):
            return value
        }
    }

    var name: String {
        switch self {
        case .Known(let intern):
            switch intern {
            case .None:
                return "None"
            case .USART1:
                return "UART1"
            case .USART2:
                return "UART2"
            case .USART3:
                return "UART3"
            case .USART4:
                return "UART4"
            case .USB_VCP:
                return "USB"
            case .SoftSerial1:
                return "SOFTSERIAL1"
            case .SoftSerial2:
                return "SOFTSERIAL2"
            }
        case .Unknown(let value):
            return String(format: "PORT %d", value)
        }
    }
}

enum BaudRate : Equatable {
    case Auto
    case Baud1200
    case Baud2400
    case Baud4800
    case Baud9600
    case Baud19200
    case Baud38400
    case Baud57600
    case Baud115200
    case Baud230400
    case Baud250000
    case Baud400000
    case Baud460800
    case Baud500000
    case Baud921600
    case Baud1000000
    case Baud1500000
    case Baud2000000
    case Baud2470000
    case Unknown(value: Int)
    
    init(value: Int) {
        let values = BaudRate.values()
        if value >= 0 && value < values.count {
            self = values[value]
        } else {
            self = .Unknown(value: value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .Unknown(let value):
            return value
        default:
            let values = BaudRate.values()
            return values.indexOf(self) ?? 0
        }
    }
    
    var description: String {
        switch self {
        case Auto:
            return "Auto"
        case Baud1200:
            return "1200"
        case Baud2400:
            return "2400"
        case Baud4800:
            return "4800"
        case Baud9600:
            return "9600"
        case Baud19200:
            return "19200"
        case Baud38400:
            return "38400"
        case Baud57600:
            return "57600"
        case Baud115200:
            return "115200"
        case Baud230400:
            return "230400"
        case Baud250000:
            return "250000"
        case Baud400000:
            return "400000"
        case Baud460800:
            return "460800"
        case Baud500000:
            return "500000"
        case Baud921600:
            return "921600"
        case Baud1000000:
            return "1000000"
        case Baud1500000:
            return "1500000"
        case Baud2000000:
            return "2000000"
        case Baud2470000:
            return "2470000"
        case Unknown(let value):
            return String(format: "Unknown (%d)", value)
        }
    }
    
    static let inav17Values = [Auto, Baud1200, Baud2400, Baud4800, Baud9600, Baud19200, Baud38400, Baud57600, Baud115200, Baud230400, Baud250000, Baud460800, Baud921600]
    static let bfValues = [Auto, Baud9600, Baud19200, Baud38400, Baud57600, Baud115200, Baud230400, Baud250000, Baud400000, Baud460800, Baud500000, Baud921600, Baud1000000, Baud1500000, Baud2000000, Baud2470000]
    static let defaultValues =  [Auto, Baud9600, Baud19200, Baud38400, Baud57600, Baud115200, Baud230400, Baud250000]

    static func values() -> [BaudRate] {
        let config = Configuration.theConfig
        if config.isINav && config.isApiVersionAtLeast("1.25") {    // INav 1.7
            return inav17Values
        }
        else if config.isApiVersionAtLeast("1.31") {    // BF3.1, CF2
            return bfValues
        }
        else {
            return defaultValues
        }
    }
}

func ==(lhs: BaudRate, rhs: BaudRate) -> Bool {
    return lhs.description == rhs.description
}

struct PortConfig : DictionaryCoding {
    var portIdentifier = PortIdentifier.Known(.None)
    var functions = PortFunction.None
    var mspBaudRate = BaudRate.Auto
    var gpsBaudRate = BaudRate.Auto
    var telemetryBaudRate = BaudRate.Auto
    var blackboxBaudRate = BaudRate.Auto
    
    init(portIdentifier: PortIdentifier, functions: PortFunction, mspBaudRate: BaudRate, gpsBaudRate: BaudRate, telemetryBaudRate: BaudRate, blackboxBaudRate: BaudRate) {
        self.portIdentifier = portIdentifier
        self.functions = functions
        self.mspBaudRate = mspBaudRate
        self.gpsBaudRate = gpsBaudRate
        self.telemetryBaudRate = telemetryBaudRate
        self.blackboxBaudRate = blackboxBaudRate
    }
    
    // MARK: DictionaryCoding
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let portIdentifier = dict["portIdentifier"] as? Int,
            let functions = dict["functions"] as? Int,
            let mspBaudRate = dict["mspBaudRate"] as? Int,
            let gpsBaudRate = dict["gpsBaudRate"] as? Int,
            let telemetryBaudRate = dict["telemetryBaudRate"] as? Int,
            let blackboxBaudRate = dict["blackboxBaudRate"] as? Int
            else { return nil }
        
        self.init(portIdentifier: PortIdentifier(value: portIdentifier), functions: PortFunction(rawValue: functions), mspBaudRate: BaudRate(value: mspBaudRate), gpsBaudRate: BaudRate(value: gpsBaudRate), telemetryBaudRate: BaudRate(value: telemetryBaudRate), blackboxBaudRate: BaudRate(value: blackboxBaudRate))
    }
    
    func toDict() -> NSDictionary {
        return [ "portIdentifier": portIdentifier.intValue, "functions": functions.rawValue, "mspBaudRate": mspBaudRate.intValue, "gpsBaudRate": gpsBaudRate.intValue, "telemetryBaudRate": telemetryBaudRate.intValue, "blackboxBaudRate": blackboxBaudRate.intValue ]
    }
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
    var autoEncoding = [ "autoDisarmDelay", "disarmKillSwitch", "mixerConfiguration", "boardAlignRoll", "boardAlignPitch", "boardAlignYaw", "boxNames", "boxIds", "modeRangeSlots", "rcExpo", "yawExpo", "rcRate", "yawRate",
        "rollSuperRate", "pitchSuperRate", "yawSuperRate", "throttleMid", "throttleExpo", "tpaRate", "tpaBreakpoint", "pidNames", "pidValues", "pidController", "serialRxType", "maxCheck", "midRC", "minCheck",
        "spektrumSatBind",
        "rxMinUsec", "rxMaxUsec", "rcInterpolation", "rcInterpolationInterval", "airmodeActivateThreshold", "rxSpiProtocol", "rxSpiId", "rxSpiChannelCount", "fpvCamAngleDegrees",
        "failsafeDelay", "failsafeOffDelay", "failsafeThrottleLowDelay", "failsafeThrottle", "failsafeKillSwitch", "failsafeProcedure", "rxFailMode", "rxFailValue", "loopTime", "gyroSyncDenom",
        "pidProcessDenom", "useUnsyncedPwm", "motorPwmProtocol", "motorPwmRate", "digitalIdleOffsetPercent", "gyroUses32KHz", "gyroLowpassFrequency",
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
    
    // MSP_FEATURE
    var features = BaseFlightFeature.None
    
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
    var rcRate = 0.0        // pitch & roll rate
    var yawRate = 0.0       // yaw rate
    var rollSuperRate = 0.0
    var pitchSuperRate = 0.0
    var yawSuperRate = 0.0
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
    
    // MSP_[PID_]ADVANCED_CONFIG / MSP_SET_[PID_]ADVANCED_CONFIG
    var gyroSyncDenom = 0
    var pidProcessDenom = 0
    var useUnsyncedPwm = false
    var motorPwmProtocol = 0        // PWM = 0, Oneshot125 = 1, Oneshot42 = 2, Multishot = 3, Brushed = 4, DShot150 = 5, DShot 300 = 6, DShot 600 = 7
    var motorPwmRate = 0
    var digitalIdleOffsetPercent = 0.0
    var gyroUses32KHz = false
    
    // MSP_FILTER_CONFIG / MSP_SET_FILTER_CONFIG
    var gyroLowpassFrequency = 0
    var dTermLowpassFrequency = 0
    var yawLowpassFrequency = 0
    var gyroNotchFrequency = 0
    var gyroNotchCutoff = 0
    var dTermNotchFrequency = 0
    var dTermNotchCutoff = 0
    var gyroNotchFrequency2 = 0
    var gyroNotchCutoff2 = 0
    
    // MSP_PID_ADVANCED / MSP_SET_PID_ADVANCED
    var vbatPidCompensation = false
    var setpointRelaxRatio = 0
    var dTermSetpointWeight = 0
    var rateAccelLimit = 0
    var yawRateAccelLimit = 0
    var levelAngleLimit = 0
    var levelSensitivity = 0
    
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
    var vbatMinCellVoltage = 0.0     // V
    var vbatMaxCellVoltage = 0.0     // V
    var vbatWarningCellVoltage = 0.0 // V
    var vbatMeterType = 0
    
    var vbatMeterId = 0
    var vbatResistorDividerValue = 10
    var vbatResistorDividerMultiplier = 1
    var batteryCapacity = 0
    var voltageMeterSource = 0
    var currentMeterSource = 0
    
    // MSP_CURRENT_METER_CONFIG
    var currentMeterId = 0
    var currentMeterType = 0
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
    
    private override init() {
        super.init()
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

class Misc : AutoCoded {
    var autoEncoding = [ "accelerometerTrimPitch", "accelerometerTrimRoll" ]
    static var theMisc = Misc()
    
    // MSP_ACC_TRIM / MSP_SET_ACC_TRIM
    var accelerometerTrimPitch = 0
    var accelerometerTrimRoll = 0
    
    private override init() {
        super.init()
    }
    
    init(copyOf: Misc) {
        self.accelerometerTrimPitch = copyOf.accelerometerTrimPitch
        self.accelerometerTrimRoll = copyOf.accelerometerTrimRoll
        
        super.init()
    }
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class Configuration : AutoCoded {
    var autoEncoding = [ "version", "mspVersion", "capability", "msgProtocolVersion", "apiVersion", "buildInfo", "fcIdentifier", "fcVersion", "boardInfo", "boardVersion", "uid", "cycleTime", "i2cError", "activeSensors", "mode", "profile", "systemLoad", "rateProfile", "armingFlags", "accCalibAxis", "voltage", "mAhDrawn", "rssi", "amperage", "batteryCells", "maxAmperage", "btRssi" ]
    static var theConfig = Configuration()
    
    // MSP_IDENT
    var version: String?
    var mspVersion = 0
    var capability = 0
    
    // MSP_API_VERSION
    var msgProtocolVersion = 0
    var apiVersion: String?
    
    // MSP_BUILD_INFO
    var buildInfo: String?
    
    // MSP_FC_VARIANT
    var fcIdentifier: String?
    // MSP_FC_VERSION
    var fcVersion: String?
    
    // MSP_BOARD_INFO
    var boardInfo: String?
    var boardVersion = 0
    
    // MSP_UID
    var uid: String?

    // MSP_STATUS[_EX]
    var cycleTime = 0     // microsecond?
    var i2cError = 0
    var activeSensors = 0
    var mode = 0 {
        didSet {
            let modeChanges = oldValue ^ mode
            if !_loading && modeChanges != 0 && userDefaultEnabled(.FlightModeAlert) {
                guard let boxNames = Settings.theSettings.boxNames else {
                    return
                }
                for (i, m) in boxNames.enumerate() {
                    if modeChanges & (1 << i) != 0 {
                        // Mode has changed
                        guard let flightMode = Mode(rawValue: m) else {
                            continue
                        }
                        var speech = flightMode.spokenName
                        if mode & (1 << i) != 0 {
                            // Activated
                            if flightMode == .ARM {
                                speech = "motors armed"
                            } else {
                                speech = speech + " activated"
                            }
                        } else {
                            // Off
                            if flightMode == .ARM {
                                speech = "disarmed"
                            } else {
                                speech = speech + " off"
                            }
                        }
                        VoiceMessage.theVoice.speak(speech)
                    }
                }
            }
        }
    }
    var profile = 0
    var systemLoad = 0      // 0-100% in MSP_STATUS_EX
    var rateProfile = 0     // Only exposed (MSP_STATUS_EX) and settable (MSP_SELECT_SETTING) with betaflight
    // INav
    var armingFlags = 0
    var accCalibAxis = 0

    // MSP_ANALOG
    var voltage = 0.0 {      // V
        didSet {
            if voltage > 0 && batteryCells == 0 && Settings.theSettings.features.contains(.VBat) {
                let vbatMaxCellVoltage = Settings.theSettings.vbatMaxCellVoltage
                if vbatMaxCellVoltage > 0 {
                    batteryCells = Int(voltage / vbatMaxCellVoltage + 1)
                }
            }
        }
    }
    var mAhDrawn = 0
    var rssi = 0            // %
    var amperage = 0.0 {      // A
        didSet {
            maxAmperage = max(maxAmperage, amperage)
        }
    }
    
    // MSP_SIKRADIO
    var rxerrors = 0
    var fixedErrors = 0
    var txBuffer = 0
    var sikRssi = 0         // 0-255 0.5db per bit. 18 ~ -120db and 225 ~ 0db
    var sikRemoteRssi = 0   // 0-255
    var noise = 0           // 0-255
    var remoteNoise = 0     // 0-255
    
    // Local
    var batteryCells = 0
    var maxAmperage = 0.0
    var btRssi = 0          // %
    
    private var _localSNR = 0.0
    private var _remoteSNR = 0.0
    private var lastLocalSNRTime: NSDate?
    private var lastRemoteSNRTime: NSDate?
    
    private var _loading = true
    
    private override init() {
        super.init()
        _loading = false
    }
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _loading = false
    }
    // MARK:
    
    func isGyroAndAccActive() -> Bool {
        return activeSensors & 1 > 0;
    }
    func isBarometerActive() -> Bool {
        return activeSensors & 2 > 0;
    }
    
    func isMagnetometerActive() -> Bool {
        return activeSensors & 4 > 0;
    }
    
    func isGPSActive() -> Bool {
        return activeSensors & 8 > 0;
    }
    
    func isSonarActive() -> Bool {
        return activeSensors & 16 > 0;
    }
    
    func isApiVersionAtLeast(version: String) -> Bool {
        if apiVersion == nil {
            return false
        }
        let currentVersion = apiVersion!.componentsSeparatedByString(".")
        let refVersion = version.componentsSeparatedByString(".")
        var i = 0
        while true {
            if i >= currentVersion.count {
                if i >= refVersion.count {
                    // Same version
                    return true
                }
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
            i += 1
        }
    }
    
    override func setValue(value: AnyObject?, forUndefinedKey key: String) {
        if key == "accelerometerTrimPitch" || key == "accelerometerTrimRoll" {
            // These were moved to Misc. Ignore them.
            return
        }
        super.setValue(value, forUndefinedKey: key)
    }
    
    var localSNR: Double {
        if lastLocalSNRTime == nil || -lastLocalSNRTime!.timeIntervalSinceNow >= 1 {
            lastLocalSNRTime = NSDate()
            _localSNR = (-120 + Double(sikRssi - noise) * 120 / 207) / 2 + _localSNR / 2
        }
        return _localSNR
    }

    var remoteSNR: Double {
        if lastRemoteSNRTime == nil || -lastRemoteSNRTime!.timeIntervalSinceNow >= 1 {
            lastRemoteSNRTime = NSDate()
            _remoteSNR = (-120 + Double(sikRemoteRssi - remoteNoise) * 120 / 207) / 2 + _remoteSNR / 2
        }
        return _remoteSNR
    }
    
    var sikQuality: Int {
        let snr = min(localSNR, remoteSNR)
        
        return Int(round(constrain(120 + snr, min: 0, max: 100)))
    }
    
    var isBetaflight: Bool {
        return fcIdentifier == "BTFL"
    }
    
    var isINav: Bool {
        return fcIdentifier == "INAV"
    }
}

struct GpsSatQuality : OptionSetType, DictionaryCoding {
    let rawValue: Int
    
    static let none = GpsSatQuality(rawValue: 0)
    static let svUsed = GpsSatQuality(rawValue: 1 << 0)         // Used for navigation
    static let diffCorr = GpsSatQuality(rawValue: 1 << 1)       // Differential correction data is available for this SV
    static let orbitAvail = GpsSatQuality(rawValue: 1 << 2)     // Orbit information is available for this SV (Ephemeris or Almanach)
    static let orbitEph = GpsSatQuality(rawValue: 1 << 3)       // Orbit information is Ephemeris
    static let unhealthy = GpsSatQuality(rawValue: 1 << 4)      // SV is unhealthy / shall not be used
    static let orbitAlm = GpsSatQuality(rawValue: 1 << 5)       // Orbit information is Almanac Plus
    static let orbitAop = GpsSatQuality(rawValue: 1 << 6)       // Orbit information is AssistNow Autonomous
    static let smoothed = GpsSatQuality(rawValue: 1 << 7)       // Carrier smoothed pseudorange used (see PPP for details)
    
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

struct Satellite : DictionaryCoding {
    var channel: Int    // Channel number
    var svid: Int       // Satellite ID
    var quality: GpsSatQuality    // Bitfield Quality
    var cno: Int        // Carrier to Noise Ratio (Signal Strength 0-99 dB)

    init(channel: Int, svid: Int, quality: GpsSatQuality, cno: Int) {
        self.channel = channel
        self.svid = svid
        self.quality = quality
        self.cno = cno
    }
    
    // MARK: DictionaryCoding
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let channel = dict["channel"] as? Int,
            let svid = dict["svid"] as? Int,
            let quality = dict["quality"] as? NSDictionary,
            let cno = dict["cno"] as? Int
            else { return nil }
        
        self.init(channel: channel, svid: svid, quality: GpsSatQuality(fromDict: quality)!, cno: cno)
    }
    
    func toDict() -> NSDictionary {
        return [ "channel": channel, "svid": svid, "quality": quality.toDict(), "cno": cno ]
    }
}

struct GPSLocation : DictionaryCoding, Equatable  {
    var latitude: Double
    var longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // MARK: DictionaryCoding
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let latitude = dict["latitude"] as? Double,
            let longitude = dict["longitude"] as? Double
            else { return nil }
        
        self.init(latitude: latitude, longitude: longitude)
    }
    
    func toDict() -> NSDictionary {
        return [ "latitude": latitude, "longitude": longitude ]
    }
    
    // MARK:
    
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
func ==(lhs: GPSLocation, rhs: GPSLocation) -> Bool {
    return lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude
}


struct Waypoint {
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
}

class GPSData : AutoCoded {
    var autoEncoding = [ "fix", "latitude", "longitude", "altitude", "speed", "headingOverGround", "numSat", "distanceToHome", "directionToHome", "update", "lastKnownGoodLatitude", "lastKnownGoodLongitude", "lastKnownGoodAltitude", "lastKnownGoodTimestamp" ]
    static var theGPSData = GPSData()
    
    // MSP_RAW_GPS
    var fix = false
    var position: GPSLocation = GPSLocation(latitude: 0, longitude: 0) {
        didSet {
            if fix {
                // Hack to avoid bogus first position with lat or long at 0 when the object is decoded and uses the lat and long setters in sequence
                if position.latitude != 0 && position.longitude != 0 {
                    lastKnownGoodLatitude = position.latitude
                    lastKnownGoodLongitude = position.longitude
                    lastKnownGoodTimestamp = NSDate()
                    
                    positions.append(position.toCLLocationCoordinate2D())
                }
            }
        }
    }
    var latitude: Double {          // degree
        get {
            return position.latitude
        }
        // FIXME Only needed for backward compatibility of old flight log files
        set(value) {
            position.latitude = value
        }
    }
    var longitude: Double {         // degree
        get {
            return position.longitude
        }
        // FIXME Only needed for backward compatibility of old flight log files
        set(value) {
            position.longitude = value
        }
    }
    var altitude = 0 {           // m
        willSet(value) {
            if fix {
                lastKnownGoodAltitude = value
                maxAltitude = max(maxAltitude, value)
                if lastAltitudeTime != nil {
                    variometer = Double(value - altitude) / -lastAltitudeTime!.timeIntervalSinceNow
                }
                lastAltitudeTime = NSDate()
            }
        }
    }
    var speed = 0.0 {             // km/h
        didSet {
            if fix {
                maxSpeed = max(maxSpeed, speed)
            }
        }
    }
    var headingOverGround = 0.0 // degree
    var numSat = 0
    
    // MSP_COMP_GPS
    var distanceToHome = 0 {      // m
        didSet {
            if fix {
                maxDistanceToHome = max(maxDistanceToHome, distanceToHome)
            }
        }
    }
    var directionToHome = 0     // degree
    var update = 0
    
    // MSP_WP
    var homePosition: GPSLocation?
    var posHoldPosition: GPSLocation?
    var waypoints = [Waypoint]()

    // Local
    var lastKnownGoodLatitude = 0.0
    var lastKnownGoodLongitude = 0.0
    var lastKnownGoodAltitude = 0
    var lastKnownGoodTimestamp: NSDate?
    var maxDistanceToHome = 0
    var maxAltitude = 0
    var variometer = 0.0
    var lastAltitudeTime: NSDate?
    var maxSpeed = 0.0
    var positions = [CLLocationCoordinate2D]()
    
    // MSP_GPSSVINFO
    private var _satellites = [Satellite]()
    
    var satellites: [Satellite] {
        get {
            return [Satellite](_satellites)
        }
        set(value) {
            _satellites = value
        }
    }
    
    private override init() {
        super.init()
    }

    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if let satellitesDicts = aDecoder.decodeObjectForKey("satellites") as? [NSDictionary] {
            _satellites = [Satellite]()
            for dict in satellitesDicts {
                _satellites.append(Satellite(fromDict: dict)!)
            }
        }
        if let positionDict = aDecoder.decodeObjectForKey("position") as? NSDictionary {
            position = GPSLocation(fromDict: positionDict)!
        }
        if let positionDict = aDecoder.decodeObjectForKey("homePosition") as? NSDictionary {
            homePosition = GPSLocation(fromDict: positionDict)!
        }
        if let positionDict = aDecoder.decodeObjectForKey("posHoldPosition") as? NSDictionary {
            posHoldPosition = GPSLocation(fromDict: positionDict)!
        }
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        
        var satellitesDicts = [NSDictionary]()
        for satellite in _satellites {
            satellitesDicts.append(satellite.toDict())
        }
        aCoder.encodeObject(satellitesDicts, forKey: "satellites")
        aCoder.encodeObject(position.toDict(), forKey: "position")
        if homePosition != nil {
            aCoder.encodeObject(homePosition!.toDict(), forKey: "homePosition")
        }
        if posHoldPosition != nil {
            aCoder.encodeObject(posHoldPosition!.toDict(), forKey: "posHoldPosition")
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

class Receiver : AutoCoded {
    var autoEncoding = [ "activeChannels", "channels", "map" ]
    static var theReceiver = Receiver()
    
    var activeChannels = 0
    var channels = [Int](count: 18, repeatedValue: 0)   // Length must match MAX_SUPPORTED_RC_CHANNEL_COUNT in cleanflight
    
    var map = [Int](count: 8, repeatedValue: 0)         // Length must match MAX_MAPPABLE_RX_INPUTS in cleanflight

    private override init() {
        super.init()
    }
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class SensorData : AutoCoded {
    var autoEncoding = [ "accelerometerX", "accelerometerY", "accelerometerZ", "gyroscopeX", "gyroscopeY", "gyroscopeZ", "magnetometerX", "magnetometerY", "magnetometerZ", "altitude", "variometer", "sonar", "rollAngle", "pitchAngle", "heading", "altitudeHold", "headingHold" ]
    static var theSensorData = SensorData()
    
    // MSP_RAW_IMU
    var accelerometerX = 0.0, accelerometerY = 0.0, accelerometerZ = 0.0
    var gyroscopeX = 0.0, gyroscopeY = 0.0, gyroscopeZ = 0.0
    var magnetometerX = 0.0, magnetometerY = 0.0, magnetometerZ = 0.0
    // MSP_ALTITUDE
    var altitude = 0.0 {          // m
        willSet(value) {
            maxAltitude = max(maxAltitude, value)
        }
    }
    var variometer = 0.0
    // MSP_SONAR
    var sonar = 0               // cm
    // MSP_ATTITUDE
    var rollAngle = 0.0
    var pitchAngle = 0.0
    var heading = 0.0 {
        willSet(value) {
            if lastAttitude != nil {
                let deltaTime = -lastAttitude!.timeIntervalSinceNow
                if deltaTime > 0.01 {
                    var headingVariation = value - heading
                    if headingVariation < -180 {
                        headingVariation += 360
                    } else if headingVariation > 180 {
                        headingVariation -= 360
                    }
                    turnRate = headingVariation / deltaTime / 2 + turnRate / 2
                    //if abs(turnRate) > 360 {
                    //    NSLog("Turn rate %.0f, (dt=%f)", turnRate, deltaTime)
                    //}
                    lastAttitude = NSDate()
                }
            } else {
                lastAttitude = NSDate()
            }
        }
    }
    // MSP_WP
    var altitudeHold = 0.0
    var headingHold = 0.0

    // Local
    var maxAltitude = 0.0       // m
    
    var turnRate = 0.0          // deg / s
    var lastAttitude: NSDate?
    
    private override init() {
        super.init()
    }
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class MotorData : AutoCoded {
    var autoEncoding = [ "nMotors", "throttle", "servoValue" ]
    static var theMotorData = MotorData()
    
    // MSP_MOTOR
    var nMotors = 8
    var throttle = [Int](count: 8, repeatedValue: 0)
    // MSP_SERVO
    var servoValue = [Int](count: 8, repeatedValue: 0)

    private override init() {
        super.init()
    }
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class Dataflash : AutoCoded {
    var autoEncoding = [ "ready", "sectors", "usedSize", "totalSize" ]
    static var theDataflash = Dataflash()
    
    var ready = 0
    var sectors = 0
    var usedSize = 0
    var totalSize = 0

    private override init() {
        super.init()
    }
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class AllAircraftData : NSObject, NSCoding {
    static var allAircraftData = AllAircraftData()
    
    var settings: Settings
    var misc: Misc
    var configuration: Configuration
    var gpsData: GPSData
    var receiver: Receiver
    var sensorData: SensorData
    var motorData: MotorData
    var dataflash: Dataflash
    
    override init() {
        settings = Settings.theSettings
        misc = Misc.theMisc
        configuration = Configuration.theConfig
        gpsData = GPSData.theGPSData
        receiver = Receiver.theReceiver
        sensorData = SensorData.theSensorData
        motorData = MotorData.theMotorData
        dataflash = Dataflash.theDataflash
    }
    
    // MARK: NSCoding
    
    required convenience init?(coder decoder: NSCoder) {
        guard let settings = decoder.decodeObjectForKey("Settings") as? Settings,
            let misc = decoder.decodeObjectForKey("Misc") as? Misc,
            let configuration = decoder.decodeObjectForKey("Configuration") as? Configuration,
            let gpsData = decoder.decodeObjectForKey("GPSData") as? GPSData,
            let receiver = decoder.decodeObjectForKey("Receiver") as? Receiver,
            let sensorData = decoder.decodeObjectForKey("SensorData") as? SensorData,
            let motorData = decoder.decodeObjectForKey("MotorData") as? MotorData,
            let dataflash = decoder.decodeObjectForKey("Dataflash") as? Dataflash
            else { return nil }
        
        self.init()
        self.settings = settings
        Settings.theSettings = settings
        self.misc = misc
        Misc.theMisc = misc
        self.configuration = configuration
        Configuration.theConfig = configuration
        self.gpsData = gpsData
        GPSData.theGPSData = gpsData
        self.receiver = receiver
        Receiver.theReceiver = receiver
        self.sensorData = sensorData
        SensorData.theSensorData = sensorData
        self.motorData = motorData
        MotorData.theMotorData = motorData
        self.dataflash = dataflash
        Dataflash.theDataflash = dataflash
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(settings, forKey: "Settings")
        coder.encodeObject(misc, forKey: "Misc")
        coder.encodeObject(configuration, forKey: "Configuration")
        coder.encodeObject(gpsData, forKey: "GPSData")
        coder.encodeObject(receiver, forKey: "Receiver")
        coder.encodeObject(sensorData, forKey: "SensorData")
        coder.encodeObject(motorData, forKey: "MotorData")
        coder.encodeObject(dataflash, forKey: "Dataflash")
    }

}

func resetAircraftModel() {
    Settings.theSettings = Settings()
    Misc.theMisc = Misc()
    Configuration.theConfig = Configuration()
    GPSData.theGPSData = GPSData()
    Receiver.theReceiver = Receiver()
    SensorData.theSensorData = SensorData()
    MotorData.theMotorData = MotorData()
    Dataflash.theDataflash = Dataflash()
    
    AllAircraftData.allAircraftData = AllAircraftData()
    
    INavConfig.theINavConfig = INavConfig()
}
