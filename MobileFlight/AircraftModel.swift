//
//  AircraftModel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation
import MapKit
import Firebase

protocol DictionaryCoding {
    func toDict() -> NSDictionary
    init?(fromDict: NSDictionary?)
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
    var autoEncoding = [ "blackboxDevice", "blackboxRateNum", "blackboxRateDenom" ]
    static var theDataflash = Dataflash()
    
    // MSP_BLACKBOX_CONFIG
    var blackboxSupported = false
    var blackboxDevice = 0
    var blackboxRateNum = 1
    var blackboxRateDenom = 1
    
    // MSP_DATAFLASH_SUMMARY
    var ready = false
    var sectors = 0
    var usedSize = 0
    var totalSize = 0

    // MSP_SDCARD_SUMMARY
    var sdcardSupported = false
    var sdcardState = 0
    var sdcardLastError = 0
    var sdcardFreeSpace: Int64 = 0
    var sdcardTotalSpace: Int64 = 0
    
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
    var inavState: INavState
    
    override init() {
        settings = Settings.theSettings
        misc = Misc.theMisc
        configuration = Configuration.theConfig
        gpsData = GPSData.theGPSData
        receiver = Receiver.theReceiver
        sensorData = SensorData.theSensorData
        motorData = MotorData.theMotorData
        inavState = INavState.theINavState
    }
    
    // MARK: NSCoding
    
    required convenience init?(coder decoder: NSCoder) {
        guard let settings = decoder.decodeObjectForKey("Settings") as? Settings,
            let misc = decoder.decodeObjectForKey("Misc") as? Misc,
            let configuration = decoder.decodeObjectForKey("Configuration") as? Configuration,
            let gpsData = decoder.decodeObjectForKey("GPSData") as? GPSData,
            let receiver = decoder.decodeObjectForKey("Receiver") as? Receiver,
            let sensorData = decoder.decodeObjectForKey("SensorData") as? SensorData,
            let motorData = decoder.decodeObjectForKey("MotorData") as? MotorData
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
        
        if decoder.containsValueForKey("INavState") {
            self.inavState = decoder.decodeObjectForKey("INavState") as! INavState
            INavState.theINavState = self.inavState
        } else {
            self.inavState = INavState()
            INavState.theINavState = self.inavState
        }
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(settings, forKey: "Settings")
        coder.encodeObject(misc, forKey: "Misc")
        coder.encodeObject(configuration, forKey: "Configuration")
        coder.encodeObject(gpsData, forKey: "GPSData")
        coder.encodeObject(receiver, forKey: "Receiver")
        coder.encodeObject(sensorData, forKey: "SensorData")
        coder.encodeObject(motorData, forKey: "MotorData")
        coder.encodeObject(inavState, forKey: "INavState")
    }

}

/*
enum VTXBand : Int {
    case BOSCAM_A = 0
    case BOSCAM_B = 1
    case BOSCAM_E = 2
    case FATSHARK = 3
    case RACEBAND = 4
}

enum VTXChannel : Int {
    0-7: Channel 1 to 8
}

enum SmartAudioPower : Int {
    case MW25 = 0
    case MW200 = 1
    case MW500 = 2
    case MW800 = 3
}
enum TrampPower : Int {
    case MW25 = 0
    case MW100 = 1
    case MW200 = 2
    case MW400 = 3
    case MW600 = 4
}
*/

class VTXConfig {
    static var theVTXConfig = VTXConfig()
    
    var deviceType = 0
    var band = 0
    var channel = 0
    var powerIdx = 0
    var pitMode = false
}

func resetAircraftModel() {
    Settings.theSettings = Settings()
    Misc.theMisc = Misc()
    Configuration.theConfig = Configuration()
    GPSData.theGPSData = GPSData()
    Receiver.theReceiver = Receiver()
    SensorData.theSensorData = SensorData()
    MotorData.theMotorData = MotorData()
    INavState.theINavState = INavState()
    
    AllAircraftData.allAircraftData = AllAircraftData()
    
    Dataflash.theDataflash = Dataflash()
    INavConfig.theINavConfig = INavConfig()
    
    OSD.theOSD = OSD()
    VTXConfig.theVTXConfig = VTXConfig()
}
