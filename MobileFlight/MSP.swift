//
//  MSP.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
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
import UIKit
import MapKit

class MessageRetryHandler {
    let code: MSP_code
    let data: [UInt8]?
    let callback: ((_ success: Bool) -> Void)?
    let maxTries: Int
    var timer: Timer?
    var cancelled = false
    
    var tries = 0
    
    init(code: MSP_code, data: [UInt8]?, maxTries: Int, callback: ((_ success: Bool) -> Void)?) {
        self.code = code
        self.data = data
        self.maxTries = maxTries
        self.callback = callback
    }
}

class DataMessageRetryHandler : MessageRetryHandler {
    let dataCallback: (_ data: [UInt8]?) -> Void
    
    init(code: MSP_code, data: [UInt8]?, maxTries: Int, callback: @escaping (_ data: [UInt8]?) -> Void) {
        self.dataCallback = callback
        super.init(code: code, data: data, maxTries: maxTries, callback: nil)
    }
}

class MSPParser {
    let motorEvent = Event<Void>()
    let rawIMUDataEvent = Event<Void>()
    let altitudeEvent = Event<Void>()
    let sonarEvent = Event<Void>()
    let rssiEvent = Event<Void>()
    let attitudeEvent = Event<Void>()
    let navigationEvent = Event<Void>()
    let flightModeEvent = Event<Void>()
    let batteryEvent = Event<Void>()
    let gpsEvent = Event<Void>()
    let receiverEvent = Event<Void>()
    let communicationEvent = Event<Bool>()
    let dataReceivedEvent = Event<Void>()
    let sensorStatusEvent = Event<Void>()
    let statusEvent = Event<Void>()     // MSP_STATUS[_EX] received, fires up to 10 times/s
    
    let CHANNEL_FORWARDING_DISABLED = 0xFF
    let codec = MSPCodec()
    let latencyMsgs = Set<MSP_code>(arrayLiteral: .msp_STATUS, .msp_RAW_GPS, .msp_COMP_GPS, .msp_ALTITUDE, .msp_ATTITUDE, .msp_ANALOG, .msp_WP)
    
    var datalog: FileHandle?
    var datalogStart: Date?
    
    fileprivate var outputQueue = [[UInt8]]()
    
    fileprivate var commChannel: CommChannel?
    
    var retriedMessages = Dictionary<MSP_code, MessageRetryHandler>()
    let retriedMessageLock = NSObject()
    
    var cliViewController: CLIViewController?
    
    fileprivate var receiveStats = [(date: Date, size: Int)]()
    fileprivate var sentDates = [MSP_code : Date]()
    fileprivate var msgLatencies = [MSP_code : Double]()
    
    var incomingBytesPerSecond: Int {
        var byteCount = 0
        objc_sync_enter(self)
        for (date, size) in receiveStats {
            if -date.timeIntervalSinceNow >= 0.5 {
                break
            }
            byteCount += size
        }
        objc_sync_exit(self)
        return byteCount * 2
    }
    
    var latency: Double {
        objc_sync_enter(self)
        if msgLatencies.isEmpty {
            objc_sync_exit(self)
            return 0.2      // Unknown. Let's pretend it's 200ms
        }
        var latencies = [Double]()
        for mspCode in msgLatencies.keys {
            var latency = msgLatencies[mspCode]!
            if let sentDate = sentDates[mspCode], -sentDate.timeIntervalSinceNow > latency {
                latency = -sentDate.timeIntervalSinceNow
            }
            latencies.append(min(latency, 1.0))
        }
        objc_sync_exit(self)

        latencies.sort()
        if latencies.count % 2 == 1 {
            return latencies[latencies.count / 2]
        } else {
            return (latencies[latencies.count / 2 - 1] + latencies[latencies.count / 2]) / 2
        }
    }
    
    func read(_ data: [UInt8]) {
        if cliViewController != nil {
            cliViewController!.receive(data)
            return
        }
        
        objc_sync_enter(self)
        if datalog != nil {
            var logData = [UInt8]()
            // Timestamp in milliseconds since start of logging
            logData.append(contentsOf: writeUInt32(Int(round(-datalogStart!.timeIntervalSinceNow * 1000))))
            logData.append(contentsOf: writeUInt16(min(data.count, Int(UINT16_MAX))))
            datalog!.write(Data(bytes: UnsafePointer<UInt8>(logData), count: logData.count))
            datalog!.write(Data(bytes: UnsafePointer<UInt8>(data), count: data.count))
        }
        //NSLog("Received %d bytes", data.count)
        
        receiveStats.insert((Date(), data.count), at: 0)
        while receiveStats.count > 500 {
            receiveStats.removeLast()
        }
        objc_sync_exit(self)
        
        for b in data {
            if let (success, mspCode, message) = codec.decode(b) {
                objc_sync_enter(self)
                if let date = self.sentDates[mspCode] {
                    msgLatencies[mspCode] = -date.timeIntervalSinceNow
                    self.sentDates.removeValue(forKey: mspCode)
                }
                objc_sync_exit(self)
                if success {
                    if processMessage(mspCode, message: message) {
                        callSuccessCallback(mspCode, data: message)
                        dataReceivedEvent.raiseDispatch()
                    } else {
                        callErrorCallback(mspCode)
                    }
                } else {
                    //NSLog("MSP %d unsupported or invalid", mspCode.rawValue)
                    callErrorCallback(mspCode)
                }
            }
        }
    }

