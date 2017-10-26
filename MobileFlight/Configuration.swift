//
//  Configuration.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 12/06/17.
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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


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
    var activeSensors = 0   // bitmask: 0=Accelerometer, 1=Baro, 2=Mag, 3=GPS, 4=Sonar, (BF 3.2) 5=gyro
    
    var mode = 0 {
        didSet {
            let modeChanges = oldValue ^ mode
            if !_loading && modeChanges != 0 && userDefaultEnabled(.FlightModeAlert) {
                guard let boxNames = Settings.theSettings.boxNames else {
                    return
                }
                var activatedModes = [Mode]()
                var deactivatedModes = [Mode]()
                var alreadySpoken = false
                for (i, m) in boxNames.enumerated() {
                    let modeBit = 1 << i
                    // If mode has been activated
                    if modeChanges & modeBit != 0 {
                        guard let flightMode = Mode(rawValue: m) else {
                            continue
                        }
                        if mode & modeBit != 0 {
                            activatedModes.append(flightMode)
                        } else {
                            deactivatedModes.append(flightMode)
                        }
                    }
                }
                for flightMode in activatedModes {
                    var implied = false
                    for otherFlightMode in activatedModes {
                        if flightMode.impliedBy(otherFlightMode) {
                            implied = true
                            break
                        }
                    }
                    if implied {
                        continue
                    }
                    var speech = flightMode.spokenName
                    if flightMode == .ARM {
                        speech = "motors armed"
                    }
                    VoiceMessage.theVoice.speak(speech)
                    alreadySpoken = true
                }
                if !alreadySpoken {
                    // Process deactivated modes
                    for flightMode in deactivatedModes {
                        var implied = false
                        for otherFlightMode in deactivatedModes {
                            if flightMode.impliedBy(otherFlightMode) {
                                implied = true
                                break
                            }
                        }
                        if implied {
                            continue
                        }
                        var speech = flightMode.spokenName
                        if flightMode == .ARM {
                            speech = "disarmed"
                        } else {
                            speech = speech + " off"
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
    
    fileprivate var _localSNR = 0.0
    fileprivate var _remoteSNR = 0.0
    fileprivate var lastLocalSNRTime: Date?
    fileprivate var lastRemoteSNRTime: Date?
    
    fileprivate var _loading = true
    
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
        return activeSensors & 1 != 0
    }
    func isBarometerActive() -> Bool {
        return activeSensors & 2 != 0
    }
    
    func isMagnetometerActive() -> Bool {
        return activeSensors & 4 != 0
    }
    
    func isGPSActive() -> Bool {
        return activeSensors & 8 != 0
    }
    
    func isSonarActive() -> Bool {
        return activeSensors & 16 != 0
    }
    
    // BF 3.2
    func isGyroActive() -> Bool {
        if isApiVersionAtLeast("1.36") && !isINav {
            return activeSensors & 32 != 0
        } else {
            // Assume active
            return true
        }
    }
    
    // INav
    
    func isPitotActive() -> Bool {
        return activeSensors & 64 != 0;
    }
    
    func isHardwareHealthy() -> Bool {
        return activeSensors & (1 << 15) != 0;
    }
    
    func isApiVersionAtLeast(_ version: String) -> Bool {
        if apiVersion == nil {
            return false
        }
        let currentVersion = apiVersion!.components(separatedBy: ".")
        let refVersion = version.components(separatedBy: ".")
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
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        if key == "accelerometerTrimPitch" || key == "accelerometerTrimRoll" {
            // These were moved to Misc. Ignore them.
            return
        }
        super.setValue(value, forUndefinedKey: key)
    }
    
    var localSNR: Double {
        if lastLocalSNRTime == nil || -lastLocalSNRTime!.timeIntervalSinceNow >= 1 {
            lastLocalSNRTime = Date()
            _localSNR = (-120 + Double(sikRssi - noise) * 120 / 207) / 2 + _localSNR / 2
        }
        return _localSNR
    }
    
    var remoteSNR: Double {
        if lastRemoteSNRTime == nil || -lastRemoteSNRTime!.timeIntervalSinceNow >= 1 {
            lastRemoteSNRTime = Date()
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

