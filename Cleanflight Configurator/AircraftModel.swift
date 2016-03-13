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
    case AUTOTUNE = "AUTOTUNE"
    case GTUNE = "GTUNE"
    case SONAR = "SONAR"
    case SERVO1 = "SERVO1"
    case SERVO2 = "SERVO2"
    case SERVO3 = "SERVO3"
    case BLACKBOX = "BLACKBOX"
    case FAILSAFE = "FAILSAFE"
    case AIR = "AIR MODE"
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

enum PortIdentifier : Int {
    case None = -1
    case USART1 = 0
    case USART2 = 1
    case USART3 = 2
    case USART4 = 3
    case USB_VCP = 20
    case SoftSerial1 = 30
    case SoftSerial2 = 31
}

enum BaudRate : Int {
    case Auto = 0
    case Baud9600 = 1
    case Baud19200 = 2
    case Baud38400 = 3
    case Baud57600 = 4
    case Baud115200 = 5
    case Baud230400 = 6
    case Baud250000 = 7
    
}

struct PortConfig : DictionaryCoding {
    var portIdentifier = PortIdentifier.None
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
        
        self.init(portIdentifier: PortIdentifier(rawValue: portIdentifier)!, functions: PortFunction(rawValue: functions), mspBaudRate: BaudRate(rawValue: mspBaudRate)!, gpsBaudRate: BaudRate(rawValue: gpsBaudRate)!, telemetryBaudRate: BaudRate(rawValue: telemetryBaudRate)!, blackboxBaudRate: BaudRate(rawValue: blackboxBaudRate)!)
    }
    
    func toDict() -> NSDictionary {
        return [ "portIdentifier": portIdentifier.rawValue, "functions": functions.rawValue, "mspBaudRate": mspBaudRate.rawValue, "gpsBaudRate": gpsBaudRate.rawValue, "telemetryBaudRate": telemetryBaudRate.rawValue, "blackboxBaudRate": blackboxBaudRate.rawValue ]
    }
}

class Settings : AutoCoded {
    var autoEncoding = [ "autoDisarmDelay", "disarmKillSwitch", "mixerConfiguration", "serialRxType", "boardAlignRoll", "boardAlignPitch", "boardAlignYaw", "currentScale", "currentOffset", "boxNames", "boxIds", "modeRangeSlots", "rcExpo", "yawExpo", "rcRate", "rollRate", "pitchRate", "yawRate", "throttleMid", "throttleExpo", "tpaRate", "tpaBreakpoint", "pidNames", "pidValues", "pidController", "maxCheck", "minCheck", "spektrumSatBind", "rxMinUsec",
        "rxMaxUsec", "failsafeDelay", "failsafeOffDelay", "failsafeThrottleLowDelay", "failsafeKillSwitch", "failsafeProcedure", "rxFailMode", "rxFailValue" ]
    static var theSettings: Settings!
    
    // MSP_ARMING_CONFIG / MSP_SET_ARMING_CONFIG
    var autoDisarmDelay = 5       // sec
    var disarmKillSwitch = false
    
    // MSP_BF_CONFIG / MSP_SET_BF_CONFIG
    var mixerConfiguration = 3              // Quad X by default
    var features = BaseFlightFeature.None
    var serialRxType = 0
    var boardAlignRoll = 0
    var boardAlignPitch = 0
    var boardAlignYaw = 0
    var currentScale = 400
    var currentOffset = 0

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
    
    // MSP_SERVO_CONFIGURATIONS / MSP_SET_SERVO_CONFIGURATION
    var servoConfigs: [ServoConfig]?
    
    // MSP_CF_SERIAL_CONFIG / MSP_SET_CF_SERIAL_CONFIG
    var portConfigs: [PortConfig]?
    
    // MSP_RX_CONFIG / MSP_SET_RX_CONFIG
    // serialRxType
    var maxCheck = 1100
    // misc.midRC
    var minCheck = 1900
    var spektrumSatBind = 0
    var rxMinUsec = 885
    var rxMaxUsec = 2115
    