    func processMessage(_ code: MSP_code, message: [UInt8]) -> Bool {
        let settings = Settings.theSettings
        let config = Configuration.theConfig
        let gpsData = GPSData.theGPSData
        let receiver = Receiver.theReceiver
        let misc = Misc.theMisc
        let sensorData = SensorData.theSensorData
        let motorData = MotorData.theMotorData
        let inavConfig = INavConfig.theINavConfig
        let inavState = INavState.theINavState
        
        switch code {
        case .msp_IDENT:    // Deprecated, removed in CF 2.0 / BF 3.2
            if message.count < 7 {
                return false
            }
            config.version = String(format:"%d.%02d", message[0] / 100, message[0] % 100)
            settings.mixerConfiguration = Int(message[1])
            config.mspVersion = Int(message[2])
            config.capability = readUInt32(message, index: 3)
            
        case .msp_STATUS, .msp_STATUS_EX:
            if message.count < 11 {
                return false
            }
            let previousActiveSensors = config.activeSensors
            let previousMode = config.mode
            let previousArmingFlags = inavState.armingFlags
            
            config.cycleTime = readUInt16(message, index: 0)
            config.i2cError = readUInt16(message, index: 2)
            config.activeSensors = readUInt16(message, index: 4)
            config.mode = readUInt32(message, index: 6)
            config.profile = Int(message[10])
            if message.count >= 13 {
                config.systemLoad = readUInt16(message, index: 11)
                if message.count >= 15 {
                    if config.isINav {
                        inavState.armingFlags = INavArmingFlags(rawValue: readUInt16(message, index: 13))
                        inavState.accCalibAxis = Int(message[15])
                    } else {
                        config.rateProfile = Int(message[14])
                    }
                    // TODO Additional flightModeFlags
                    // TODO Arming Disable Flags
                }
            }
            statusEvent.raiseDispatch()
            if previousMode != config.mode {
                flightModeEvent.raiseDispatch()
            }
            if previousActiveSensors != config.activeSensors || previousArmingFlags != inavState.armingFlags {
                sensorStatusEvent.raiseDispatch()
            }
            
        case .msp_RAW_IMU:
            if message.count < 18 {
                return false
            }
            // 512 for mpu6050, 256 for mma
            // currently we are unable to differentiate between the sensor types, so we are going with 512
            sensorData.accelerometerX = Double(readInt16(message, index: 0)) / 512.0
            sensorData.accelerometerY = Double(readInt16(message, index: 2)) / 512.0
            sensorData.accelerometerZ = Double(readInt16(message, index: 4)) / 512.0
            // properly scaled
            sensorData.gyroscopeX = Double(readInt16(message, index: 6)) * (4 / 16.4)
            sensorData.gyroscopeY = Double(readInt16(message, index: 8)) * (4 / 16.4)
            sensorData.gyroscopeZ = Double(readInt16(message, index: 10)) * (4 / 16.4)
            // no clue about scaling factor
            sensorData.magnetometerX = Double(readInt16(message, index: 12)) / 1090
            sensorData.magnetometerY = Double(readInt16(message, index: 14)) / 1090
            sensorData.magnetometerZ = Double(readInt16(message, index: 16)) / 1090
            
            rawIMUDataEvent.raiseDispatch()
        
        case .msp_SERVO:
            if message.count < 16 {
                return false
            }
            for i in 0 ..< 8 {
                motorData.servoValue[i] = readUInt16(message, index: i*2)
            }
            motorEvent.raiseDispatch()
        
        case .msp_SERVO_CONFIGURATIONS:
            let servoConfSize = 14
            var servoConfigs = [ServoConfig]()
            for i in 0 ..< message.count / servoConfSize {
                let offset = i * servoConfSize
                var servoConfig = ServoConfig(
                    minimumRC: readInt16(message, index: offset),
                    middleRC: readInt16(message, index: offset + 4),
                    maximumRC: readInt16(message, index: offset + 2),
                    rate: readInt8(message, index: offset + 6),
                    minimumAngle: Int(message[offset + 7]),
                    maximumAngle: Int(message[offset + 8]),
                    rcChannel: Int(message[offset + 9]),
                    reversedSources: readUInt32(message, index: offset + 10)
                )
                if servoConfig.rcChannel == CHANNEL_FORWARDING_DISABLED {
                    servoConfig.rcChannel = nil
                }
                servoConfigs.append(servoConfig)
            }
            if servoConfigs.count == 0 {
                return false
            }
            settings.servoConfigs = servoConfigs
        
        case .msp_MOTOR:
            if message.count < 16 {
                return false
            }
            var nMotors = 0
            for i in 0 ..< 8 {
                motorData.throttle[i] = readUInt16(message, index: i*2)
                if (motorData.throttle[i] > 0) {
                    nMotors += 1
                }
            }
            motorData.nMotors = nMotors
            motorEvent.raiseDispatch()
        
        case .msp_UID:
            if message.count < 12 {
                return false
            }
            config.uid = String(format: "%04x%04x%04x", readUInt32(message, index: 0), readUInt32(message, index: 4), readUInt32(message, index: 8))
            
        case .msp_ACC_TRIM:
            if message.count < 4 {
                return false
            }
            misc.accelerometerTrimPitch = readInt16(message, index: 0)
            misc.accelerometerTrimRoll = readInt16(message, index: 2)
            
        case .msp_RC:
            var channelCount = message.count / 2
            if (channelCount > receiver.channels.count) {
                NSLog("MSP_RC Received %d channels instead of %d max", channelCount, receiver.channels.count)
                channelCount = receiver.channels.count
            }
            receiver.activeChannels = channelCount
            for i in 0..<channelCount {
                receiver.channels[i] = Int(readUInt16(message, index: (i * 2)));
            }
            receiverEvent.raiseDispatch()
            
        case .msp_RAW_GPS:
            if message.count < 16 {
                return false
            }

            gpsData.fix = message[0] != 0
            gpsData.numSat = Int(message[1])
            gpsData.position = GPSLocation(latitude: Double(readInt32(message, index: 2)) / 10000000, longitude: Double(readInt32(message, index: 6)) / 10000000)
            gpsData.altitude = readUInt16(message, index: 10)
            gpsData.speed = Double(readUInt16(message, index: 12)) * 0.036           // km/h = cm/s / 100 * 3.6
            gpsData.headingOverGround = Double(readUInt16(message, index: 14)) / 10  // 1/10 degree to degree
            gpsEvent.raiseDispatch()
            
        case .msp_COMP_GPS:
            if message.count < 5 {
                return false
            }
            gpsData.distanceToHome = readUInt16(message, index: 0)
            gpsData.directionToHome = readUInt16(message, index: 2)
            gpsData.update = Int(message[4])
            gpsEvent.raiseDispatch()
            
        case .msp_ATTITUDE:
            if message.count < 6 {
                return false
            }
            sensorData.rollAngle = Double(readInt16(message, index: 0)) / 10.0   // x
            sensorData.pitchAngle = Double(readInt16(message, index: 2)) / 10.0   // y
            sensorData.heading = Double(readInt16(message, index: 4))          // z
            attitudeEvent.raiseDispatch()
            
        case .msp_ALTITUDE:
            if message.count < 6 {
                return false
            }
            sensorData.altitude = Double(readInt32(message, index: 0)) / 100.0      // cm
            sensorData.variometer = Double(readInt16(message, index: 4)) / 100.0    // cm/s
            // iNAV baro latest alt (4)
            altitudeEvent.raiseDispatch()
            
        case .msp_SONAR:
            if message.count < 4 {
                return false
            }
            sensorData.sonar = readInt32(message,  index: 0);
            sonarEvent.raiseDispatch()

        case .msp_ANALOG:
            if message.count < 7 {
                return false
            }
            config.voltage = Double(message[0]) / 10                                    // 1/10 V
            config.mAhDrawn = readUInt16(message, index: 1)
            config.rssi = readUInt16(message, index: 3) * 100 / 1023                    // 0-1023
            config.amperage = Double(readInt16(message, index: 5)) / 100                // 1/100 A
            rssiEvent.raiseDispatch()
            batteryEvent.raiseDispatch()
            
        case .msp_RC_TUNING:
            if message.count < 11 {
                return false
            }
            settings.rcRate = Double(message[0]) / 100
            settings.rcExpo = Double(message[1]) / 100
            settings.rollSuperRate = Double(message[2]) / 100
            settings.pitchSuperRate = Double(message[3]) / 100
            settings.yawSuperRate = Double(message[4]) / 100
            settings.tpaRate = Double(message[5]) / 100
            settings.throttleMid = Double(message[6]) / 100
            settings.throttleExpo = Double(message[7]) / 100
            settings.tpaBreakpoint = readUInt16(message, index: 8)
            settings.yawExpo = Double(message[10]) / 100
            if message.count >= 12 {
                settings.yawRate = Double(message[11]) / 100
            }
            
        case .msp_PID:
            settings.pidValues = [[Double]]()
            for i in 0..<message.count / 3 {
                settings.pidValues!.append([Double]())

                settings.pidValues![i].append(Double(message[i*3]))
                settings.pidValues![i].append(Double(message[i*3 + 1]))
                settings.pidValues![i].append(Double(message[i*3 + 2]))
            }
            
        case .msp_ARMING_CONFIG:
            if message.count < 2 {
                return false
            }
            settings.autoDisarmDelay = Int(message[0])
            settings.disarmKillSwitch = message[1] != 0
            
        case .msp_MISC: // 22 bytes
            if message.count < 18 {
                return false
            }
            var offset = 0
            settings.midRC = readInt16(message, index: offset)
            offset += 2
            settings.minThrottle = readInt16(message, index: offset) // 0-2000
            offset += 2
            settings.maxThrottle = readInt16(message, index: offset) // 0-2000
            offset += 2
            settings.minCommand = readInt16(message, index: offset) // 0-2000
            offset += 2
            settings.failsafeThrottle = readInt16(message, index: offset) // 0-2000
            offset += 2
            settings.gpsType = Int(message[offset])
            offset += 2
            settings.gpsUbxSbas = Int(message[offset])
            offset += 2
            settings.rssiChannel = Int(message[offset])
            offset += 2
            settings.magDeclination = Double(readInt16(message, index: offset)) / 10 // -18000-18000
            if message.count >= 22 {
                offset += 2;
                settings.vbatScale = Int(message[offset]) // 10-200
                offset += 1
                settings.vbatMinCellVoltage = Double(message[offset]) / 10; // 10-50
                offset += 1
                settings.vbatMaxCellVoltage = Double(message[offset]) / 10; // 10-50
                offset += 1
                settings.vbatWarningCellVoltage = Double(message[offset]) / 10; // 10-50
                batteryEvent.raiseDispatch()
            }
            
        case .msp_BOXNAMES:
            settings.boxNames = [String]()
            var buf = [UInt8]()
            for i in 0 ..< message.count {
                if message[i] == 0x3B {     // ; (delimiter char)
                    settings.boxNames!.append(NSString(bytes: buf, length: buf.count, encoding: String.Encoding.ascii.rawValue)! as String)
                    buf.removeAll()
                } else {
                    buf.append(message[i])
                }
            }
            
        case .msp_PIDNAMES:
            settings.pidNames = [String]()
            var buf = [UInt8]()
            for i in 0 ..< message.count {
                if message[i] == 0x3B {     // ; (delimiter char)
                    settings.pidNames?.append(NSString(bytes: buf, length: buf.count, encoding: String.Encoding.ascii.rawValue)! as String)
                    buf.removeAll()
                } else {
                    buf.append(message[i])
                }
            }
            
        case .msp_WP:
            if config.isINav {
                if message.count < 21 {
                    return false
                }
            } else {
                if message.count < 15 {
                    return false
                }
            }
            var offset = 0
            let wpNum = Int(message[offset])
            offset += 1
            var action: INavWaypointAction?
            if config.isINav {
                // 1: waypoint, 4: RTH
                action = INavWaypointAction(value: Int(message[offset]))
                offset += 1
            }
            let position = GPSLocation(latitude: Double(readInt32(message, index: offset)) / 10000000, longitude: Double(readInt32(message, index: offset + 4)) / 10000000)
            offset += 8
            let altitude = Double(readInt32(message, index: offset)) / 100    // cm
            offset += 4
            if wpNum == 0 {     // Special waypoint: Home position
                if position.latitude == 0 && position.longitude == 0 {
                    // No home position
                    gpsData.homePosition = nil
                } else {
                    gpsData.homePosition = position
                }
                gpsEvent.raiseDispatch()
            }
            else if (!config.isINav && wpNum == 16) || wpNum == 255 {     // Cleanflight: 16, INav: 255
                // FIXME Not sure if it's the pos hold position In INav
                gpsData.posHoldPosition = position
                if !config.isINav {
                    // In INav, it's the current GPS altitude..
                    sensorData.altitudeHold = altitude
                }
                if !config.isINav {
                    sensorData.headingHold = Double(readInt16(message, index: offset))          // degrees - Custom firmware by Raph
                }
                offset += 2
                navigationEvent.raiseDispatch()
            }
            else if config.isINav && wpNum >= 1 {
                let p1 = Int(readInt16(message, index: offset))     // Speed for .Waypoint action in cm/s (must be > 0.5 m/s and < general.max_speed (3 m/s by default))
                offset += 2
                let p2 = Int(readInt16(message, index: offset))
                offset += 2
                let p3 = Int(readInt16(message, index: offset))
                offset += 2
                let last = Int(message[offset]) != 0
                let waypoint = Waypoint(number: wpNum, action: action!, position: position, altitude: altitude, param1: p1, param2: p2, param3: p3, last: last)
                inavState.setWaypoint(waypoint)
            }
            
        case .msp_BOXIDS:
            settings.boxIds = [Int]()
            for i in 0 ..< message.count {
                settings.boxIds!.append(Int(message[i]))
            }
            
        case .msp_GPSSVINFO:
            if message.count < 1 {
                return false
            }
            let numSat = Int(message[0])
            if message.count < numSat * 4 + 1 {
                return false
            }
            var sats = [Satellite]()
            for i in 0..<numSat {
                sats.append(Satellite(channel: Int(message[i * 4 + 1]), svid: Int(message[i * 4 + 2]), quality: GpsSatQuality(rawValue: Int(message[i * 4 + 3])), cno: Int(message[i * 4 + 4])))
            }
            gpsData.satellites = sats
            
            gpsEvent.raiseDispatch()
            
        case .msp_RX_CONFIG:
            if message.count < 8 {
                return false
            }
            settings.serialRxType = Int(message[0])
            settings.maxCheck = readUInt16(message, index: 1)
            settings.midRC = readUInt16(message, index: 3)
            settings.minCheck = readUInt16(message, index: 5)
            settings.spektrumSatBind = Int(message[7])
            if message.count >= 12 {
                settings.rxMinUsec = readUInt16(message, index: 8)
                settings.rxMaxUsec = readUInt16(message, index: 10)
                if message.count >= 14 {
                    settings.rcInterpolation = Int(message[12])
                    settings.rcInterpolationInterval = Int(message[13])
                    if message.count >= 16 {
                        settings.airmodeActivateThreshold = readUInt16(message, index: 14)
                        if message.count >= 22 {
                            settings.rxSpiProtocol = Int(message[16])
                            settings.rxSpiId = readUInt32(message, index: 17)
                            settings.rxSpiChannelCount = Int(message[21])
                            if message.count >= 23 {
                                settings.fpvCamAngleDegrees = Int(message[22])
                            }
                        }
                    }
                }
            }
            
        case .msp_FAILSAFE_CONFIG:
            if message.count < 8 {
                return false
            }
            settings.failsafeDelay = Double(message[0]) / 10
            settings.failsafeOffDelay = Double(message[1]) / 10
            settings.failsafeThrottle = readInt16(message, index: 2) // 0-2000
            settings.failsafeKillSwitch = message[4] != 0
            settings.failsafeThrottleLowDelay = Double(readUInt16(message, index: 5)) / 10
            settings.failsafeProcedure = Int(message[7])
            // INAV failsafe_recovery_delay (1)
            
        case .msp_RXFAIL_CONFIG:
            if message.count % 3 != 0 {
                return false
            }
            settings.rxFailMode = [Int]()
            settings.rxFailValue = [Int]()
            for i in 0..<message.count / 3 {
                settings.rxFailMode!.append(Int(message[i * 3]))
                settings.rxFailValue!.append(readUInt16(message, index: i * 3 + 1))
            }
            
        case .msp_RX_MAP:
            for (i, b) in message.enumerated() {
                if (i >= receiver.map.count) {
                    NSLog("MSP_RX_MAP received %d channels instead of %d", message.count, receiver.map.count)
                    break
                }
                receiver.map[i] = Int(b)
            }
            receiverEvent.raiseDispatch()
        
        /*
        case .MSP_BF_CONFIG:        // Deprecated, removed in CF 1.14+
            if message.count < 16 {
                return false
            }
            settings.mixerConfiguration = Int(message[0])
            settings.features = BaseFlightFeature(rawValue: readUInt32(message, index: 1))
            settings.serialRxType = Int(message[5])
            settings.boardAlignRoll = Int(readInt16(message, index: 6))
            settings.boardAlignPitch = Int(readInt16(message, index: 8))
            settings.boardAlignYaw = Int(readInt16(message, index: 10))
            settings.currentScale = Int(readInt16(message, index: 12))
            settings.currentOffset = Int(readInt16(message, index: 14))
        */

        // Cleanflight-specific
        case .msp_API_VERSION:
            if message.count < 3 {
                return false
            }
            config.msgProtocolVersion = Int(message[0])
            config.apiVersion = String(format: "%d.%d", message[1], message[2])
            
        case .msp_FC_VARIANT:
            if message.count < 4 {
                return false
            }
            config.fcIdentifier = String(format: "%c%c%c%c", message[0], message[1], message[2], message[3])
            
        case .msp_FC_VERSION:
            if message.count < 3 {
                return false
            }
            config.fcVersion = String(format: "%d.%d.%d", message[0], message[1], message[2])
            
        case .msp_BUILD_INFO:
            if message.count < 19 {
                return false
            }
            let date = NSString(bytes: message, length: 11, encoding: String.Encoding.utf8.rawValue)
            let time = NSString(bytes: Array<UInt8>(message[11..<19]), length: 8, encoding: String.Encoding.utf8.rawValue)
            /*
            if message.count >= 26 {
                let revision  = NSString(bytes: Array<UInt8>(message[19..<26]), length: 7, encoding: NSUTF8StringEncoding)
                NSLog("revision %@", revision!)
            }
            */
            config.buildInfo = String(format: "%@ %@", date!, time!)
            
        case .msp_BOARD_INFO:
            if message.count < 6 {
                return false
            }
            config.boardInfo = String(format: "%c%c%c%c", message[0], message[1], message[2], message[3])
            config.boardVersion = readUInt16(message, index: 4)
            
        case .msp_MODE_RANGES:
            let nRanges = message.count / 4
            var modeRanges = [ModeRange]()
            for i in 0 ..< nRanges {
                let offset = i * 4
                let start = 900 + Int(message[offset+2]) * 25
                let end = 900 + Int(message[offset+3]) * 25
                if start < end {
                    modeRanges.append(ModeRange(
                        id: Int(message[offset]),
                        auxChannelId: Int(message[offset+1]),
                        start: start,
                        end: end))
                }
            }
            settings.modeRanges = modeRanges
            settings.modeRangeSlots = nRanges
            
        case .msp_CF_SERIAL_CONFIG:
            let nPorts = message.count / 7
            if nPorts < 1 {
                return false
            }
            settings.portConfigs = [PortConfig]()
            for i in 0..<nPorts {
                let offset = i * 7
                settings.portConfigs!.append(PortConfig(portIdentifier: PortIdentifier(value: Int(message[offset])), functions: PortFunction(rawValue: readUInt16(message, index: offset+1)), mspBaudRate: BaudRate(value: Int(message[offset+3])), gpsBaudRate: BaudRate(value: Int(message[offset+4])), telemetryBaudRate: BaudRate(value: Int(message[offset+5])), blackboxBaudRate: BaudRate(value: Int(message[offset+6]))))
            }
            
        case .msp_PID_CONTROLLER:
            if message.count < 1 {
                return false
            }
            settings.pidController = Int(message[0])

        case .msp_LOOP_TIME:
            if message.count < 2 {
                return false
            }
            settings.loopTime = readUInt16(message, index: 0)
            
        case .msp_BLACKBOX_CONFIG:
            if message.count < 4 {
                return false
            }
            let dataflash = Dataflash.theDataflash
            dataflash.blackboxSupported = message[0] != 0
            dataflash.blackboxDevice = Int(message[1])
            dataflash.blackboxRateNum = Int(message[2])
            dataflash.blackboxRateDenom = Int(message[3])
            
        case .msp_DATAFLASH_SUMMARY:
            if message.count < 13 {
                return false
            }
            let dataflash = Dataflash.theDataflash
            dataflash.ready = message[0] & 1 != 0
            dataflash.sectors = readUInt32(message, index: 1)
            dataflash.totalSize = readUInt32(message, index: 5)
            dataflash.usedSize = readUInt32(message, index: 9)
            
        case .msp_DATAFLASH_READ:
            // Nothing to do. Handled by the callback
            break
            
        case .msp_SDCARD_SUMMARY:
            if message.count < 11 {
                return false
            }
            let dataflash = Dataflash.theDataflash
            dataflash.sdcardSupported = message[0] != 0
            dataflash.sdcardState = Int(message[1])
            dataflash.sdcardLastError = Int(message[2])
            dataflash.sdcardFreeSpace = Int64(readUInt32(message, index: 3)) * 1024
            dataflash.sdcardTotalSpace = Int64(readUInt32(message, index: 7)) * 1024
            
        case .msp_SIKRADIO:
            if message.count < 9 {
                return false
            }
            config.rxerrors = readUInt16(message, index: 0)
            config.fixedErrors = readUInt16(message, index: 2)
            config.sikRssi = Int(message[4])
            config.sikRemoteRssi = Int(message[5])
            config.txBuffer = Int(message[6])
            config.noise = Int(message[7])
            config.remoteNoise = Int(message[8])
            rssiEvent.raiseDispatch()
        
        // Betaflight
        case .msp_ADVANCED_CONFIG:
            if message.count < 6 {
                return false
            }
            settings.gyroSyncDenom = Int(message[0])
            settings.pidProcessDenom = Int(message[1])  // not in INav
            settings.useUnsyncedPwm = message[2] != 0   // Not in INav
            settings.motorPwmProtocol = Int(message[3])
            settings.motorPwmRate = readUInt16(message, index: 4)
            if message.count >= 8 {
                if config.isINav {
                    settings.servoPwmRate = readUInt16(message, index: 6)
                } else {
                    settings.digitalIdleOffsetPercent = Double(readUInt16(message, index: 6)) / 100
                }
                if message.count >= 9 {
                    if config.isINav {
                        settings.syncLoopWithGyro = message[8] != 0
                    } else {
                        settings.gyroUses32KHz = message[8] != 0
                    }
                }
            }
            
        case .msp_FILTER_CONFIG:
            if message.count < 13 {
                return false
            }
            settings.gyroLowpassFrequency = Int(message[0])
            settings.dTermLowpassFrequency = readUInt16(message, index: 1)
            settings.yawLowpassFrequency = readUInt16(message, index: 3)
            settings.gyroNotchFrequency = readUInt16(message, index: 5)
            settings.gyroNotchCutoff = readUInt16(message, index: 7)
            settings.dTermNotchFrequency = readUInt16(message, index: 9)
            settings.dTermNotchCutoff = readUInt16(message, index: 11)
            if message.count >= 15 {
                settings.gyroNotchFrequency2 = readUInt16(message, index: 13)
                if message.count >= 17 {
                    settings.gyroNotchCutoff2 = readUInt16(message, index: 15)
                    if message.count >= 18 {
                        settings.dtermFilterType = Int(message[17])
                    }
                }
            }

        case .msp_ADVANCED_TUNING:      // aka MSP_PID_ADVANCED subject to change A LOT
            if message.count < 17 {
                return false
            }
            //settings.rollPitchItermIgnoreRate = readUInt16(message, index: 0)
            //settings.yawItermIgnoreRate = readUInt16(message, index: 2)
            //settings.yawPLimit = readUInt16(message, index: 4)
            //settings.deltaMethod = Int(message[6])
            settings.vbatPidCompensation = message[7] != 0
            //settings.pTermSRateWeight = Int(message[8])
            settings.setpointRelaxRatio = Int(message[8])
            settings.dTermSetpointWeight = Int(message[9])
            //settings.iTermThrottleGain = Int(message[12])
            settings.rateAccelLimit = readUInt16(message, index: 13)
            settings.yawRateAccelLimit = readUInt16(message, index: 15)
            if message.count >= 19 {
                settings.levelAngleLimit = Int(message[17])
                settings.levelSensitivity = Int(message[18])    // gone in BF 3.2
            }
            
        case .msp_SENSOR_CONFIG:
            if message.count < 3 {
                return false
            }
            settings.accelerometerDisabled = config.isINav ? message[0] == 0 : message[0] != 0
            settings.barometerDisabled = config.isINav ? message[1] == 0 : message[1] != 0
            settings.magnetometerDisabled = config.isINav ? message[2] == 0 : message[2] != 0
            if message.count >= 4 {
                settings.pitotDisabled = config.isINav ? message[3] == 0 : message[3] != 0
                if message.count >= 5 {
                    settings.sonarDisabled = config.isINav ? message[4] == 0 : message[4] != 0
                }
                // INav optical flow (1) (future)
            }
        case .msp_RSSI_CONFIG:
            if message.count < 1 {
                return false
            }
            settings.rssiChannel = Int(message[0])
            
        case .msp_VOLTAGE_METER_CONFIG:
            if message.count < 3 {
                return false
            }
            if message.count == 3 {
                // CF 1.14
                settings.vbatScale = Int(message[0]) // 10-200
                settings.vbatResistorDividerValue = Int(message[1])
                settings.vbatResistorDividerMultiplier = Int(message[2])
            } else if message.count >= 7 {
                // Cleanflight 2.0 / Betaflight 3.2
                settings.vbatMeterId = Int(message[2])
                settings.vbatScale = Int(message[4]) // 10-200
                settings.vbatResistorDividerValue = Int(message[5])
                settings.vbatResistorDividerMultiplier = Int(message[6])
            } else {
                settings.vbatScale = Int(message[0]) // 10-200
                settings.vbatMinCellVoltage = Double(message[1]) / 10; // 10-50
                settings.vbatMaxCellVoltage = Double(message[2]) / 10; // 10-50
                settings.vbatWarningCellVoltage = Double(message[3]) / 10; // 10-50
                if message.count > 4 {
                    settings.vbatMeterType = Int(message[4])
                }
                batteryEvent.raiseDispatch()
            }
        
        case .msp_MIXER_CONFIG:
            if message.count < 1 {
                return false
            }
            settings.mixerConfiguration = Int(message[0])
            if message.count >= 2 {
                settings.yawMotorsReversed = message[1] != 0
            }
            
        case .msp_FEATURE:
            if message.count < 4 {
                return false
            }
            settings.features = BaseFlightFeature(rawValue: readUInt32(message, index: 0))
            
        case .msp_BATTERY_CONFIG:
            if message.count < 7 {
                return false
            }
            settings.vbatMinCellVoltage = Double(message[0]) / 10; // 10-50
            settings.vbatMaxCellVoltage = Double(message[1]) / 10; // 10-50
            settings.vbatWarningCellVoltage = Double(message[2]) / 10; // 10-50
            settings.batteryCapacity = readUInt16(message, index: 3)
            settings.voltageMeterSource = Int(message[5])
            settings.currentMeterSource = Int(message[6])
            batteryEvent.raiseDispatch()
            
        case .msp_BOARD_ALIGNMENT:
            if message.count < 6 {
                return false
            }
            settings.boardAlignRoll = Int(readInt16(message, index: 0))
            settings.boardAlignPitch = Int(readInt16(message, index: 2))
            settings.boardAlignYaw = Int(readInt16(message, index: 4))
        
        case .msp_CURRENT_METER_CONFIG:
            if message.count < 7 {
                return false
            }
            if message.count == 7 {
                settings.currentScale = Int(readInt16(message, index: 0))
                settings.currentOffset = Int(readInt16(message, index: 2))
                settings.currentMeterType = Int(message[4])
                settings.batteryCapacity = Int(readInt16(message, index: 5))
                batteryEvent.raiseDispatch()
            } else {
                // FIXME: Need to retrieve virtual sensor scale and offset if currently being used
                // CF 2.0 / BF 3.2 (ignoring virtual current meter if any)
                settings.currentMeterId = Int(message[2])
                settings.currentMeterType = Int(message[3])
                settings.currentScale = Int(readInt16(message, index: 4))
                settings.currentOffset = Int(readInt16(message, index: 6))
            }
        
        case .msp_MOTOR_CONFIG:     // CF 2.0
            if message.count < 6 {
                return false
            }
            settings.minThrottle = readInt16(message, index: 0) // 0-2000
            settings.maxThrottle = readInt16(message, index: 2) // 0-2000
            settings.minCommand = readInt16(message, index: 4) // 0-2000
            
        case .msp_COMPASS_CONFIG:   // CF 2.0
            if message.count < 2 {
                return false
            }
            settings.magDeclination = Double(readInt16(message, index:0)) / 10  // -18000-18000
            
        case .msp_GPS_CONFIG:       // CF 2.0
            if message.count < 4 {
                return false
            }
            settings.gpsType = Int(message[0])
            settings.gpsUbxSbas = Int(message[1])
            settings.gpsAutoConfig = message[2] != 0
            settings.gpsAutoBaud = message[3] != 0
            
        case .msp_RC_DEADBAND:
            if message.count < 3 {
                return false
            }
            settings.rcDeadband = Int(message[0])
            settings.yawDeadband = Int(message[1])
            settings.altHoldDeadband = Int(message[2])
            if message.count >= 5 {
                settings.throttle3dDeadband = Int(readInt16(message, index: 3))
            }
            
        case .msp_NAME:
            settings.craftName = NSString(bytes: message, length: message.count, encoding: String.Encoding.ascii.rawValue)! as String
            
        case .msp_OSD_CONFIG:
            if message.count < 1 {
                return false
            }
            let osd = OSD.theOSD
            let flags = Int(message[0])     // 1: OSD supported, 2: OSD slave, 16: MAX7456 hardware
            osd.supported = flags & 1 != 0
            if osd.supported {
                osd.videoMode = VideoMode(rawValue: Int(message[1]))!
                if message.count >= 12 {
                    osd.unitMode = UnitMode(rawValue: Int(message[2]))!
                    osd.rssiAlarm = Int(message[3])
                    osd.capacityAlarm = readInt16(message, index: 4)
                    osd.minutesAlarm = readInt16(message, index: 6)
                    osd.altitudeAlarm = readInt16(message, index: 8)
                    var i = 10
                    osd.elements = [OSDElementPosition]()
                    for element in OSDElement.Elements {
                        if i + 1 >= message.count {
                            break
                        }
                        let pos = OSDElementPosition()
                        pos.element = element
                        let (x, y, visible) = decodePos(readInt16(message, index: i))
                        pos.visible = visible
                        pos.x = x
                        pos.y = y
                        osd.elements.append(pos)
                        i += 2
                    }
                    if message.count > i {
                        // Stats
                        var count = Int(message[i])
                        i += 1
                        osd.displayedStats = [Bool]()
                        while i < message.count && osd.displayedStats!.count < count {
                            osd.displayedStats!.append(message[i] != 0)
                            i += 1
                        }
                        // Timers
                        count = Int(message[i])
                        i += 1
                        osd.timers = [OSDTimer]()
                        while i + 1 < message.count && osd.timers!.count < count {
                            osd.timers!.append(OSDTimer.parse(readInt16(message, index: i)))
                            i += 2
                        }
                    }
                }
            }
        
        case .msp_VTX_CONFIG:
            if message.count < 3 {
                return false
            }
            let vtxConfig = VTXConfig.theVTXConfig
            vtxConfig.deviceType = Int(message[0])
            vtxConfig.band = Int(message[1])
            vtxConfig.channel = Int(message[2])
            if message.count >= 5 {
                vtxConfig.powerIdx = Int(message[3])
                vtxConfig.pitMode = message[4] != 0
            }
            
        case .msp_BEEPER_CONFIG:
            if message.count < 4 {
                return false
            }
            settings.beeperMask = readUInt32(message, index: 0)
            
        // INav
        case .msp_NAV_STATUS:
            if message.count < 7 {
                return false
            }
            inavState.mode = INavStatusMode(value: Int(message[0]))
            inavState.state = INavStatusState(value: Int(message[1]))
            inavState.activeWaypointAction = INavWaypointAction(value: Int(message[2]))
            inavState.activeWaypoint = Int(message[3])
            inavState.error = INavStatusError(value: Int(message[4]))
            sensorData.headingHold = Double(readInt16(message, index: 5))
            if inavState.mode.intValue != 0 || inavState.state.intValue != 0 || inavState.error.intValue != 0 {
                NSLog("NAV_STATUS %d %d %d", inavState.mode.intValue, inavState.state.intValue, inavState.error.intValue)
            }
            navigationEvent.raiseDispatch()

        case .msp_SENSOR_STATUS:
            if message.count < 9 {
                return false
            }
            inavState.hardwareHealthy = message[0] != 0
            inavState.gyroStatus = INavSensorStatus(value: Int(message[1]))
            inavState.accStatus = INavSensorStatus(value: Int(message[2]))
            inavState.magStatus = INavSensorStatus(value: Int(message[3]))
            inavState.baroStatus = INavSensorStatus(value: Int(message[4]))
            inavState.gpsStatus = INavSensorStatus(value: Int(message[5]))
            inavState.sonarStatus = INavSensorStatus(value: Int(message[6]))
            inavState.pitotStatus = INavSensorStatus(value: Int(message[7]))
            inavState.flowStatus = INavSensorStatus(value: Int(message[8]))
            sensorStatusEvent.raiseDispatch()
            
        // INav 1.6+
        case .msp_NAV_POSHOLD:
            if message.count < 13 {
                return false
            }
            inavConfig.userControlMode = INavUserControlMode(value: Int(message[0]))
            inavConfig.maxSpeed = Double(readUInt16(message, index: 1)) / 100
            inavConfig.maxClimbRate = Double(readUInt16(message, index: 3)) / 100
            inavConfig.maxManualSpeed = Double(readUInt16(message, index: 5)) / 100
            inavConfig.maxManualClimbRate = Double(readUInt16(message, index: 7)) / 100
            inavConfig.maxBankAngle = Int(message[9])
            inavConfig.useThrottleMidForAltHold = message[10] != 0
            inavConfig.hoverThrottle = readUInt16(message, index: 11)
        
        case .msp_RTH_AND_LAND_CONFIG:
            if message.count < 19 {
                return false
            }
            inavConfig.minRthDistance = Double(readUInt16(message, index: 0)) / 100
            inavConfig.rthClimbFirst = message[2] != 0
            inavConfig.rthClimbIgnoreEmergency = message[3] != 0
            inavConfig.rthTailFirst = message[4] != 0
            inavConfig.rthAllowLanding = message[5] != 0
            inavConfig.rthAltControlMode = Int(message[6])
            inavConfig.rthAbortThreshold = Double(readUInt16(message, index: 7)) / 100
            inavConfig.rthAltitude = Double(readUInt16(message, index: 9)) / 100
            inavConfig.landDescendRate = Double(readUInt16(message, index: 11)) / 100
            inavConfig.landSlowdownMinAlt = Double(readUInt16(message, index: 13)) / 100
            inavConfig.landSlowdownMaxAlt = Double(readUInt16(message, index: 15)) / 100
            inavConfig.emergencyDescendRate = Double(readUInt16(message, index: 17)) / 100
            
        case .msp_FW_CONFIG:
            if message.count < 12 {
                return false
            }
            inavConfig.fwCruiseThrottle = readUInt16(message, index: 0)
            inavConfig.fwMinThrottle = readUInt16(message, index: 2)
            inavConfig.fwMaxThrottle = readUInt16(message, index: 4)
            inavConfig.fwMaxBankAngle = Int(message[6])
            inavConfig.fwMaxClimbAngle = Int(message[7])
            inavConfig.fwMaxDiveAngle = Int(message[8])
            inavConfig.fwPitchToThrottle = Int(message[9])
            inavConfig.fwLoiterRadius = Double(readUInt16(message, index: 10)) / 100
            
        case .msp_WP_GETINFO:
            if message.count < 4 {
                return false
            }
            inavConfig.maxWaypoints = Int(message[1])
            inavConfig.waypointListValid = message[2] != 0
            inavConfig.waypointCount = Int(message[3])
            
        // ACKs for sent commands
        case .msp_SET_MISC,
            .msp_SET_BF_CONFIG,
            .msp_EEPROM_WRITE,
            .msp_SET_REBOOT,
            .msp_ACC_CALIBRATION,
            .msp_MAG_CALIBRATION,
            .msp_SET_ACC_TRIM,
            .msp_SET_MODE_RANGE,
            .msp_SET_ARMING_CONFIG,
            .msp_SET_RC_TUNING,
            .msp_SET_RX_MAP,
            .msp_SET_PID_CONTROLLER,
            .msp_SET_PID,
            .msp_SELECT_SETTING,
            .msp_SET_MOTOR,
            .msp_DATAFLASH_ERASE,
            .msp_SET_WP,
            .msp_SET_SERVO_CONFIGURATION,
            .msp_SET_CF_SERIAL_CONFIG,
            .msp_SET_RAW_RC,
            .msp_SET_RX_CONFIG,
            .msp_SET_FAILSAFE_CONFIG,
            .msp_SET_RXFAIL_CONFIG,
            .msp_SET_LOOP_TIME,
            .msp_SET_ADVANCED_CONFIG,
            .msp_SET_SENSOR_CONFIG,
            .msp_SET_RSSI_CONFIG,
            .msp_SET_VOLTAGE_METER_CONFIG,
            .msp_SET_MIXER_CONFIG,
            .msp_SET_FEATURE,
            .msp_SET_BATTERY_CONFIG,
            .msp_SET_BOARD_ALIGNMENT,
            .msp_SET_CURRENT_METER_CONFIG,
            .msp_SET_MOTOR_CONFIG,
            .msp_SET_COMPASS_CONFIG,
            .msp_SET_GPS_CONFIG,
            .msp_SET_RC_DEADBAND,
            .msp_SET_NAV_POSHOLD,
            .msp_WP_MISSION_LOAD,
            .msp_WP_MISSION_SAVE,
            .msp_SET_OSD_CONFIG,
            .msp_SET_VTX_CONFIG,
            .msp_SET_FILTER_CONFIG,
            .msp_OSD_CHAR_WRITE,
            .msp_SET_NAME,
            .msp_SET_RTH_AND_LAND_CONFIG,
            .msp_SET_FW_CONFIG,
            .msp_SET_BLACKBOX_CONFIG,
            .msp_SET_BEEPER_CONFIG:
            break
            
        default:
            NSLog("Unhandled message %d", code.rawValue)
            break
        }
        
        return true
    }
    
