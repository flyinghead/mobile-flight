//
//  Simulator.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 19/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
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

import Foundation
import CoreMotion
import Firebase

class Simulator : CommChannel {
    private let msp: MSPParser
    private let motionManager = CMMotionManager()

    private var closed = false
    private var timer: NSTimer?
    
    var connected: Bool { return !closed }

    init(msp: MSPParser) {
        self.msp = msp
        
        resetAircraftModel()
        
        let config = Configuration.theConfig
        config.apiVersion = "1.36"
        config.fcIdentifier = "BTFL SIM"
        config.fcVersion = "3.2.0"
        config.buildInfo = "Jul 23 2017 17:41:04"
        config.boardInfo = "IOS"
        config.boardVersion = 0
        config.uid = "1234567890"
        
        let settings = Settings.theSettings
        settings.features = [ .VBat, .RxSerial, .Failsafe, .GPS, .Sonar, .Telemetry, .CurrentMeter, .LedStrip, .Blackbox, .OSD, .AirMode ]

        settings.boxNames = [ "ARM", "AIR MODE", "ANGLE", "HORIZON", "HEADFREE", "FAILSAFE", "BEEPER", "BLACKBOX", "OSD SW" ]
        settings.boxIds = [ 0, 1, 2, 3, 4, 5, 6, 7, 8 ]
        
        settings.vbatMinCellVoltage = 3.3
        settings.vbatWarningCellVoltage = 3.5
        settings.vbatMaxCellVoltage = 4.3
        settings.batteryCapacity = 1500
        settings.currentMeterType = 1       // ADC

        settings.voltageMeterSource = 1       // ADC
        settings.currentMeterSource = 1       // ADC
        
        settings.modeRanges = [ ModeRange(id: 3, auxChannelId: 2, start: 900, end: 1500) ]
        settings.modeRangeSlots = 16
        
        settings.pidNames = [ "ROLL", "PITCH", "YAW", "ALT", "Pos", "PosR", "NavR", "LEVEL", "MAG", "VEL" ]
        settings.pidValues = [
            [ 40, 40, 30 ],
            [ 58, 50, 35 ],
            [ 70, 45, 20 ],
            [ 50, 0, 0 ],
            [ 15, 0, 0 ],
            [ 34, 14, 53 ],
            [ 25, 33, 83 ],
            [ 50, 50, 75 ],
            [ 40, 0, 0 ],
            [ 55, 55, 75 ]
        ]
        
        settings.rcInterpolation = 2    // Auto
        settings.rcInterpolationInterval = 19
        
        settings.motorPwmProtocol = 8   // DShot1200
        settings.digitalIdleOffsetPercent = 4.5
        
        settings.portConfigs = [
            PortConfig(portIdentifier: .Known(.USART1), functions: PortFunction.None, mspBaudRate: .Auto, gpsBaudRate: .Auto, telemetryBaudRate: .Auto, blackboxBaudRate: .Auto),
            PortConfig(portIdentifier: .Known(.USART2), functions: PortFunction.None, mspBaudRate: .Auto, gpsBaudRate: .Auto, telemetryBaudRate: .Auto, blackboxBaudRate: .Auto),
            PortConfig(portIdentifier: .Known(.USART3), functions: PortFunction.None, mspBaudRate: .Auto, gpsBaudRate: .Auto, telemetryBaudRate: .Auto, blackboxBaudRate: .Auto),
        ]
        
        settings.servoConfigs = [ServoConfig](count: 8, repeatedValue:
            ServoConfig(minimumRC: 1000, middleRC: 1500, maximumRC: 2000, rate: 100, minimumAngle: 0, maximumAngle: 0, rcChannel: nil, reversedSources: 0))
        
        config.activeSensors = 0xFF
        config.mode = 1 << 3        // Horizon
        config.voltage = 15.8
        config.mAhDrawn = 744
        config.rssi = 88
        config.amperage = 4.5
        
        let receiver = Receiver.theReceiver
        receiver.activeChannels = 8
        receiver.channels[0] = 1500
        receiver.channels[1] = 1500
        receiver.channels[2] = 1500
        receiver.channels[3] = 1000
        receiver.channels[4] = 2000
        receiver.channels[5] = 1500
        receiver.channels[6] = 1000
        receiver.channels[7] = 1250

        let motorData = MotorData.theMotorData
        motorData.nMotors = 4
        motorData.throttle = [ settings.minCommand, settings.minCommand, settings.minCommand, settings.minCommand, 1000, 1000, 1000, 1000]
        
        let osd = OSD.theOSD
        osd.elements = [OSDElementPosition]()
        for e in OSDElement.Elements {
            let (x, y, visible) = e.defaultPosition()
            let position = OSDElementPosition()
            position.element = e
            position.visible = visible
            position.x = x
            position.y = y
            osd.elements.append(position)
        }
        osd.timers = [ OSDTimer(source: 0, precision: 0, alarm: 0), OSDTimer(source: 1, precision: 0, alarm: 0) ]
        osd.displayedStats = [ false, true, true, true, true, true, true, true, true, true, false, true ]
        
        let dataflash = Dataflash.theDataflash
        dataflash.blackboxSupported = true
        dataflash.blackboxDevice = 2
        dataflash.sdcardState = 4
        dataflash.sdcardSupported = true
        dataflash.sdcardTotalSpace = 16 * 1024 * 1024 * 1024
        dataflash.sdcardFreeSpace = 4 * 1024 * 1024 * 1024
        
        let inavState = INavState.theINavState
        inavState.accStatus = .Known(.Healthy)
        inavState.gyroStatus = .Known(.Healthy)
        inavState.baroStatus = .Known(.Healthy)
        inavState.gpsStatus = .Known(.Healthy)
        inavState.magStatus =  .Known(.Healthy)
        
        inavState.armingFlags.insert(.NavigationSafety)
        inavState.armingFlags.remove(.OkToArm)
        
        msp.openCommChannel(self)
        msp.communicationEvent.raise(true)

        let gpsData = GPSData.theGPSData
        gpsData.distanceToHome = 4
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDelegate.currentLocation() { location in
                gpsData.fix = true
                gpsData.position = location
                gpsData.numSat = 7
            }
        }
        
