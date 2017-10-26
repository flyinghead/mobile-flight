//
//  VoiceMessage.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 18/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
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

import UIKit
import AVFoundation

enum AlertText : String {
    case CommunicationLost = "Communication Lost"
    case GPSFixLost = "GPS Fix Lost"
}

class VoiceAlert: NSObject {
    var speech: String
    let condition: () -> Bool
    let repeatInterval: TimeInterval
    var timer: Timer?
    
    init(speech: String, repeatInterval: TimeInterval, condition: @escaping () -> Bool) {
        self.speech = speech
        self.condition = condition
        self.repeatInterval = repeatInterval
        super.init()
    }
    
    func startSpeaking() {
        timer = Timer.scheduledTimer(timeInterval: repeatInterval, target: self, selector: #selector(VoiceAlert.timerDidFire(_:)), userInfo: nil, repeats: true)
        timerDidFire(timer!)
    }
    
    func timerDidFire(_ timer: Timer) {
        if !condition() {
            timer.invalidate()
            self.timer = nil
            return
        }
        VoiceMessage.theVoice.speak(speech)
    }
}

class VoiceAlarm {
    var on: Bool { return false }
    var enabled: Bool { return true }
    
    func voiceAlert() -> VoiceAlert! {
        return nil
    }
}

class CommunicationLostAlarm : VoiceAlarm {
    override var on: Bool {
        
        if !Settings.theSettings.armed {
            return false
        }
        let msp = (UIApplication.shared.delegate as! AppDelegate).msp
        return msp.communicationEstablished && !msp.communicationHealthy
    }
    
    override var enabled: Bool {
        return userDefaultEnabled(.ConnectionLostAlarm)
    }
    
    override func voiceAlert() -> VoiceAlert {
        return VoiceAlert(speech: "Communication Lost", repeatInterval: 10.0, condition: { self.enabled && self.on })
    }
}

class GPSFixLostAlarm : VoiceAlarm {
    override var on: Bool {
        if CommunicationLostAlarm().on {
            return false
        }
        // TODO Add a condition on whether we have a home fix and we had a GPS fix when arming
        let settings = Settings.theSettings
        let mode = Configuration.theConfig.mode
        
        // Only alert if armed and in GPS Hold or Home mode
        if !settings.armed
            || (!settings.isModeOn(.NAV_WP, forStatus: mode) && !settings.returnToHomeMode && !settings.positionHoldMode) {
                return false
        }
        
        let gpsData = GPSData.theGPSData
        return !gpsData.fix || gpsData.numSat < 5
    }
    override var enabled: Bool {
        return userDefaultEnabled(.GPSFixLostAlarm)
    }
    
    override func voiceAlert() -> VoiceAlert {
        return VoiceAlert(speech: "GPS Fix Lost", repeatInterval: 10.0, condition: { self.enabled && self.on })
    }
}

class BatteryLowAlarm : VoiceAlarm {
    enum Status {
        case good, warning, critical
    }
    
    override var on: Bool {
        return batteryStatus() != .good
    }
    override var enabled: Bool {
        return userDefaultEnabled(.BatteryLowAlarm)
    }

    func batteryStatus() -> Status {
        let msp = (UIApplication.shared.delegate as! AppDelegate).msp
        if !msp.communicationEstablished || !msp.communicationHealthy {
            return .good        // Comm lost or not connected, no need for battery alarm
        }
        let settings = Settings.theSettings
        let config = Configuration.theConfig
        
        if settings.features.contains(.VBat)
            && config.batteryCells > 0
            && config.voltage > 0 {
            let voltsPerCell = config.voltage / Double(config.batteryCells)
            if voltsPerCell <= settings.vbatMinCellVoltage {
                return .critical
            } else if voltsPerCell <= settings.vbatWarningCellVoltage {
                return .warning
            }
        }
        return .good
    }
    
    override func voiceAlert() -> VoiceAlert {
        return VoiceAlert(speech: batteryStatus() == .critical ? "Battery level critical" : "Battery low", repeatInterval: 10.0, condition: { self.enabled && self.on })
    }
}

class RSSILowAlarm : VoiceAlarm {
    
    override var on: Bool {
        let msp = (UIApplication.shared.delegate as! AppDelegate).msp
        if !msp.communicationEstablished || CommunicationLostAlarm().on {
            return false
        }
        let config = Configuration.theConfig
        
        return Settings.theSettings.armed && config.rssi <= userDefaultAsInt(.RSSIAlarmLow)
    }
    override var enabled: Bool {
        return userDefaultEnabled(.RSSIAlarm)
    }
    
    override func voiceAlert() -> VoiceAlert! {
        return VoiceAlert(speech: Configuration.theConfig.rssi <= userDefaultAsInt(.RSSIAlarmCritical) ? "R.S.S.I. critical" : "R.S.S.I. low", repeatInterval: 10.0, condition: { self.enabled && self.on })
    }
}

class VoiceMessage: NSObject, AVSpeechSynthesizerDelegate {
    static let theVoice = VoiceMessage()
    let synthesizer = AVSpeechSynthesizer()
    
    fileprivate var alerts = [String: VoiceAlert]()
    fileprivate var speeches = Set<String>()
    
    fileprivate override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    fileprivate func addAlert(_ name: String, alert: VoiceAlert) {
        if let oldAlert = alerts[name] {
            if oldAlert.timer?.isValid ?? false {
                oldAlert.speech = alert.speech
                return
            }
        }
        alerts[name] = alert
        alert.startSpeaking()
    }

    func speak(_ speech: String) {
        if speeches.contains(speech) {
            return
        }
        speeches.insert(speech)
        
        let utterance = AVSpeechUtterance(string: speech)
        utterance.voice = findVoice()
        utterance.rate = (UIDevice.current.systemVersion as NSString).floatValue >= 9.0 ? 0.52 : 0.15
        synthesizer.speak(utterance)
    }
    
    func findVoice() -> AVSpeechSynthesisVoice? {
        if AVSpeechSynthesisVoice.currentLanguageCode().hasPrefix("en-") {
            // Use default voice
            return nil
        }
        var englishVoice: AVSpeechSynthesisVoice? = nil
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            if voice.language == "en-US" {
                return voice
            }
            if voice.language.hasPrefix("en-") {
                englishVoice = voice
            }
        }
        return englishVoice
    }
    
    func checkAlarm(_ alarm: VoiceAlarm) {
        if alarm.enabled && alarm.on {
            addAlert(NSStringFromClass(type(of: alarm)), alert: alarm.voiceAlert())
        }
    }
    
    fileprivate func stopAlerts() {
        for alert in alerts.values {
            alert.timer?.invalidate()
        }
        alerts.removeAll()
    }
    
    func stopAll() {
        stopAlerts()
        synthesizer.stopSpeaking(at: .word)
        speeches.removeAll()
    }
    
    // MARK: AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        speeches.remove(utterance.speechString)
    }
}
