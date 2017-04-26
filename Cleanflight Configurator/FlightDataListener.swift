//
//  DataListener.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

@objc protocol FlightDataListener : class {
    optional func receivedData()        // for Configuration and Misc right now
    optional func receivedGpsData()
    optional func receivedReceiverData()
    optional func receivedSensorData()
    optional func receivedMotorData()
    optional func communicationStatus(status: Bool)     // true: communication established, false: communication closed permanently
    optional func receivedRawIMUData()
    optional func receivedAltitudeData()
    optional func receivedSonarData()
    optional func received3drRssiData()                   // RSSI data from 3DR Radio
}
