//
//  MSPVehicle.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 08/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class MSPVehicle : Vehicle {
    var baroMode = ObservableBool(false)
    var sonarMode = ObservableBool(false)
    var altHoldMode = ObservableBool(false)
    var failsafeMode = ObservableBool(false)
    var angleMode = ObservableBool(false)
    var horizonMode = ObservableBool(false)
    var airMode = ObservableBool(false)
    var magMode = ObservableBool(false)
    var gpsHoldMode = ObservableBool(false)
    var gpsHomeMode = ObservableBool(false)
    
    var camStabMode = ObservableBool(false)
    var calibrateMode = ObservableBool(false)
    var telemetryMode = ObservableBool(false)
    var blackboxMode = ObservableBool(false)
    var autotuneMode = ObservableBool(false)
}