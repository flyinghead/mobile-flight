//
//  Vehicle.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 06/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation
import MapKit

class Vehicle {
    var connected = ObservableBool(false)
    var replaying = ObservableBool(false)
    var noDataReceived = ObservableBool(false)      // ???
    
    // Armed state and counters
    var armed = ObservableBool(false)
    var lastArmedDate: NSDate?
    var totalArmedTime: NSTimeInterval {
        return _totalArmedTime + -(lastArmedDate?.timeIntervalSinceNow ?? 0)
    }
    var lastArmedTime: Double {
        if !armed.value {
            // Disarmed
            return _lastArmedTime
        } else {
            // Armed
            return -(lastArmedDate?.timeIntervalSinceNow ?? 0.0)
        }
    }
    private var _lastArmedTime: NSTimeInterval = 0.0
    private var _totalArmedTime = 0.0

    // Attitude
    var rollAngle = ObservableDouble(0.0)
    var pitchAngle = ObservableDouble(0.0)
    
    var heading = ObservableDouble(0.0)
    var turnRate = ObservableDouble(0.0)
    
    var speed = ObservableDouble(0.0)
    var maxSpeed = ObservableDouble(0.0)
    
    var altitude = ObservableDouble(0.0)
    var maxAltitude = ObservableDouble(0.0)
    
    var verticalSpeed = ObservableDouble(0.0)
    
    // RC
    var rcChannels = NillableObservableArray<Int>()     // Order AETR
    var rssi = NillableObservableInt()
    var sikRssi = NillableObservableInt()
    var rcOutEnabled = ObservableBool(false)            // FIXME Need a way to enable this when it's allowed
    var rcChannelsNativeOrder = [ 0, 1, 2, 3 ]
    var rcCommandsProvider: RcCommandsProvider?
    
    // GPS
    var gpsFix = NillableObservableBool()       // nil if no GPS
    var gpsNumSats = ObservableInt(0)
    var distanceToHome = ObservableDouble(0.0)
    var maxDistanceToHome = ObservableDouble(0.0)
    var position = NillableObservablePosition()
    var lastKnownGoodPosition = NillableObservablePosition()
    var positions = NillableObservableArray<Position3D>()
    
    // Battery
    var batteryVolts = ObservableDouble(0.0)
    var batteryVoltsWarning = NillableObservableDouble()
    var batteryVoltsCritical = NillableObservableDouble()
    var batteryAmps = ObservableDouble(0.0)
    var maxBatteryAmps = ObservableDouble(0.0)
    var batteryConsumedMAh = ObservableInt(0)
    
    // Navigation
    var navigationHeading = NillableObservableDouble()
    var altitudeHold = NillableObservableDouble()
    var navigationSpeed = NillableObservableDouble()
    var waypointDistance = NillableObservableDouble()
    var waypointPosition = NillableObservablePosition3D()
    var homePosition = NillableObservablePosition3D()
    
    init() {
        armed.addObserver(self, listener: { newValue in
            if newValue {
                self.lastArmedDate = NSDate()
            } else {
                if self.lastArmedDate != nil {
                    self._lastArmedTime = -self.lastArmedDate!.timeIntervalSinceNow
                    self.lastArmedDate = nil
                    self._totalArmedTime += self.lastArmedTime
                }
            }
        })
        speed.addObserver(self, listener: { newValue in
            if newValue > self.maxSpeed.value {
                self.maxSpeed.value = newValue
            }
        })
        altitude.addObserver(self, listener: { newValue in
            if newValue > self.maxAltitude.value {
                self.maxAltitude.value = newValue
            }
        })
        distanceToHome.addObserver(self, listener: { newValue in
            if newValue > self.maxDistanceToHome.value {
                self.maxDistanceToHome.value = newValue
            }
        })
        batteryAmps.addObserver(self, listener: { newValue in
            if newValue > self.maxBatteryAmps.value {
                self.maxBatteryAmps.value = newValue
            }
        })
        position.addObserver(self, listener: { newValue in
            if (newValue?.latitude != 0 || newValue?.longitude != 0) && self.gpsFix.value == true {
                self.lastKnownGoodPosition.value = self.position.value
                
                let position3d = Position3D(position2d: newValue!, altitude: self.altitude.value)
                if let positions = self.positions.value {
                    if positions.count == 0 || positions.last! != position3d {
                        self.positions.value!.append(position3d)
                        self.positions.notifyListeners()
                    }
                } else {
                    self.positions.value = [ position3d ]
                }
            }
        })
    }
}

struct Position : Equatable {
    var latitude: Double
    var longitude: Double
    
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
}

func ==(lhs: Position, rhs: Position) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

class NillableObservablePosition : Observable<Position?> {
    init() {
        super.init(nil)
    }
    
    override func areEqual(o1: Position?, _ o2: Position?) -> Bool {
        if o1 == nil {
            return o2 == nil
        } else if o2 == nil {
            return false
        } else {
            return o1!.latitude == o2!.latitude && o1!.longitude == o2!.longitude
        }
    }
}

struct Position3D : Equatable {
    var position2d: Position
    var altitude: Double
}

func ==(lhs: Position3D, rhs: Position3D) -> Bool {
    return lhs.position2d == rhs.position2d && lhs.altitude == rhs.altitude
}

class NillableObservablePosition3D : Observable<Position3D?> {
    init() {
        super.init(nil)
    }
    
    override func areEqual(o1: Position3D?, _ o2: Position3D?) -> Bool {
        if o1 == nil {
            return o2 == nil
        } else if o2 == nil {
            return false
        } else {
            return o1!.position2d.latitude == o2!.position2d.latitude && o1!.position2d.longitude == o2!.position2d.longitude && o1!.altitude == o2!.altitude
        }
    }
}

