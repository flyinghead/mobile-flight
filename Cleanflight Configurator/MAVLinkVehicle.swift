//
//  MAVLinkVehicle.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 12/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class MAVLinkVehicle : Vehicle {
    var flightMode = EquatableObservable<ArduCopterFlightMode>(.UNKNOWN)
    
    var autopilotMessage = VehicleEvent<(severity: MAV_SEVERITY, message: String)>()
    
    var batteryRemaining = ObservableInt(100)
    
    var currentMissionItem = ObservableInt(0)
    
    var fenceBreached = ObservableBool(false)
    var fenceBreachType = EquatableObservable<FENCE_BREACH>(FENCE_BREACH_NONE)
    
    override init() {
        super.init()
        
        flightMode.addObserver(self) { newValue in
            if newValue != .UNKNOWN {
                VoiceMessage.theVoice.speak(newValue.spokenModeName())
            }
        }
    }
}