    func callSuccessCallback(_ code: MSP_code, data: [UInt8]) {
        var callback: ((_ success: Bool) -> Void)? = nil
        var dataCallback: ((_ data: [UInt8]) -> Void)? = nil
        
        objc_sync_enter(retriedMessageLock)
        if let retriedMessage = retriedMessages.removeValue(forKey: code) {
            retriedMessage.cancelled = true
            retriedMessage.timer?.invalidate()
            if retriedMessage is DataMessageRetryHandler {
                dataCallback = (retriedMessage as! DataMessageRetryHandler).dataCallback
            } else {
                callback = retriedMessage.callback
            }
        }
        objc_sync_exit(retriedMessageLock)
        callback?(true)
        dataCallback?(data)
    }
    
    func makeSendMessageTimer(_ handler: MessageRetryHandler) {
        DispatchQueue.main.async(execute: {
            if !handler.cancelled {
                handler.timer = Timer(timeInterval: 0.3, target: self, selector: #selector(MSPParser.sendMessageTimedOut(_:)), userInfo: handler, repeats: false)
                RunLoop.main.add(handler.timer!, forMode: RunLoopMode.commonModes)
            }
        })
    }
    
    func sendMessage(_ code: MSP_code, data: [UInt8]?, retry: Int, flush: Bool = true, callback: ((_ success: Bool) -> Void)?) {
        //NSLog("sendMessage %d", code.rawValue)
        if retry > 0 || callback != nil {
            let messageRetry = MessageRetryHandler(code: code, data: data, maxTries: retry, callback: callback)
            makeSendMessageTimer(messageRetry)
            
            objc_sync_enter(retriedMessageLock)
            retriedMessages[code] = messageRetry
            objc_sync_exit(retriedMessageLock)
        }
        addOutputMessage(codec.encode(code, message: data), flush: flush)
    }
    
    func sendMessage(_ code: MSP_code, data: [UInt8]?, flush: Bool = true) {
        sendMessage(code, data: data, retry: 0, flush: flush, callback: nil)
    }
    
    @objc
    func sendMessageTimedOut(_ timer: Timer) {
        let handler = timer.userInfo as! MessageRetryHandler
        handler.tries += 1
        if handler.tries > handler.maxTries {
            handler.cancelled = true
            NSLog("sendMessage %d failed", handler.code.rawValue)
            callErrorCallback(handler.code)
            return
        }
        NSLog("Retrying sendMessage %d", handler.code.rawValue)
        makeSendMessageTimer(handler)

        sendMessage(handler.code, data: handler.data, retry: 0, callback: nil)
    }
    
    fileprivate func callErrorCallback(_ code: MSP_code) {
        objc_sync_enter(retriedMessageLock)
        let handler = retriedMessages.removeValue(forKey: code)
        objc_sync_exit(retriedMessageLock)
        if handler is DataMessageRetryHandler {
            (handler as! DataMessageRetryHandler).dataCallback(nil)
        } else if handler != nil {
            handler!.callback?(false)
        }
        return
    }
    
    func cancelRetries() {
        objc_sync_enter(retriedMessageLock)
        for handler in retriedMessages.values {
            handler.cancelled = true
            handler.timer?.invalidate()
        }
        objc_sync_exit(retriedMessageLock)
    }
    
    func sendSetMisc(_ settings: Settings, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(contentsOf: writeInt16(settings.midRC))
        data.append(contentsOf: writeInt16(settings.minThrottle))
        data.append(contentsOf: writeInt16(settings.maxThrottle))
        data.append(contentsOf: writeInt16(settings.minCommand))
        data.append(contentsOf: writeInt16(settings.failsafeThrottle))
        data.append(UInt8(settings.gpsType))
        data.append(UInt8(0))
        data.append(UInt8(settings.gpsUbxSbas))
        data.append(UInt8(0))    // multiwiiCurrentOuput
        data.append(UInt8(settings.rssiChannel))
        data.append(UInt8(0))
        data.append(contentsOf: writeInt16(Int(round(settings.magDeclination * 10))))
        data.append(UInt8(settings.vbatScale))
        data.append(UInt8(round(settings.vbatMinCellVoltage * 10)))
        data.append(UInt8(round(settings.vbatMaxCellVoltage * 10)))
        data.append(UInt8(round(settings.vbatWarningCellVoltage * 10)))
        
        sendMessage(.msp_SET_MISC, data: data, retry: 2, callback: callback)
    }
    
    /*
    func sendSetBfConfig(settings: Settings, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(settings.mixerConfiguration))
        data.appendContentsOf(writeUInt32(settings.features.rawValue))
        data.append(UInt8(settings.serialRxType))
        data.appendContentsOf(writeInt16(settings.boardAlignRoll))
        data.appendContentsOf(writeInt16(settings.boardAlignPitch))
        data.appendContentsOf(writeInt16(settings.boardAlignYaw))
        data.appendContentsOf(writeInt16(settings.currentScale))
        data.appendContentsOf(writeInt16(settings.currentOffset))
        
        sendMessage(.MSP_SET_BF_CONFIG, data: data, retry: 2, callback: callback)
    }
    */
    
    func sendSetAccTrim(_ misc: Misc, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(contentsOf: writeInt16(misc.accelerometerTrimPitch))
        data.append(contentsOf: writeInt16(misc.accelerometerTrimRoll))
        
        sendMessage(.msp_SET_ACC_TRIM, data: data, retry: 2, callback: callback)
    }
    
    func sendSetModeRange(_ index: Int, range: ModeRange, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(index))
        data.append(UInt8(range.id))
        data.append(UInt8(range.auxChannelId))
        data.append(UInt8((range.start - 900) / 25))
        data.append(UInt8((range.end - 900) / 25))
        
        sendMessage(.msp_SET_MODE_RANGE, data: data, retry: 2, callback: callback)
    }
    
