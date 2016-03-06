//
//  Vehicle.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 06/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class Vehicle {
    var connected = ObservableBool(false)
    var armed = ObservableBool(false)
    var replaying = ObservableBool(false)
    var noDataReceived = ObservableBool(false)
    
    var rollAngle = ObservableDouble(0.0)
    var pitchAngle = ObservableDouble(0.0)
    
    var heading = ObservableDouble(0.0)
    var turnRate = ObservableDouble(0.0)
    
    var speed = ObservableDouble(0.0)
    
    var altitude = ObservableDouble(0.0)
    var verticalSpeed = ObservableDouble(0.0)
    
    var rssi = ObservableInt(0)
    
    var timeCounter = ObservableDouble(0.0)
    
    var gpsFix = ObservableBool(false)
    var gpsNumSats = ObservableInt(0)
    var distanceToHome = ObservableDouble(0.0)
    
    var batteryVolts = ObservableDouble(0.0)
    var batteryAmps = ObservableDouble(0.0)
    var batteryConsumedMAh = ObservableDouble(0.0)
}