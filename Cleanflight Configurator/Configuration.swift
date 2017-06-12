//
//  Configuration.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 12/06/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class Configuration : AutoCoded {
    var autoEncoding = [ "version", "mspVersion", "capability", "msgProtocolVersion", "apiVersion", "buildInfo", "fcIdentifier", "fcVersion", "boardInfo", "boardVersion", "uid", "cycleTime", "i2cError", "activeSensors", "mode", "profile", "systemLoad", "rateProfile", "voltage", "mAhDrawn", "rssi", "amperage", "batteryCells", "maxAmperage", "btRssi" ]
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
    
    override init() {
        super.init()
        _loading = false
    }
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _loading = false
    }
    // MARK:
    
    func isAccelerometerActive() -> Bool {
        return activeSensors & 1 != 0;
    }
    func isBarometerActive() -> Bool {
        return activeSensors & 2 != 0;
    }
    
    func isMagnetometerActive() -> Bool {
        return activeSensors & 4 != 0;
    }
    
    func isGPSActive() -> Bool {
        return activeSensors & 8 != 0;
    }
    
    func isSonarActive() -> Bool {
        return activeSensors & 16 != 0;
    }
    
    // INav
    
    func isPitotActive() -> Bool {
        return activeSensors & 64 != 0;
    }
    
    func isHardwareHealthy() -> Bool {
        return activeSensors & (1 << 15) != 0;
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
        return fcIdentifier!.hasPrefix("BTFL")  // Account for the simulator (BTFL SIM)
    }
    
    var isINav: Bool {
        return fcIdentifier == "INAV"
    }
}