    func sendSetArmingConfig(_ settings: Settings, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(settings.autoDisarmDelay))
        data.append(UInt8(settings.disarmKillSwitch ? 1 : 0))
        
        sendMessage(.msp_SET_ARMING_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendSetRcTuning(_ settings: Settings, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(round(settings.rcRate * 100)))
        data.append(UInt8(round(settings.rcExpo * 100)))
        data.append(UInt8(round(settings.rollSuperRate * 100)))
        data.append(UInt8(round(settings.pitchSuperRate * 100)))
        data.append(UInt8(round(settings.yawSuperRate * 100)))
        data.append(UInt8(round(settings.tpaRate * 100)))
        data.append(UInt8(round(settings.throttleMid * 100)))
        data.append(UInt8(round(settings.throttleExpo * 100)))
        data.append(contentsOf: writeInt16(settings.tpaBreakpoint))
        data.append(UInt8(round(settings.yawExpo * 100)))
        data.append(UInt8(round(settings.yawRate * 100)))       // BF and CF 2.0 only
    
        sendMessage(.msp_SET_RC_TUNING, data: data, retry: 2, callback: callback)
    }
    
    func sendSetRxMap(_ map: [UInt8], callback:((_ success:Bool) -> Void)?) {
        sendMessage(.msp_SET_RX_MAP, data: map, retry: 2, callback: callback)
    }
    
