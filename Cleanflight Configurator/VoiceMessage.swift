//
//  VoiceMessage.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 18/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import AVFoundation

enum AlertText : String {
    case CommunicationLost = "Communication Lost"
    case GPSFixLost = "GPS Fix Lost"
}

class VoiceAlert: NSObject {
    var speech: String
    let condition: () -> Bool
    let repeatInterval: NSTimeInterval
    var timer: NSTimer?
    
    init(speech: String, repeatInterval: NSTimeInterval, condition: () -> Bool) {
        self.speech = speech
        self.condition = condition
        self.repeatInterval = repeatInterval
        super.init()
    }
    
    func startSpeaking() {
        timer = NSTimer.scheduledTimerWithTimeInterval(repeatInterval, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        timerDidFire(timer!)
    }
    
    func timerDidFire(timer: NSTimer) {
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
        
        if !Settings.theSettings.isModeOn(.ARM, forStatus: Configuration.theConfig.mode) {
            return false
        }
        let msp = (UIApplication.sharedApplication().delegate as! AppDelegate).msp
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
        if !settings.isModeOn(.ARM, forStatus: mode)
            || (!settings.isModeOn(.GPSHOLD, forStatus: mode) && !settings.isModeOn(.GPSHOME, forStatus: mode)) {
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
        case Good, Warning, Critical
    }
    
    override var on: Bool {
        return batteryStatus() != .Good
    }
    override var enabled: Bool {
        return userDefaultEnabled(.BatteryLowAlarm)
    }

    func batteryStatus() -> Status {
        let msp = (UIApplication.sharedApplication().delegate as! AppDelegate).msp
        if !msp.communicationEstablished || !msp.communicationHealthy {
            return .Good        // Comm lost or not connected, no need for battery alarm
        }
        let settings = Settings.theSettings
        let config = Configuration.theConfig
        let misc = Misc.theMisc
        
        if settings.features.contains(.VBat) ?? false
            && config.batteryCells > 0
            && config.voltage > 0 {
            let voltsPerCell = config.voltage / Double(config.batteryCells)
            if voltsPerCell <= misc.vbatMinCellVoltage {
                return .Critical
            } else if voltsPerCell <= misc.vbatWarningCellVoltage {
                return .Warning
            }
        }
        return .Good
    }
    
    override func voiceAlert() -> VoiceAlert {
        return VoiceAlert(speech: batteryStatus() == .Critical ? "Battery level critical" : "Battery low", repeatInterval: 10.0, condition: { self.enabled && self.on })
    }
}

class RSSILowAlarm : VoiceAlarm {
    
    override var on: Bool {
        let msp = (UIApplication.sharedApplication().delegate as! AppDelegate).msp
        if !msp.communicationEstablished || CommunicationLostAlarm().on {
            return false
        }
        let config = Configuration.theConfig
        
        return Settings.theSettings.isModeOn(.ARM, forStatus: config.mode) && config.rssi <= userDefaultAsInt(.RSSIAlarmLow)
    }
    override var enabled: Bool {
        return userDefaultEnabled(.RSSIAlarm)
    }
    
    override func voiceAlert() -> VoiceAlert! {
        return VoiceAlert(speech: Configuration.theConfig.rssi <= userDefaultAsInt(.RSSIAlarmCritical) ? "RF signal critical" : "RF signal low", repeatInterval: 10.0, condition: { self.enabled && self.on })
    }
}

class VoiceMessage: NSObject, FlightDataListener, AVSpeechSynthesizerDelegate {
    static let theVoice = VoiceMessage()
    let synthesizer = AVSpeechSynthesizer()
    
    private var alerts = [String: VoiceAlert]()
    private var speeches = Set<String>()
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    private func addAlert(name: String, alert: VoiceAlert) {
        if let oldAlert = alerts[name] {
            if oldAlert.timer?.valid ?? false {
                oldAlert.speech = alert.speech
                return
            }
        }
        alerts[name] = alert
        alert.startSpeaking()
    }

    func speak(speech: String) {
        if speeches.contains(speech) {
            return
        }
        NSLog("Speak %@", speech)
        speeches.insert(speech)
        
        let utterance = AVSpeechUtterance(string: speech)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.15
        synthesizer.speakUtterance(utterance)
    }
    
    func checkAlarm(alarm: VoiceAlarm) {
        if alarm.enabled && alarm.on {
            addAlert(NSStringFromClass(alarm.dynamicType), alert: alarm.voiceAlert())
        }
    }
    
    private func stopAlerts() {
        for alert in alerts.values {
            alert.timer?.invalidate()
        }
        alerts.removeAll()
    }
    
    func stopAll() {
        stopAlerts()
        synthesizer.stopSpeakingAtBoundary(.Word)
        speeches.removeAll()
    }
    
    // MARK: AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didStartSpeechUtterance utterance: AVSpeechUtterance) {
        let removed = speeches.remove(utterance.speechString)
        NSLog("Started speaking %@", removed ?? "nil")
    }
}