    // MSP_FAILSAFE_CONFIG / MSP_SET_FAILSAFE_CONFIG
    var failsafeDelay = 0.0         // Guard time for failsafe activation after signal loss (0 - 20 secs)
    var failsafeOffDelay = 0.0      // Time for landing before motor stop (0 - 20 secs)
    var failsafeThrottleLowDelay = 0.0  // If throtlle has been below minCheck for that much time, just disarm (0 - 30 secs)
    // misc.failsafeThrottle
    var failsafeKillSwitch = false  // If true, failsafe switch will disarm aircraft instantly instead of doing the failsafe procedure
    var failsafeProcedure = 0       // 0: land, 1: drop
    
    // MSP_RX_FAIL_CONFIG / MSP_SET_RX_FAIL_CONFIG
    var rxFailMode: [Int]?          // 0: Auto, 1: Hold, 2: Set
    var rxFailValue: [Int]?         // For mode 2 (Set)
    
    override init() {
        super.init()
        Settings.theSettings = self
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
        
        self.pidNames = copyOf.pidNames
        self.pidValues = copyOf.pidValues
        self.pidController = copyOf.pidController
        
        self.servoConfigs = copyOf.servoConfigs
        self.portConfigs = copyOf.portConfigs
        
        self.maxCheck = copyOf.maxCheck
        self.minCheck = copyOf.minCheck
        self.spektrumSatBind = copyOf.spektrumSatBind
        self.rxMinUsec = copyOf.rxMinUsec
        self.rxMaxUsec = copyOf.rxMaxUsec
        
        self.failsafeDelay = copyOf.failsafeDelay
        self.failsafeOffDelay = copyOf.failsafeOffDelay
        self.failsafeThrottleLowDelay = copyOf.failsafeThrottleLowDelay
        self.failsafeKillSwitch = copyOf.failsafeKillSwitch
        self.failsafeProcedure = copyOf.failsafeProcedure
        
        self.rxFailMode = copyOf.rxFailMode
        self.rxFailValue = copyOf.rxFailValue
        
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
    var autoEncoding = [ "midRC", "minThrottle", "maxThrottle", "minCommand", "failsafeThrottle", "gpsType", "gpsBaudRate", "gpsUbxSbas", "multiwiiCurrentOutput", "rssiChannel", "placeholder2", "magDeclination", "vbatScale", "vbatMinCellVoltage", "vbatMaxCellVoltage", "vbatWarningCellVoltage", "accelerometerTrimPitch", "accelerometerTrimRoll" ]
    static var theMisc: Misc!
    
    // MSP_MISC / MSP_SET_MISC
    var midRC = 1500            // rxConfig.midrc [1401 - 1599], also set by RX_CONFIG (but then no range is enforced...)
    var minThrottle = 1150      // escAndServoConfig.minthrottle    // Used when motors are armed in !MOTOR_STOP
    var maxThrottle = 1850      // escAndServoConfig.maxthrottle    // Motor output always constrained by this limit. Will reduce other motors if one is above limit
    var minCommand = 1000       // escAndServoConfig.mincommand     // Used to disarm motors
    var failsafeThrottle = 0
    var gpsType = 0
    var gpsBaudRate = 0
    var gpsUbxSbas = 0
    var multiwiiCurrentOutput = 0       // FIXME This should be a boolean instead
    var rssiChannel = 0
    var placeholder2 = 0
    var magDeclination = 0.0         // degree
    var vbatScale = 0
    var vbatMinCellVoltage = 0.0     // V
    var vbatMaxCellVoltage = 0.0     // V
    var vbatWarningCellVoltage = 0.0 // V
    
    // MSP_ACC_TRIM / MSP_SET_ACC_TRIM
    var accelerometerTrimPitch = 0
    var accelerometerTrimRoll = 0
    
    override init() {
        super.init()
        Misc.theMisc = self
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
    var autoEncoding = [ "version", "multiType", "mspVersion", "capability", "msgProtocolVersion", "apiVersion", "buildInfo", "fcIdentifier", "fcVersion", "boardInfo", "boardVersion", "uid", "cycleTime", "i2cError", "activeSensors", "mode", "profile", "voltage", "mAhDrawn", "rssi", "amperage", "batteryCells", "maxAmperage" ]
    static var theConfig: Configuration!
    
    // MSP_IDENT
    var version: String?
    var multiType = 3      // Quad X by default
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

    // MSP_STATUS
    var cycleTime = 0     // microsecond?
    var i2cError = 0
    var activeSensors = 0
    var mode = 0
    var profile = 0
    
    // MSP_ANALOG
    var voltage = 0.0 {      // V
        didSet {
            if voltage > 0 && batteryCells == 0 && Settings.theSettings.features.contains(.VBat) ?? false {
                let vbatMaxCellVoltage = Misc.theMisc.vbatMaxCellVoltage
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
    
    private var _localSNR = 0.0
    private var _remoteSNR = 0.0
    private var lastLocalSNRTime: NSDate?
    private var lastRemoteSNRTime: NSDate?
    
    override init() {
        super.init()
        Configuration.theConfig = self
    }
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        for var i = 0; ;i++ {
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

struct GPSLocation : DictionaryCoding {
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

class GPSData : AutoCoded {
    var autoEncoding = [ "fix", "latitude", "longitude", "altitude", "speed", "headingOverGround", "numSat", "distanceToHome", "directionToHome", "update", "lastKnownGoodLatitude", "lastKnownGoodLongitude", "lastKnownGoodAltitude", "lastKnownGoodTimestamp" ]
    static var theGPSData: GPSData!
    
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
    
    override init() {
        super.init()
        GPSData.theGPSData = self
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
}

class Receiver : AutoCoded {
    var autoEncoding = [ "activeChannels", "channels", "map" ]
    static var theReceiver: Receiver!
    
    var activeChannels = 0
    var channels = [Int](count: 18, repeatedValue: 0)   // Length must match MAX_SUPPORTED_RC_CHANNEL_COUNT in cleanflight
    
    var map = [Int](count: 8, repeatedValue: 0)         // Length must match MAX_MAPPABLE_RX_INPUTS in cleanflight

    override init() {
        super.init()
        Receiver.theReceiver = self
    }
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class SensorData : AutoCoded {
    var autoEncoding = [ "accelerometerX", "accelerometerY", "accelerometerZ", "gyroscopeX", "gyroscopeY", "gyroscopeZ", "magnetometerX", "magnetometerY", "magnetometerZ", "altitude", "variometer", "sonar", "rollAngle", "pitchAngle", "heading", "altitudeHold", "headingHold" ]
    static var theSensorData: SensorData!
    
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
                    if abs(turnRate) > 360 {
                        NSLog("Turn rate %.0f, (dt=%f)", turnRate, deltaTime)
                    }
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
    
    override init() {
        super.init()
        SensorData.theSensorData = self
    }
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class MotorData : AutoCoded {
    var autoEncoding = [ "nMotors", "throttle", "servoValue" ]
    static var theMotorData: MotorData!
    
    // MSP_MOTOR
    var nMotors = 8
    var throttle = [Int](count: 8, repeatedValue: 0)
    // MSP_SERVO
    var servoValue = [Int](count: 8, repeatedValue: 0)

    override init() {
        super.init()
        MotorData.theMotorData = self
    }
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class Dataflash : AutoCoded {
    var autoEncoding = [ "ready", "sectors", "usedSize", "totalSize" ]
    static var theDataflash: Dataflash!
    
    var ready = 0
    var sectors = 0
    var usedSize = 0
    var totalSize = 0

    override init() {
        super.init()
        Dataflash.theDataflash = self
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

    // FIXME Hack
    func updateVehicle(vehicle: MSPVehicle) {
        vehicle.settings = settings
        vehicle.misc = misc
        vehicle.config = configuration
        vehicle.gpsData = gpsData
        vehicle.receiver = receiver
        vehicle.sensorData = sensorData
        vehicle.motorData = motorData
        vehicle.dataflash = dataflash
        
        if settings.features.contains(.VBat) && configuration.batteryCells != 0 {
            vehicle.batteryVoltsWarning.value = misc.vbatWarningCellVoltage * Double(configuration.batteryCells)
            vehicle.batteryVoltsCritical.value = misc.vbatMinCellVoltage * Double(configuration.batteryCells)
        }

    }
}