    func sendPidController(_ pidController: Int, callback:((_ success:Bool) -> Void)?) {
        sendMessage(.msp_SET_PID_CONTROLLER, data: [ UInt8(pidController) ], retry: 2, callback: callback)
    }
    
    func sendPid(_ settings: Settings, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        for pid in settings.pidValues! {
            let p = pid[0]
            let i = pid[1]
            let d = pid[2]
            data.append(UInt8(round(p)))
            data.append(UInt8(round(i)))
            data.append(UInt8(round(d)))
        }
        sendMessage(.msp_SET_PID, data: data, retry: 2, callback: callback)
    }
    
    func sendSelectProfile(_ profile: Int, callback:((_ success:Bool) -> Void)?) {
        // Note: this call includes a write eeprom (in CF 1.12. Not sure about other versions)
        sendMessage(.msp_SELECT_SETTING, data: [ UInt8(profile) ], retry: 2, callback: callback)
    }
    
    func sendDataflashRead(_ address: Int, callback: @escaping (_ data: [UInt8]?) -> Void) {
        let data = writeUInt32(address)
        let messageRetry = DataMessageRetryHandler(code: .msp_DATAFLASH_READ, data: data, maxTries: 3, callback: callback)
        makeSendMessageTimer(messageRetry)
        
        objc_sync_enter(retriedMessageLock)
        retriedMessages[.msp_DATAFLASH_READ] = messageRetry
        objc_sync_exit(retriedMessageLock)
        sendMessage(.msp_DATAFLASH_READ, data: data, retry: 0, callback: nil)
    }
    