        if motionManager.deviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            let queue = NSOperationQueue()
            motionManager.startDeviceMotionUpdatesToQueue(queue) { motion, error in
                if motion != nil {
                    let sensorData = SensorData.theSensorData
                    
                    switch UIDevice.currentDevice().orientation {
                    case .LandscapeLeft:
                        sensorData.pitchAngle = motion!.attitude.roll * 180.0 / M_PI + 45.0
                        sensorData.rollAngle = motion!.attitude.pitch * 180.0 / M_PI
                    case .LandscapeRight:
                        sensorData.pitchAngle = -motion!.attitude.roll * 180.0 / M_PI + 45.0
                        sensorData.rollAngle = -motion!.attitude.pitch * 180.0 / M_PI
                    default:
                        sensorData.pitchAngle = -motion!.attitude.pitch * 180.0 / M_PI + 45.0
                        sensorData.rollAngle = motion!.attitude.roll * 180.0 / M_PI
                    }
                    sensorData.heading = motion!.attitude.yaw * 180.0 / M_PI
                    
                    sensorData.accelerometerX = motion!.userAcceleration.x
                    sensorData.accelerometerY = motion!.userAcceleration.y
                    sensorData.accelerometerZ = motion!.userAcceleration.z
                    
                    sensorData.gyroscopeX = motion!.rotationRate.x * 180.0 / M_PI
                    sensorData.gyroscopeY = motion!.rotationRate.y * 180.0 / M_PI
                    sensorData.gyroscopeZ = motion!.rotationRate.z * 180.0 / M_PI
                }
            }
        }
        
        timer = NSTimer(timeInterval: 0.1, target: self, selector: #selector(Simulator.timerDidFire(_:)), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)

        Analytics.logEvent("simulator_started", parameters: nil)
    }
    
    func flushOut() {
        let array = [UInt8]()
        for code in msp.retriedMessages.keys {
            msp.callSuccessCallback(code, data: array)
        }
    }

    func close() {
        motionManager.stopDeviceMotionUpdates()
        closed = true
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func timerDidFire(timer: NSTimer?) {
        msp.receiverEvent.raise()
        msp.attitudeEvent.raise()
        msp.batteryEvent.raise()
        msp.dataReceivedEvent.raise()
        msp.motorEvent.raise()
        msp.rssiEvent.raise()
        msp.rawIMUDataEvent.raise()
        msp.gpsEvent.raise()
    }
}
