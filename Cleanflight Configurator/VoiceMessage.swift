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
    
    private var vehicle: Vehicle {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).vehicle
    }
    
    func voiceAlert() -> VoiceAlert! {
        return nil
    }
}

class CommunicationLostAlarm : VoiceAlarm {
    override var on: Bool {
        
        if !vehicle.armed.value {
            return false
        }
        return vehicle.connected.value && !(UIApplication.sharedApplication().delegate as! AppDelegate).protocolHandler.communicationHealthy
    }
    
    override var enabled: Bool {
        return userDefaultEnabled(.ConnectionLostAlarm)
    }
    
    override func voiceAlert() -> VoiceAlert {
        return VoiceAlert(speech: "Communication Lost", repeatInterval: 10.0, condition: { self.on })
    }
}

class GPSFixLostAlarm : VoiceAlarm {
    override var on: Bool {
        if CommunicationLostAlarm().on {
            return false
        }
        
        // Only alert if armed and GPS installed
        if !vehicle.armed.value || vehicle.gpsFix.value == nil {
                return false
        }
        
        return !(vehicle.gpsFix.value!)
    }
    override var enabled: Bool {
        return userDefaultEnabled(.GPSFixLostAlarm)
    }
    
    override func voiceAlert() -> VoiceAlert {
        return VoiceAlert(speech: "GPS Fix Lost", repeatInterval: 10.0, condition: { self.on })
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
        let protocolHandler = (UIApplication.sharedApplication().delegate as! AppDelegate).protocolHandler
        if !vehicle.connected.value || !protocolHandler.communicationHealthy {
            return .Good        // Comm lost or not connected, no need for battery alarm
        }
        if let criticalLevel = vehicle.batteryVoltsCritical.value {
            if vehicle.batteryVolts.value <= criticalLevel {
                return .Critical
            }
        }
        if let warningLevel = vehicle.batteryVoltsWarning.value {
            if vehicle.batteryVolts.value <= warningLevel {
                return .Warning
            }
        }
        return .Good
    }
    
    override func voiceAlert() -> VoiceAlert {
        return VoiceAlert(speech: batteryStatus() == .Critical ? "Battery level critical" : "Battery low", repeatInterval: 10.0, condition: { self.on })
    }
}

class RSSILowAlarm : VoiceAlarm {
    
    override var on: Bool {
        if !vehicle.connected.value || CommunicationLostAlarm().on {
            return false
        }
        
        return vehicle.armed.value && vehicle.rssi.value <= userDefaultAsInt(.RSSIAlarmLow)
    }
    override var enabled: Bool {
        return userDefaultEnabled(.RSSIAlarm)
    }
    
    override func voiceAlert() -> VoiceAlert! {
        return VoiceAlert(speech: vehicle.rssi.value <= userDefaultAsInt(.RSSIAlarmCritical) ? "RF signal critical" : "RF signal low", repeatInterval: 10.0, condition: { self.on })
    }
}

class VoiceMessage: NSObject, FlightDataListener {
    static let theVoice = VoiceMessage()
    let synthesizer = AVSpeechSynthesizer()
    
    private var alerts = [String: VoiceAlert]()
    
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
        let utterance = AVSpeechUtterance(string: speech)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // FIXME Why do we need to increase it??
        synthesizer.speakUtterance(utterance)
    }
    
    func checkAlarm(alarm: VoiceAlarm) {
        if alarm.enabled && alarm.on {
            addAlert(NSStringFromClass(alarm.dynamicType), alert: alarm.voiceAlert())
        }
    }
    
    func stopAlerts() {
        for alert in alerts.values {
            alert.timer?.invalidate()
        }
        alerts.removeAll()
    }
}