    // Waypoint number 0 is GPS Home location, waypoint number 16 is GPS Hold location, other values are ignored in CF
    // Pass altitude=0 to keep current AltHold value
    func sendWaypoint(_ number: Int, latitude: Double, longitude: Double, altitude: Double, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(number))
        data.append(contentsOf: writeInt32(Int(latitude * 10000000.0)))
        data.append(contentsOf: writeInt32(Int(longitude * 10000000.0)))
        data.append(contentsOf: writeInt32(Int(altitude * 100)))
        data.append(contentsOf: [0, 0, 0, 0, 0])  // Future: heading (16), time to stay (16), nav flags
        
        sendMessage(.msp_SET_WP, data: data, retry: 2, callback: callback)
    }

    // INav: wp#0 is home, wp#255 is GPS Hold location and wp#1 to wp#15 are regular waypoints (must be set in sequence)
    func sendINavWaypoint(_ waypoint: Waypoint, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(waypoint.number))
        data.append(UInt8(waypoint.action.intValue))
        data.append(contentsOf: writeInt32(Int(waypoint.position.latitude * 10000000.0)))
        data.append(contentsOf: writeInt32(Int(waypoint.position.longitude * 10000000.0)))
        data.append(contentsOf: writeInt32(Int(waypoint.altitude * 100)))
        data.append(contentsOf: writeInt16(waypoint.param1))
        data.append(contentsOf: writeInt16(waypoint.param2))
        data.append(contentsOf: writeInt16(waypoint.param3))
        data.append(UInt8(waypoint.last ? 0xA5 : 0))
        
        sendMessage(.msp_SET_WP, data: data, retry: 2, callback: callback)
    }
    
    func sendINavWaypoints(_ inavState: INavState, callback:((_ success:Bool) -> Void)?) {
        sendINavWaypointsRecursive(inavState, wpNumber: 0, callback: callback)
    }
    fileprivate func sendINavWaypointsRecursive(_ inavState: INavState, wpNumber: Int, callback:((_ success:Bool) -> Void)?) {
        if wpNumber >= inavState.waypoints.count {
            callback?(true)
        } else {
            var waypoint = inavState.waypoints[wpNumber]
            waypoint.last = wpNumber == inavState.waypoints.count - 1
            sendINavWaypoint(waypoint) { success in
                if success {
                    self.sendINavWaypointsRecursive(inavState, wpNumber: wpNumber + 1, callback: callback)
                } else {
                    callback?(false)
                }
            }
        }
    }
    
    func setGPSHoldPosition(latitude: Double, longitude: Double, altitude: Double, callback:((_ success:Bool) -> Void)?) {
        if Configuration.theConfig.isINav {
            let waypoint = Waypoint(number: 255, action: .known(.waypoint), position: GPSLocation(latitude: latitude, longitude: longitude), altitude: altitude, param1: 0, param2: 0, param3: 0, last: false)
            sendINavWaypoint(waypoint, callback: callback)
        } else {
            sendWaypoint(16, latitude: latitude, longitude: longitude, altitude: altitude, callback: callback)
        }
    }
    
    // Clear inavState before calling this function
    func fetchINavWaypoints(_ inavState: INavState,  callback:((_ success:Bool) -> Void)?) {
        if let waypoint = inavState.waypoints.last, waypoint.last {
            callback?(true)
        } else if self.replaying {
            // Avoid infinite recursion
            callback?(true)
        } else {
            sendMessage(.msp_WP, data: [ UInt8(inavState.waypoints.count + 1) ], retry: 2) { success in
                if success {
                    self.fetchINavWaypoints(inavState, callback: callback)
                } else {
                    callback?(false)
                }
            }
        }
    }
    
    func setServoConfig(_ servoIdx: Int, servoConfig: ServoConfig, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(servoIdx))
        data.append(contentsOf: writeInt16(servoConfig.minimumRC))
        data.append(contentsOf: writeInt16(servoConfig.maximumRC))
        data.append(contentsOf: writeInt16(servoConfig.middleRC))
        data.append(writeInt8(servoConfig.rate))
        data.append(UInt8(servoConfig.minimumAngle))
        data.append(UInt8(servoConfig.maximumAngle))
        data.append(UInt8(servoConfig.rcChannel == nil ? CHANNEL_FORWARDING_DISABLED : servoConfig.rcChannel!))
        data.append(contentsOf: writeUInt32(servoConfig.reversedSources))
        
        sendMessage(.msp_SET_SERVO_CONFIGURATION, data: data, retry: 2, callback: callback)
    }
    
    func sendSerialConfig(_ settings: Settings, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        for portConfig in settings.portConfigs! {
            data.append(UInt8(portConfig.portIdentifier.intValue))
            data.append(contentsOf: writeUInt16(portConfig.functions.rawValue))
            data.append(UInt8(portConfig.mspBaudRate.intValue))
            data.append(UInt8(portConfig.gpsBaudRate.intValue))
            data.append(UInt8(portConfig.telemetryBaudRate.intValue))
            data.append(UInt8(portConfig.blackboxBaudRate.intValue))
        }
        
        sendMessage(.msp_SET_CF_SERIAL_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendRawRc(_ values: [Int]) {
        var data = [UInt8]()
        for v in values {
            data.append(contentsOf: writeUInt16(v))
        }
        sendMessage(.msp_SET_RAW_RC, data: data)
    }
    
    func sendRxConfig(_ settings: Settings, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(settings.serialRxType))
        data.append(contentsOf: writeUInt16(settings.maxCheck))
        data.append(contentsOf: writeUInt16(settings.midRC))
        data.append(contentsOf: writeUInt16(settings.minCheck))
        data.append(UInt8(settings.spektrumSatBind))
        data.append(contentsOf: writeUInt16(settings.rxMinUsec))
        data.append(contentsOf: writeUInt16(settings.rxMaxUsec))
        data.append(UInt8(settings.rcInterpolation))
        data.append(UInt8(settings.rcInterpolationInterval))
        data.append(contentsOf: writeUInt16(settings.airmodeActivateThreshold))
        data.append(UInt8(settings.rxSpiProtocol))
        data.append(contentsOf: writeUInt32(settings.rxSpiId))
        data.append(UInt8(settings.rxSpiChannelCount))
        data.append(UInt8(settings.fpvCamAngleDegrees))

        sendMessage(.msp_SET_RX_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendFailsafeConfig(_ settings: Settings, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(Int(settings.failsafeDelay * 10)))
        data.append(UInt8(Int(settings.failsafeOffDelay * 10)))
        data.append(contentsOf: writeUInt16(settings.failsafeThrottle))
        data.append(UInt8(settings.failsafeKillSwitch ? 1 : 0))
        data.append(contentsOf: writeUInt16(Int(settings.failsafeThrottleLowDelay * 10)))
        data.append(UInt8(settings.failsafeProcedure))
        sendMessage(.msp_SET_FAILSAFE_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendRxFailConfig(_ settings: Settings, index: Int = 0, callback:((_ success:Bool) -> Void)?) {
        if settings.rxFailMode == nil || settings.rxFailMode!.count == 0 {
            // Happens when RX config is invalid
            callback?(true)
            return
        }
        var data = [UInt8]()
        data.append(UInt8(index))
        data.append(UInt8(settings.rxFailMode![index]))
        data.append(contentsOf: writeUInt16(settings.rxFailValue![index]))
        sendMessage(.msp_SET_RXFAIL_CONFIG, data: data, retry: 2, callback: { success in
            if success {
                if index < settings.rxFailMode!.count - 1 {
                    self.sendRxFailConfig(settings, index: index + 1, callback: callback)
                } else {
                    callback?(true)
                }
            } else {
                callback?(false)
            }
        })
    }
    
    func sendLoopTime(_ settings: Settings, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(contentsOf: writeUInt16(settings.loopTime))
        sendMessage(.msp_SET_LOOP_TIME, data: data, retry: 2, callback: callback)
    }
    
    func sendRssiConfig(_ rssiChannel: Int, callback:((_ success: Bool) -> Void)?) {
        let data = [UInt8(rssiChannel)]
        sendMessage(.msp_SET_RSSI_CONFIG, data: data, retry: 2, callback: callback)
    }

    func isBuggyCFAlwaysError() -> Bool {
        // CF 2.0 and 2.1 (as well as BF 3.2 beta) always returns an error (bug)
        let config = Configuration.theConfig
        if config.isINav || config.isBetaflight {
            return false
        }
        return config.apiVersion == "1.35" || config.apiVersion == "1.36"
    }
    
    func sendVoltageMeterConfig(_ settings: Settings, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.35") && !config.isINav {
            // CF 2 / BF 3.2
            data.append(UInt8(settings.vbatMeterId))
            data.append(UInt8(settings.vbatScale))
            data.append(UInt8(settings.vbatResistorDividerValue))
            data.append(UInt8(settings.vbatResistorDividerMultiplier))
        } else {
            data.append(UInt8(settings.vbatScale))
            data.append(UInt8(settings.vbatMinCellVoltage * 10))
            data.append(UInt8(settings.vbatMaxCellVoltage * 10))
            data.append(UInt8(settings.vbatWarningCellVoltage * 10))
            data.append(UInt8(settings.vbatMeterType))
        }
        sendMessage(.msp_SET_VOLTAGE_METER_CONFIG, data: data, retry: 2) { success in
            if self.isBuggyCFAlwaysError() {
                callback?(true)
            } else {
                callback?(success)
            }
        }
    }
    
    func sendMixerConfiguration(_ settings: Settings, callback:((_ success:Bool) -> Void)?) {
        let data = [UInt8(settings.mixerConfiguration), UInt8(settings.yawMotorsReversed ? 1 : 0)]
        sendMessage(.msp_SET_MIXER_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendSetFeature(_ features: BaseFlightFeature, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(contentsOf: writeUInt32(features.rawValue))
        
        sendMessage(.msp_SET_FEATURE, data: data, retry: 2, callback: callback)
    }
    
    func sendBatteryConfig(_ settings: Settings, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(settings.vbatMinCellVoltage * 10))
        data.append(UInt8(settings.vbatMaxCellVoltage * 10))
        data.append(UInt8(settings.vbatWarningCellVoltage * 10))
        data.append(contentsOf: writeUInt16(settings.batteryCapacity))
        data.append(UInt8(settings.voltageMeterSource))
        data.append(UInt8(settings.currentMeterSource))

        sendMessage(.msp_SET_BATTERY_CONFIG, data: data, retry: 2) { success in
            if self.isBuggyCFAlwaysError() {
                callback?(true)
            } else {
                callback?(success)
            }
        }
    }
    
    func sendBoardAlignment(_ settings: Settings, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(contentsOf: writeUInt16(settings.boardAlignRoll))
        data.append(contentsOf: writeUInt16(settings.boardAlignPitch))
        data.append(contentsOf: writeUInt16(settings.boardAlignYaw))
        
        sendMessage(.msp_SET_BOARD_ALIGNMENT, data: data, retry: 2, callback: callback)
    }
    
    func sendCurrentMeterConfig(_ settings: Settings, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.35") && !config.isINav {
            // CF 2 / BF 3.2
            if settings.currentMeterType == 1 {     // CURRENT_METER_ADC
                // regular
                data.append(UInt8(10))  // CURRENT_METER_ID_BATTERY_1
            } else {
                data.append(UInt8(80))  // CURRENT_METER_ID_VIRTUAL_1
            }
            data.append(contentsOf: writeUInt16(settings.currentScale))
            data.append(contentsOf: writeUInt16(settings.currentOffset))
        } else {
            data.append(contentsOf: writeUInt16(settings.currentScale))
            data.append(contentsOf: writeUInt16(settings.currentOffset))
            data.append(UInt8(settings.currentMeterType))
            data.append(contentsOf: writeUInt16(settings.batteryCapacity))
        }
    
        sendMessage(.msp_SET_CURRENT_METER_CONFIG, data: data, retry: 2) { success in
            if self.isBuggyCFAlwaysError() {
                callback?(true)
            } else {
                callback?(success)
            }
        }
    }
    
    func sendBlackboxConfig(_ dataflash: Dataflash, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(dataflash.blackboxDevice))
        data.append(UInt8(dataflash.blackboxRateNum))
        data.append(UInt8(dataflash.blackboxRateDenom))
        sendMessage(.msp_SET_BLACKBOX_CONFIG, data: data, retry: 2, callback: callback)
    }

    // Cleanflight 2.0
    
    func sendMotorConfig(_ settings: Settings, callback:((_ success: Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(contentsOf: writeUInt16(settings.minThrottle))
        data.append(contentsOf: writeUInt16(settings.maxThrottle))
        data.append(contentsOf: writeUInt16(settings.minCommand))
        sendMessage(.msp_SET_MOTOR_CONFIG, data: data, retry: 2, callback: callback)
    }

    func sendCompassConfig(_ magDeclination: Double, callback:((_ success: Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(contentsOf: writeInt16(Int(round(magDeclination * 10))))
        sendMessage(.msp_SET_COMPASS_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendGpsConfig(_ settings: Settings, callback:((_ success: Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(settings.gpsType))
        data.append(UInt8(settings.gpsUbxSbas))
        data.append(UInt8(settings.gpsAutoConfig ? 1 : 0))
        data.append(UInt8(settings.gpsAutoBaud ? 1 : 0))
        sendMessage(.msp_SET_GPS_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendRcDeadband(_ settings: Settings, callback:((_ success: Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(settings.rcDeadband))
        data.append(UInt8(settings.yawDeadband))
        data.append(UInt8(settings.altHoldDeadband))
        data.append(contentsOf: writeUInt16(settings.throttle3dDeadband))
        sendMessage(.msp_SET_RC_DEADBAND, data: data, retry: 2, callback: callback)
    }

    // Betaflight
    
    func sendAdvancedConfig(_ settings: Settings, callback:((_ success: Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(settings.gyroSyncDenom))
        data.append(UInt8(settings.pidProcessDenom))
        data.append(UInt8(settings.useUnsyncedPwm ? 1 : 0))
        data.append(UInt8(settings.motorPwmProtocol))
        data.append(contentsOf: writeUInt16(settings.motorPwmRate))
        if Configuration.theConfig.isINav {
            data.append(contentsOf: writeUInt16(settings.servoPwmRate))
            data.append(UInt8(settings.syncLoopWithGyro ? 1 : 0))
        } else {
            data.append(contentsOf: writeUInt16(Int(round(settings.digitalIdleOffsetPercent * 100))))
            data.append(UInt8(settings.gyroUses32KHz ? 1 : 0))
        }
        sendMessage(.msp_SET_ADVANCED_CONFIG, data: data, retry: 2, callback: callback)
    }

    func sendSensorConfig(_ settings: Settings, callback:((_ success: Bool) -> Void)?) {
        let config = Configuration.theConfig
        var data = [UInt8]()
        data.append(UInt8(settings.accelerometerDisabled != config.isINav ? 1 : 0))
        data.append(UInt8(settings.barometerDisabled != config.isINav ? 1 : 0))
        data.append(UInt8(settings.magnetometerDisabled != config.isINav ? 1 : 0))
        data.append(UInt8(settings.pitotDisabled != config.isINav ? 1 : 0))
        data.append(UInt8(settings.sonarDisabled != config.isINav ? 1 : 0))
        sendMessage(.msp_SET_SENSOR_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendSelectRateProfile(_ rateProfile: Int, callback:((_ success: Bool) -> Void)?) {
        sendMessage(.msp_SELECT_SETTING, data: [ UInt8(rateProfile | 0x80) ], retry: 2, callback: callback)
    }
    
    func sendFilterConfig(_ settings: Settings, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(settings.gyroLowpassFrequency))
        data.append(contentsOf: writeUInt16(settings.dTermLowpassFrequency))
        data.append(contentsOf: writeUInt16(settings.yawLowpassFrequency))
        data.append(contentsOf: writeUInt16(settings.gyroNotchFrequency))
        data.append(contentsOf: writeUInt16(settings.gyroNotchCutoff))
        data.append(contentsOf: writeUInt16(settings.dTermNotchFrequency))
        data.append(contentsOf: writeUInt16(settings.dTermNotchCutoff))
        data.append(contentsOf: writeUInt16(settings.gyroNotchFrequency2))
        data.append(contentsOf: writeUInt16(settings.gyroNotchCutoff2))
        if Configuration.theConfig.isApiVersionAtLeast("1.36") {    // Not supported by INav 1.7.3 but it doesn't hurt
            data.append(UInt8(settings.dtermFilterType))
        }
        sendMessage(.msp_SET_FILTER_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendCraftName(_ name: String, callback:((_ success:Bool) -> Void)?) {
        sendMessage(.msp_SET_NAME, data: Array(name.utf8), retry: 2, callback: callback)
    }
    
    func sendOsdConfig(_ osd: OSD, callback:((_ success: Bool) -> Void)?) {
        sendOsdConfigRecursive(osd, index: osd.timers != nil ? -2 : -1, index2: 0, callback: callback)
    }
    
    fileprivate func sendOsdConfigRecursive(_ osd: OSD, index: Int, index2: Int, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        if index == -2 {
            if index2 >= osd.timers!.count {
                sendOsdConfigRecursive(osd, index: -1, index2: 0, callback: callback)
                return
            }
            data.append(UInt8(0xFE))    // -2
            data.append(UInt8(index2))
            data.append(contentsOf: writeUInt16(osd.timers![index2].rawValue))
        } else if index == -1 {
            data.append(UInt8(0xFF))    // -1
            data.append(UInt8(osd.videoMode.rawValue))
            data.append(UInt8(osd.unitMode.rawValue))
            data.append(UInt8(osd.rssiAlarm))
            data.append(contentsOf: writeUInt16(osd.capacityAlarm))
            data.append(contentsOf: writeUInt16(osd.minutesAlarm))
            data.append(contentsOf: writeUInt16(osd.altitudeAlarm))
        } else {
            if index2 == 0 {
                // Element
                if index >= osd.elements.count {
                    callback?(true)
                    return
                }
                data.append(UInt8(index))
                let position = osd.elements[index]
                data.append(contentsOf: writeUInt16(encodePos(position.x, y: position.y, visible: position.visible)))
            } else {
                // Flight Stat
                if index >= osd.displayedStats!.count {
                    callback?(true)
                    return
                }
                data.append(UInt8(index))
                data.append(contentsOf: writeUInt16(osd.displayedStats![index] ? 1 : 0))
                data.append(UInt8(0))       // Screen 0 -> selects flight stat screen
            }
        }

        sendMessage(.msp_SET_OSD_CONFIG, data: data, retry: 2) { success in
            let fakedSuccess = self.isBuggyCFAlwaysError() ? true : success

            if fakedSuccess {
                var newIndex = index + 1
                var newIndex2 = index2
                if index == -2 {
                    // Timers
                    if index2 + 1 >= osd.timers!.count {
                        newIndex = -1
                        newIndex2 = 0
                    } else {
                        newIndex = -2
                        newIndex2 = index2 + 1
                    }
                } else if newIndex >= osd.elements.count && index2 == 0 && osd.displayedStats != nil && osd.displayedStats!.count > 0 {
                    newIndex = 0
                    newIndex2 = 1
                }
                self.sendOsdConfigRecursive(osd, index: newIndex, index2: newIndex2, callback: callback)
            } else {
                callback?(false)
            }
        }
    }
    
    func sendOsdChar(_ char: Int, data: [UInt8], callback:((_ success:Bool) -> Void)?) {
        var msgData = [ UInt8(char) ]
        msgData.append(contentsOf: data)

        sendMessage(.msp_OSD_CHAR_WRITE, data: msgData,  retry: 2) { success in
            if self.isBuggyCFAlwaysError() {
                callback?(true)
            } else {
                callback?(success)
            }
        }
    }
    
    func sendVtxConfig(_ vtxConfig: VTXConfig, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(vtxConfig.band))
        data.append(UInt8(vtxConfig.channel))
        data.append(UInt8(vtxConfig.powerIdx))
        data.append(UInt8(vtxConfig.pitMode ? 1 : 0))
        sendMessage(.msp_SET_VTX_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendBeeperConfig(_ beeperMask: Int, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(contentsOf: writeUInt32(beeperMask))
        sendMessage(.msp_SET_BEEPER_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    // INav
    
    func sendNavPosHold(_ inavConfig: INavConfig, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(inavConfig.userControlMode.intValue))
        data.append(contentsOf: writeUInt16(Int(round(inavConfig.maxSpeed * 100))))
        data.append(contentsOf: writeUInt16(Int(round(inavConfig.maxClimbRate * 100))))
        data.append(contentsOf: writeUInt16(Int(round(inavConfig.maxManualSpeed * 100))))
        data.append(contentsOf: writeUInt16(Int(round(inavConfig.maxManualClimbRate * 100))))
        data.append(UInt8(inavConfig.maxBankAngle))
        data.append(UInt8(inavConfig.useThrottleMidForAltHold ? 1 : 0))
        data.append(contentsOf: writeUInt16(inavConfig.hoverThrottle))
        sendMessage(.msp_SET_NAV_POSHOLD, data: data, retry: 2, callback: callback)
    }
    
    func loadMission(_ callback:((_ success:Bool) -> Void)?) {
        let data = [UInt8(0)]
        sendMessage(.msp_WP_MISSION_LOAD, data: data, retry: 2, callback: callback)
    }
    
    func saveMission(_ callback:((_ success:Bool) -> Void)?) {
        let data = [UInt8(0)]
        sendMessage(.msp_WP_MISSION_SAVE, data: data, retry: 2, callback: callback)
    }
    
    func sendRthAndLandConfig(_ inavConfig: INavConfig, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(contentsOf: writeUInt16(Int(round(inavConfig.minRthDistance * 100))))
        data.append(UInt8(inavConfig.rthClimbFirst ? 1 : 0))
        data.append(UInt8(inavConfig.rthClimbIgnoreEmergency ? 1 : 0))
        data.append(UInt8(inavConfig.rthTailFirst ? 1 : 0))
        data.append(UInt8(inavConfig.rthAllowLanding ? 1 : 0))
        data.append(UInt8(inavConfig.rthAltControlMode))
        data.append(contentsOf: writeUInt16(Int(round(inavConfig.rthAbortThreshold * 100))))
        data.append(contentsOf: writeUInt16(Int(round(inavConfig.rthAltitude * 100))))
        data.append(contentsOf: writeUInt16(Int(round(inavConfig.landDescendRate * 100))))
        data.append(contentsOf: writeUInt16(Int(round(inavConfig.landSlowdownMinAlt * 100))))
        data.append(contentsOf: writeUInt16(Int(round(inavConfig.landSlowdownMaxAlt * 100))))
        data.append(contentsOf: writeUInt16(Int(round(inavConfig.emergencyDescendRate * 100))))

        sendMessage(.msp_SET_RTH_AND_LAND_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendFwConfig(_ inavConfig: INavConfig, callback:((_ success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(contentsOf: writeUInt16(inavConfig.fwCruiseThrottle))
        data.append(contentsOf: writeUInt16(inavConfig.fwMinThrottle))
        data.append(contentsOf: writeUInt16(inavConfig.fwMaxThrottle))
        data.append(UInt8(inavConfig.fwMaxBankAngle))
        data.append(UInt8(inavConfig.fwMaxClimbAngle))
        data.append(UInt8(inavConfig.fwMaxDiveAngle))
        data.append(UInt8(inavConfig.fwPitchToThrottle))
        data.append(contentsOf: writeUInt16(Int(round(inavConfig.fwLoiterRadius * 100))))
        sendMessage(.msp_SET_FW_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func openCommChannel(_ commChannel: CommChannel) {
        self.commChannel = commChannel
        communicationEvent.raiseDispatch(true)
    }
    
    func closeCommChannel() {
        cancelRetries()
        commChannel?.close()
        commChannel = nil
        FlightLogFile.close(self)
        synchronized(self) {
            self.sentDates.removeAll()
            self.msgLatencies.removeAll()
        }
        communicationEvent.raiseDispatch(false)
    }
    
    var communicationEstablished: Bool {
        return commChannel != nil
    }
    
    var communicationHealthy: Bool {
        return communicationEstablished && commChannel!.connected
    }
    
    var replaying: Bool {
        return commChannel is ReplayComm
    }
    
    var simulating: Bool {
        return commChannel is Simulator
    }
    
    var isWifi: Bool {
        return commChannel is AsyncSocketComm
    }
    
    func nextOutputMessage() -> [UInt8]? {
        objc_sync_enter(self)
        if outputQueue.isEmpty {
            objc_sync_exit(self)
            return nil
        }
        let msg = outputQueue.removeFirst()
        
        if msg[0] == 36 {   // $
            if let mspCode = MSP_code(rawValue: Int(msg[4])), latencyMsgs.contains(mspCode) {
                let sentDate = sentDates[mspCode]
                if sentDate == nil {
                    sentDates[mspCode] = Date()
                }
            }
        }
        objc_sync_exit(self)
        
        return msg
    }
    
    func addOutputMessage(_ msg: [UInt8], flush: Bool = true) {
        objc_sync_enter(self)
        if msg[0] == 36 {   // $
            let msgCode = msg[4]
            for i in 0..<outputQueue.count {
                let curMsg = outputQueue[i]
                if curMsg.count >= 5 && curMsg[4] == msgCode {
                    outputQueue[i] = msg
                    objc_sync_exit(self)
                    //NSLog("Message %d already in output queue", msgCode)
                    if flush {
                        commChannel?.flushOut()
                    }
                    return
                }
            }
        }
        outputQueue.append(msg)
        objc_sync_exit(self)
        
        if flush {
            commChannel?.flushOut()
        }
    }
    
    func readBluetoothRssi() {
        guard let btComm = commChannel as? BluetoothComm else {
            return
        }
        btComm.readRssi()
    }
    
    func setRssi(_ rssi: Double) {
        Configuration.theConfig.btRssi = Int(round(constrain((104 + rssi) / 78 * 100, min: 0, max: 100)))
        
        rssiEvent.raiseDispatch()
    }
}
