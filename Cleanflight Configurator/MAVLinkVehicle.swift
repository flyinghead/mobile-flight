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
    var missionItems = [APMNavigationCommand?]()
    
    var fenceBreached = ObservableBool(false)
    var fenceBreachType = EquatableObservable<FENCE_BREACH>(FENCE_BREACH_NONE)
    
    var parametersById = [String : MAVLinkParameter]()
    var parametersLoaded = false
    
    var firmwareVersion = NillableObservableString()

    var systemStatus = EquatableObservable<MAV_STATE>(MAV_STATE_UNINIT)
    var frameType = NillableObservable<MAV_TYPE>()

    var motorCount: Int {
        guard let frameType = self.frameType.value else {
            return 0
        }
        switch frameType {
        case MAV_TYPE_TRICOPTER, MAV_TYPE_QUADROTOR:
            return 4
        case MAV_TYPE_HEXAROTOR:
            return 6
        case MAV_TYPE_OCTOROTOR:
            return 8
        case MAV_TYPE_HELICOPTER:
            return 0
        default:
            return 8
        }
    }
    
    private let mavlink: MAVLink
    
    private var tlogDirectory: NSURL?
    
    init(mavlink: MAVLink) {
        self.mavlink = mavlink
        super.init()
        
        flightMode.addObserver(self) { newValue in
            if newValue != .UNKNOWN {
                VoiceMessage.theVoice.speak(newValue.spokenModeName())
                
                if (newValue == .LOITER || newValue == .POSHOLD) && self.position.value != nil {
                    self.waypointPosition.value = Position3D(position2d: self.position.value!, altitude: self.altitude.value)
                }
                self.setCurrentMissionPositionAndAltitudeTargets()
            }
        }
        
        currentMissionItem.addObserver(self) { _ in
            self.setCurrentMissionPositionAndAltitudeTargets()
        }
    }
    
    private func setCurrentMissionPositionAndAltitudeTargets() {
        if self.flightMode.value == .AUTO && currentMissionItem.value < self.missionItems.count {
            if let missionItem = self.missionItems[currentMissionItem.value] {
                self.altitudeHold.value = missionItem.targetAltitude(self.altitudeHold.value ?? self.altitude.value)
                
                if self.waypointPosition.value != nil || self.position.value != nil {
                    let targetPosition = missionItem.targetPosition(self.waypointPosition.value ?? Position3D(position2d: self.position.value!, altitude: self.altitude.value))
                    self.waypointPosition.value = targetPosition ?? self.homePosition.value
                }
            }
        }
    }
    
    override func startFlightlogRecorder() {
        TLogFile.openForWriting(flightLogDirectory, protocolHandler: mavlink)
    }
    
    override func stopFlightRecorder() {
        TLogFile.close(mavlink)
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