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
    
    var parameters: [MAVLinkParameter?]!
    var parametersById = [String : MAVLinkParameter]()
    
    override init() {
        super.init()
        
        flightMode.addObserver(self) { newValue in
            if newValue != .UNKNOWN {
                VoiceMessage.theVoice.speak(newValue.spokenModeName())
            }
        }
    }
}

class MAVLinkParameter {
    let paramId: String
    let index: Int
    let type: MAV_PARAM_TYPE
    
    var value: Double {
        didSet(oldValue) {
            if oldValue != value {
                dirty = true
            }
        }
    }
    
    private(set) var dirty = false
    
    init(paramId: String, index: Int, type: MAV_PARAM_TYPE, value: Double) {
        self.paramId = paramId
        self.index = index
        self.type = type
        self.value = value
    }
    
    var intrisicMinimum: Double {
        switch type {
        case MAV_PARAM_TYPE_REAL32:
            return Double(-Float.infinity)
        case MAV_PARAM_TYPE_INT32:
            return Double(Int32.min)
        case MAV_PARAM_TYPE_INT16:
            return Double(Int16.min)
        case MAV_PARAM_TYPE_INT8:
            return Double(Int8.min)
        default:
            return Double(-Float.infinity)
        }
    }
    
    var intrisicMaximum: Double {
        switch type {
        case MAV_PARAM_TYPE_REAL32:
            return Double(Float.infinity)
        case MAV_PARAM_TYPE_INT32:
            return Double(Int32.max)
        case MAV_PARAM_TYPE_INT16:
            return Double(Int16.max)
        case MAV_PARAM_TYPE_INT8:
            return Double(Int8.max)
        default:
            return Double(Float.infinity)
        }
    }
    
    var intrisicIncrement: Double {
        if type == MAV_PARAM_TYPE_REAL32 {
            return 0        // No default increment for floating point numbers
        } else {
            return 1
        }
    }
}