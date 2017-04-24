//
//  MSP.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class MessageRetryHandler {
    let code: MSP_code
    let data: [UInt8]?
    let callback: ((success: Bool) -> Void)?
    let maxTries: Int
    var timer: NSTimer?
    var cancelled = false
    
    var tries = 0
    
    init(code: MSP_code, data: [UInt8]?, maxTries: Int, callback: ((success: Bool) -> Void)?) {
        self.code = code
        self.data = data
        self.maxTries = maxTries
        self.callback = callback
    }
}

class DataMessageRetryHandler : MessageRetryHandler {
    let dataCallback: (data: [UInt8]?) -> Void
    
    init(code: MSP_code, data: [UInt8]?, maxTries: Int, callback: (data: [UInt8]?) -> Void) {
        self.dataCallback = callback
        super.init(code: code, data: data, maxTries: maxTries, callback: nil)
    }
}

class MSPParser {
    let CHANNEL_FORWARDING_DISABLED = 0xFF
    let codec = MSPCodec()
    let latencyMsgs = Set<MSP_code>(arrayLiteral: .MSP_STATUS, .MSP_RAW_GPS, .MSP_COMP_GPS, .MSP_ALTITUDE, .MSP_ATTITUDE, .MSP_ANALOG, .MSP_WP)
    
    var datalog: NSFileHandle?
    var datalogStart: NSDate?
    
    private var outputQueue = [[UInt8]]()
    
    var dataListeners = [FlightDataListener]()
    var dataListenersLock = NSObject()
    private var commChannel: CommChannel?
    
    var retriedMessages = Dictionary<MSP_code, MessageRetryHandler>()
    let retriedMessageLock = NSObject()
    
    var cliViewController: CLIViewController?
    
    private var receiveStats = [(date: NSDate, size: Int)]()
    private var sentDates = [MSP_code : NSDate]()
    private var msgLatencies = [MSP_code : Double]()
    
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
            if let sentDate = sentDates[mspCode] where -sentDate.timeIntervalSinceNow > latency {
                latency = -sentDate.timeIntervalSinceNow
            }
            latencies.append(min(latency, 1.0))
        }
        objc_sync_exit(self)

        latencies.sortInPlace()
        if latencies.count % 2 == 1 {
            return latencies[latencies.count / 2]
        } else {
            return (latencies[latencies.count / 2 - 1] + latencies[latencies.count / 2]) / 2
        }
    }
    
    func read(data: [UInt8]) {
        if cliViewController != nil {
            cliViewController!.receive(data)
            return
        }
        
        objc_sync_enter(self)
        if datalog != nil {
            var logData = [UInt8]()
            // Timestamp in milliseconds since start of logging
            logData.appendContentsOf(writeUInt32(Int(round(-datalogStart!.timeIntervalSinceNow * 1000))))
            logData.appendContentsOf(writeUInt16(min(data.count, Int(UINT16_MAX))))
            datalog!.writeData(NSData(bytes: logData, length: logData.count))
            datalog!.writeData(NSData(bytes: data, length: data.count))
        }
        //NSLog("Received %d bytes", data.count)
        
        receiveStats.insert((NSDate(), data.count), atIndex: 0)
        while receiveStats.count > 500 {
            receiveStats.removeLast()
        }
        objc_sync_exit(self)
        
        for b in data {
            if let (success, mspCode, message) = codec.decode(b) {
                objc_sync_enter(self)
                if let date = self.sentDates[mspCode] {
                    msgLatencies[mspCode] = -date.timeIntervalSinceNow
                    self.sentDates.removeValueForKey(mspCode)
                }
                objc_sync_exit(self)
                if success {
                    if processMessage(mspCode, message: message) {
                        callSuccessCallback(mspCode, data: message)
                    }
                } else {
                    callErrorCallback(mspCode)
                }
            }
        }
    }

    func processMessage(code: MSP_code, message: [UInt8]) -> Bool {
        let settings = Settings.theSettings
        let config = Configuration.theConfig
        let gpsData = GPSData.theGPSData
        let receiver = Receiver.theReceiver
        let misc = Misc.theMisc
        let sensorData = SensorData.theSensorData
        let motorData = MotorData.theMotorData
        
        switch code {
        case .MSP_IDENT:
            if message.count < 4 {
                return false
            }
            config.version = String(format:"%d.%02d", message[0] / 100, message[0] % 100)
            config.multiType = Int(message[1])
            config.mspVersion = Int(message[2])
            config.capability = readUInt32(message, index: 3)
            pingDataListeners()
            
        case .MSP_STATUS, .MSP_STATUS_EX:
            if message.count < 11 {
                return false
            }
            config.cycleTime = readUInt16(message, index: 0)
            config.i2cError = readUInt16(message, index: 2)
            config.activeSensors = readUInt16(message, index: 4)
            config.mode = readUInt32(message, index: 6)
            config.profile = Int(message[10])
            if message.count >= 13 {
                config.systemLoad = readUInt16(message, index: 11)
                if message.count >= 15 {
                    // Betaflight
                    config.rateProfile = Int(message[14])
                }
            }
            pingDataListeners()
            
        case .MSP_RAW_IMU:
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
            
            pingRawIMUListeners()
        
        case .MSP_SERVO:
            if message.count < 16 {
                return false
            }
            for i in 0..<8 {
                motorData.servoValue[i] = readUInt16(message, index: i*2)
            }
            pingMotorListeners()
        
        case .MSP_SERVO_CONFIGURATIONS:
            let servoConfSize = 14
            var servoConfigs = [ServoConfig]()
            for i in 0..<message.count / servoConfSize {
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
            pingSettingsListeners()
        
        case .MSP_MOTOR:
            if message.count < 16 {
                return false
            }
            var nMotors = 0
            for i in 0..<8 {
                motorData.throttle[i] = readUInt16(message, index: i*2)
                if (motorData.throttle[i] > 0) {
                    nMotors += 1
                }
            }
            motorData.nMotors = nMotors
            pingMotorListeners()
        
        case .MSP_UID:
            if message.count < 12 {
                return false
            }
            config.uid = String(format: "%04x%04x%04x", readUInt32(message, index: 0), readUInt32(message, index: 4), readUInt32(message, index: 8))
            pingDataListeners()
            
        case .MSP_ACC_TRIM:
            if message.count < 4 {
                return false
            }
            misc.accelerometerTrimPitch = readInt16(message, index: 0)
            misc.accelerometerTrimRoll = readInt16(message, index: 2)
            pingDataListeners()
            
        case .MSP_RC:
            var channelCount = message.count / 2
            if (channelCount > receiver.channels.count) {
                NSLog("MSP_RC Received %d channels instead of %d max", channelCount, receiver.channels.count)
                channelCount = receiver.channels.count
            }
            receiver.activeChannels = channelCount
            for i in 0..<channelCount {
                receiver.channels[i] = Int(readUInt16(message, index: (i * 2)));
            }
            pingReceiverListeners()
            
        case .MSP_RAW_GPS:
            if message.count < 16 {
                return false
            }

            gpsData.fix = message[0] != 0
            gpsData.numSat = Int(message[1])
            gpsData.position = GPSLocation(latitude: Double(readInt32(message, index: 2)) / 10000000, longitude: Double(readInt32(message, index: 6)) / 10000000)
            gpsData.altitude = readUInt16(message, index: 10)
            gpsData.speed = Double(readUInt16(message, index: 12)) * 0.036           // km/h = cm/s / 100 * 3.6
            gpsData.headingOverGround = Double(readUInt16(message, index: 14)) / 10  // 1/10 degree to degree
            pingGpsListeners()
            
        case .MSP_COMP_GPS:
            if message.count < 5 {
                return false
            }
            gpsData.distanceToHome = readUInt16(message, index: 0)
            gpsData.directionToHome = readUInt16(message, index: 2)
            gpsData.update = Int(message[4])
            pingGpsListeners()
            
        case .MSP_ATTITUDE:
            if message.count < 6 {
                return false
            }
            sensorData.rollAngle = Double(readInt16(message, index: 0)) / 10.0   // x
            sensorData.pitchAngle = Double(readInt16(message, index: 2)) / 10.0   // y
            sensorData.heading = Double(readInt16(message, index: 4))          // z
            pingSensorListeners()
            
        case .MSP_ALTITUDE:
            if message.count < 6 {
                return false
            }
            sensorData.altitude = Double(readInt32(message, index: 0)) / 100.0      // cm
            sensorData.variometer = Double(readInt16(message, index: 4)) / 100.0    // cm/s
            pingAltitudeListeners()
            
        case .MSP_SONAR:
            if message.count < 4 {
                return false
            }
            sensorData.sonar = readInt32(message,  index: 0);
            pingSonarListeners()

        case .MSP_ANALOG:
            if message.count < 7 {
                return false
            }
            config.voltage = Double(message[0]) / 10                                    // 1/10 V
            config.mAhDrawn = readUInt16(message, index: 1)
            config.rssi = readUInt16(message, index: 3) * 100 / 1023                    // 0-1023
            config.amperage = Double(readInt16(message, index: 5)) / 100                // 1/100 A
            pingDataListeners()
            
        case .MSP_RC_TUNING:
            if message.count < 10 {
                return false
            }
            settings.rcRate = Double(message[0]) / 100
            settings.rcExpo = Double(message[1]) / 100
            settings.rollRate = Double(message[2]) / 100
            settings.pitchRate = Double(message[3]) / 100
            settings.yawRate = Double(message[4]) / 100
            settings.tpaRate = Double(message[5]) / 100
            settings.throttleMid = Double(message[6]) / 100
            settings.throttleExpo = Double(message[7]) / 100
            settings.tpaBreakpoint = readUInt16(message, index: 8)
            if message.count >= 11 {
                settings.yawExpo = Double(message[10]) / 100
            }
            pingSettingsListeners()
            
        case .MSP_PID:
            settings.pidValues = [[Double]]()
            for i in 0..<message.count / 3 {
                settings.pidValues!.append([Double]())

                if config.isBetaflight {
                    settings.pidValues![i].append(Double(message[i*3]))
                    settings.pidValues![i].append(Double(message[i*3 + 1]))
                    settings.pidValues![i].append(Double(message[i*3 + 2]))
                } else if i <= 3 || i >= 7 {   // ROLL, PITCH, YAW, ALT, LEVEL, MAG, VEL
                    settings.pidValues![i].append(Double(message[i*3]) / 10)
                    settings.pidValues![i].append(Double(message[i*3 + 1]) / 1000)
                    settings.pidValues![i].append(Double(message[i*3 + 2]))
                } else if i == 4 {      // Pos
                    settings.pidValues![i].append(Double(message[i*3]) / 100)
                    settings.pidValues![i].append(Double(message[i*3 + 1]) / 100)
                    settings.pidValues![i].append(Double(message[i*3 + 2]) / 1000)
                } else {                // PosR, NavR
                    settings.pidValues![i].append(Double(message[i*3]) / 10)
                    settings.pidValues![i].append(Double(message[i*3 + 1]) / 100)
                    settings.pidValues![i].append(Double(message[i*3 + 2]) / 1000)
                }
            }
            pingSettingsListeners()
            
        case .MSP_ARMING_CONFIG:
            if message.count < 2 {
                return false
            }
            settings.autoDisarmDelay = Int(message[0])
            settings.disarmKillSwitch = message[1] != 0
            pingSettingsListeners()
            
        case .MSP_MISC: // 22 bytes
            if message.count < 18 {
                return false
            }
            var offset = 0
            misc.midRC = readInt16(message, index: offset)
            offset += 2
            misc.minThrottle = readInt16(message, index: offset) // 0-2000
            offset += 2
            misc.maxThrottle = readInt16(message, index: offset) // 0-2000
            offset += 2
            misc.minCommand = readInt16(message, index: offset) // 0-2000
            offset += 2
            misc.failsafeThrottle = readInt16(message, index: offset) // 0-2000
            offset += 2
            misc.gpsType = Int(message[offset])
            offset += 1
            misc.gpsBaudRate = Int(message[offset])
            offset += 1
            misc.gpsUbxSbas = Int(message[offset])
            offset += 1
            misc.multiwiiCurrentOutput = Int(message[offset])
            offset += 1
            misc.rssiChannel = Int(message[offset])
            offset += 1
            misc.placeholder2 = Int(message[offset])
            offset += 1
            misc.magDeclination = Double(readInt16(message, index: offset)) / 10 // -18000-18000
            if message.count >= 22 {
                offset += 2;
                misc.vbatScale = Int(message[offset]) // 10-200
                offset += 1
                misc.vbatMinCellVoltage = Double(message[offset]) / 10; // 10-50
                offset += 1
                misc.vbatMaxCellVoltage = Double(message[offset]) / 10; // 10-50
                offset += 1
                misc.vbatWarningCellVoltage = Double(message[offset]) / 10; // 10-50
            }
            pingDataListeners()
            
        case .MSP_MOTOR_PINS:
            // Unused
            if message.count < 8 {
                return false
            }
            break;
            
        case .MSP_BOXNAMES:
            settings.boxNames = [String]()
            var buf = [UInt8]()
            for i in 0..<message.count {
                if message[i] == 0x3B {     // ; (delimiter char)
                    settings.boxNames?.append(NSString(bytes: buf, length: buf.count, encoding: NSASCIIStringEncoding) as! String)
                    buf.removeAll()
                } else {
                    buf.append(message[i])
                }
            }
            pingSettingsListeners()
            
        case .MSP_PIDNAMES:
            settings.pidNames = [String]()
            var buf = [UInt8]()
            for i in 0..<message.count {
                if message[i] == 0x3B {     // ; (delimiter char)
                    settings.pidNames?.append(NSString(bytes: buf, length: buf.count, encoding: NSASCIIStringEncoding) as! String)
                    buf.removeAll()
                } else {
                    buf.append(message[i])
                }
            }
            pingSettingsListeners()
            
        case .MSP_WP:
            if message.count < 18 {
                return false
            }
            let wpNum = message[0]
            let position = GPSLocation(latitude: Double(readInt32(message, index: 1)) / 10000000, longitude: Double(readInt32(message, index: 5)) / 10000000)
            if wpNum == 0 {
                gpsData.homePosition = position
                pingGpsListeners()
            } else if wpNum == 16 {
                gpsData.posHoldPosition = position
                pingGpsListeners()
            }
            sensorData.altitudeHold = Double(readInt32(message, index: 9)) / 100    // cm
            sensorData.headingHold = Double(readInt16(message, index: 13))          // degrees - Custom firmware by Raph
            pingSensorListeners()
            
        case .MSP_BOXIDS:
            settings.boxIds = [Int]()
            for i in 0..<message.count {
                settings.boxIds?.append(Int(message[i]))
            }
            pingSettingsListeners()
            
        case .MSP_GPSSVINFO:
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
            
            pingGpsListeners()
            
        case .MSP_RX_CONFIG:
            if message.count < 8 {
                return false
            }
            settings.serialRxType = Int(message[0])
            settings.maxCheck = readUInt16(message, index: 1)
            misc.midRC = readUInt16(message, index: 3)
            settings.minCheck = readUInt16(message, index: 5)
            settings.spektrumSatBind = Int(message[7])
            if message.count >= 12 {
                settings.rxMinUsec = readUInt16(message, index: 8)
                settings.rxMaxUsec = readUInt16(message, index: 10)
            }
            pingDataListeners()         // FIXME
            pingSettingsListeners()
            
        case .MSP_FAILSAFE_CONFIG:
            if message.count < 8 {
                return false
            }
            settings.failsafeDelay = Double(message[0]) / 10
            settings.failsafeOffDelay = Double(message[1]) / 10
            misc.failsafeThrottle = readInt16(message, index: 2) // 0-2000
            settings.failsafeKillSwitch = message[4] != 0
            settings.failsafeThrottleLowDelay = Double(readUInt16(message, index: 5)) / 10
            settings.failsafeProcedure = Int(message[7])
            pingDataListeners()         // FIXME
            pingSettingsListeners()
            
        case .MSP_RXFAIL_CONFIG:
            if message.count % 3 != 0 {
                return false
            }
            settings.rxFailMode = [Int]()
            settings.rxFailValue = [Int]()
            for i in 0..<message.count / 3 {
                settings.rxFailMode!.append(Int(message[i * 3]))
                settings.rxFailValue!.append(readUInt16(message, index: i * 3 + 1))
            }
            pingSettingsListeners()
            
        case .MSP_RX_MAP:
            for (i, b) in message.enumerate() {
                if (i >= receiver.map.count) {
                    NSLog("MSP_RX_MAP received %d channels instead of %d", message.count, receiver.map.count)
                    break
                }
                receiver.map[i] = Int(b)
            }
            pingReceiverListeners()
            
        case .MSP_BF_CONFIG:
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
            pingSettingsListeners()

        // Cleanflight-specific
        case .MSP_API_VERSION:
            if message.count < 3 {
                return false
            }
            config.msgProtocolVersion = Int(message[0])
            config.apiVersion = String(format: "%d.%d", message[1], message[2])
            pingDataListeners()
            
        case .MSP_FC_VARIANT:
            if message.count < 4 {
                return false
            }
            config.fcIdentifier = String(format: "%c%c%c%c", message[0], message[1], message[2], message[3])
            pingDataListeners()
            
        case .MSP_FC_VERSION:
            if message.count < 3 {
                return false
            }
            config.fcVersion = String(format: "%d.%d.%d", message[0], message[1], message[2])
            pingDataListeners()
            
        case .MSP_BUILD_INFO:
            if message.count < 19 {
                return false
            }
            let date = NSString(bytes: message, length: 11, encoding: NSUTF8StringEncoding)
            let time = NSString(bytes: Array<UInt8>(message[11..<19]), length: 8, encoding: NSUTF8StringEncoding)
            /*
            if message.count >= 26 {
                let revision  = NSString(bytes: Array<UInt8>(message[19..<26]), length: 7, encoding: NSUTF8StringEncoding)
                NSLog("revision %@", revision!)
            }
            */
            config.buildInfo = String(format: "%@ %@", date!, time!)
            pingDataListeners()
            
        case .MSP_BOARD_INFO:
            if message.count < 6 {
                return false
            }
            config.boardInfo = String(format: "%c%c%c%c", message[0], message[1], message[2], message[3])
            config.boardVersion = readUInt16(message, index: 4)
            pingDataListeners()
            
        case .MSP_MODE_RANGES:
            let nRanges = message.count / 4
            var modeRanges = [ModeRange]()
            for i in 0..<nRanges {
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
            pingSettingsListeners()
            
        case .MSP_CF_SERIAL_CONFIG:
            let nPorts = message.count / 7
            if nPorts < 1 {
                return false
            }
            settings.portConfigs = [PortConfig]()
            for i in 0..<nPorts {
                let offset = i * 7
                settings.portConfigs!.append(PortConfig(portIdentifier: PortIdentifier(rawValue: Int(message[offset]))!, functions: PortFunction(rawValue: readUInt16(message, index: offset+1)), mspBaudRate: BaudRate(rawValue: Int(message[offset+3]))!, gpsBaudRate: BaudRate(rawValue: Int(message[offset+4]))!, telemetryBaudRate: BaudRate(rawValue: Int(message[offset+5]))!, blackboxBaudRate: BaudRate(rawValue: Int(message[offset+6]))!))
            }
            pingSettingsListeners()
            
        case .MSP_PID_CONTROLLER:
            if message.count < 1 {
                return false
            }
            settings.pidController = Int(message[0])
            pingSettingsListeners()

        case .MSP_DATAFLASH_SUMMARY:    // FIXME This is just a test
            if message.count < 13 {
                return false
            }
            let dataflash = Dataflash.theDataflash
            dataflash.ready = Int(message[0])
            dataflash.sectors = readUInt32(message, index: 1)
            dataflash.totalSize = readUInt32(message, index: 5)
            dataflash.usedSize = readUInt32(message, index: 9)
            
        case .MSP_DATAFLASH_READ:
            // Nothing to do. Handled by the callback
            break
        
        case .MSP_LOOP_TIME:
            if message.count < 2 {
                return false
            }
            settings.loopTime = readUInt16(message, index: 0)
            pingSettingsListeners()
            
        case .MSP_SIKRADIO:
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
            ping3drRssiListeners()
        
        // Betaflight
        case .MSP_PID_ADVANCED_CONFIG:
            if message.count < 6 {
                return false
            }
            settings.gyroSyncDenom = Int(message[0])
            settings.pidProcessDenom = Int(message[1])
            settings.useUnsyncedPwm = message[2] != 0
            settings.motorPwmProtocol = Int(message[3])
            settings.motorPwmRate = readUInt16(message, index: 4)
            pingSettingsListeners()
            
        case .MSP_FILTER_CONFIG:
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
            pingSettingsListeners()

        case .MSP_ADVANCED_TUNING:
            if message.count < 17 {
                return false
            }
            settings.rollPitchItermIgnoreRate = readUInt16(message, index: 0)
            settings.yawItermIgnoreRate = readUInt16(message, index: 2)
            settings.yawPLimit = readUInt16(message, index: 4)
            settings.deltaMethod = Int(message[6])
            settings.vbatPidCompensation = message[7] != 0
            settings.pTermSRateWeight = Int(message[8])
 //           settings.setpointRelaxRatio = Int(message[8])
            settings.dTermSetpointWeight = Int(message[9])
            settings.iTermThrottleGain = Int(message[12])
            settings.rateAccelLimit = readUInt16(message, index: 13)
            settings.yawRateAccelLimit = readUInt16(message, index: 15)
            pingSettingsListeners()
        
        case .MSP_SENSOR_CONFIG:
            if message.count < 3 {
                return false
            }
            settings.accelerometerDisabled = message[0] != 0
            settings.barometerDisabled = message[1] != 0
            settings.magnetometerDisabled = message[2] != 0
            pingSettingsListeners()
            
        // ACKs for sent commands
        case .MSP_SET_MISC,
            .MSP_SET_BF_CONFIG,
            .MSP_EEPROM_WRITE,
            .MSP_SET_REBOOT,
            .MSP_ACC_CALIBRATION,
            .MSP_MAG_CALIBRATION,
            .MSP_SET_ACC_TRIM,
            .MSP_SET_MODE_RANGE,
            .MSP_SET_ARMING_CONFIG,
            .MSP_SET_RC_TUNING,
            .MSP_SET_RX_MAP,
            .MSP_SET_PID_CONTROLLER,
            .MSP_SET_PID,
            .MSP_SELECT_SETTING,
            .MSP_SET_MOTOR,
            .MSP_DATAFLASH_ERASE,
            .MSP_SET_WP,
            .MSP_SET_SERVO_CONFIGURATION,
            .MSP_SET_CF_SERIAL_CONFIG,
            .MSP_SET_RAW_RC,
            .MSP_SET_RX_CONFIG,
            .MSP_SET_FAILSAFE_CONFIG,
            .MSP_SET_RXFAIL_CONFIG,
            .MSP_SET_LOOP_TIME,
            .MSP_SET_PID_ADVANCED_CONFIG,
            .MSP_SET_SENSOR_CONFIG:
            break
            
        default:
            NSLog("Unhandled message %d", code.rawValue)
            break
        }
        
        return true
    }
    
    func callSuccessCallback(code: MSP_code, data: [UInt8]) {
        var callback: ((success: Bool) -> Void)? = nil
        var dataCallback: ((data: [UInt8]) -> Void)? = nil
        
        objc_sync_enter(retriedMessageLock)
        if let retriedMessage = retriedMessages.removeValueForKey(code) {
            retriedMessage.cancelled = true
            retriedMessage.timer?.invalidate()
            if retriedMessage is DataMessageRetryHandler {
                dataCallback = (retriedMessage as! DataMessageRetryHandler).dataCallback
            } else {
                callback = retriedMessage.callback
            }
        }
        objc_sync_exit(retriedMessageLock)
        callback?(success: true)
        dataCallback?(data: data)
    }
    
    func makeSendMessageTimer(handler: MessageRetryHandler) {
        dispatch_async(dispatch_get_main_queue(), {
            if !handler.cancelled {
                handler.timer = NSTimer(timeInterval: 0.3, target: self, selector: #selector(MSPParser.sendMessageTimedOut(_:)), userInfo: handler, repeats: false)
                NSRunLoop.mainRunLoop().addTimer(handler.timer!, forMode: NSRunLoopCommonModes)
            }
        })
    }
    
    func sendMessage(code: MSP_code, data: [UInt8]?, retry: Int, flush: Bool = true, callback: ((success: Bool) -> Void)?) {
        if retry > 0 || callback != nil {
            let messageRetry = MessageRetryHandler(code: code, data: data, maxTries: retry, callback: callback)
            makeSendMessageTimer(messageRetry)
            
            objc_sync_enter(retriedMessageLock)
            retriedMessages[code] = messageRetry
            objc_sync_exit(retriedMessageLock)
        }
        addOutputMessage(codec.encode(code, message: data), flush: flush)
    }
    
    func sendMessage(code: MSP_code, data: [UInt8]?, flush: Bool = true) {
        sendMessage(code, data: data, retry: 0, flush: flush, callback: nil)
    }
    
    @objc
    func sendMessageTimedOut(timer: NSTimer) {
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
    
    private func callErrorCallback(code: MSP_code) {
        objc_sync_enter(retriedMessageLock)
        let handler = retriedMessages.removeValueForKey(code)
        objc_sync_exit(retriedMessageLock)
        if handler is DataMessageRetryHandler {
            (handler as! DataMessageRetryHandler).dataCallback(data: nil)
        } else if handler != nil {
            handler!.callback?(success: false)
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
    
    func addDataListener(listener: FlightDataListener) {
        objc_sync_enter(dataListenersLock);
        dataListeners.append(listener);
        objc_sync_exit(dataListenersLock);
    }
    
    func removeDataListener(listener: FlightDataListener) {
        objc_sync_enter(dataListenersLock);
        for (i, l) in dataListeners.enumerate() {
            if (l === listener) {
                dataListeners.removeAtIndex(i)
                break
            }
        }
        objc_sync_exit(dataListenersLock);
    }

    func pingListeners(delegate: ((listener: FlightDataListener) -> Void)) {
        var dataListenersCopy: [FlightDataListener]?
        
        objc_sync_enter(dataListenersLock);
        dataListenersCopy = [FlightDataListener](dataListeners)
        objc_sync_exit(dataListenersLock);
        
        dispatch_async(dispatch_get_main_queue(), {
            for l in dataListenersCopy! {
                delegate(listener: l)
            }
        })
    }
    func pingDataListeners() {
        pingListeners { (listener) -> Void in
            listener.receivedData?()
        }
    }
    func pingGpsListeners() {
        pingListeners { (listener) -> Void in
            listener.receivedGpsData?()
        }
    }
    func pingReceiverListeners() {
        pingListeners { (listener) -> Void in
            listener.receivedReceiverData?()
        }
    }
    func pingSensorListeners() {
        pingListeners { (listener) -> Void in
            listener.receivedSensorData?()
        }
    }
    func pingMotorListeners() {
        pingListeners { (listener) -> Void in
            listener.receivedMotorData?()
        }
    }
    func pingSettingsListeners() {
        pingListeners { (listener) -> Void in
            listener.receivedSettingsData?()
        }
    }
    func pingCommunicationStatusListeners(status: Bool) {
        pingListeners { (listener) -> Void in
            listener.communicationStatus?(status)
        }
    }
    func pingRawIMUListeners() {
        pingListeners { (listener) -> Void in
            listener.receivedRawIMUData?()
        }
    }
    func pingSonarListeners() {
        pingListeners { (listener) -> Void in
            listener.receivedSonarData?()
        }
    }
    func pingAltitudeListeners() {
        pingListeners { (listener) -> Void in
            listener.receivedAltitudeData?()
        }
    }
    func ping3drRssiListeners() {
        pingListeners { (listener) -> Void in
            listener.received3drRssiData?()
        }
    }
    
    func sendSetMisc(misc: Misc, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.appendContentsOf(writeInt16(misc.midRC))
        data.appendContentsOf(writeInt16(misc.minThrottle))
        data.appendContentsOf(writeInt16(misc.maxThrottle))
        data.appendContentsOf(writeInt16(misc.minCommand))
        data.appendContentsOf(writeInt16(misc.failsafeThrottle))
        data.append(UInt8(misc.gpsType))
        data.append(UInt8(misc.gpsBaudRate))
        data.append(UInt8(misc.gpsUbxSbas))
        data.append(UInt8(misc.multiwiiCurrentOutput))
        data.append(UInt8(misc.rssiChannel))
        data.append(UInt8(misc.placeholder2))
        data.appendContentsOf(writeInt16(Int(round(misc.magDeclination * 10))))
        data.append(UInt8(misc.vbatScale))
        data.append(UInt8(round(misc.vbatMinCellVoltage * 10)))
        data.append(UInt8(round(misc.vbatMaxCellVoltage * 10)))
        data.append(UInt8(round(misc.vbatWarningCellVoltage * 10)))
        
        sendMessage(.MSP_SET_MISC, data: data, retry: 2, callback: callback)
    }
    
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
    
    func sendSetAccTrim(misc: Misc, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.appendContentsOf(writeInt16(misc.accelerometerTrimPitch))
        data.appendContentsOf(writeInt16(misc.accelerometerTrimRoll))
        
        sendMessage(.MSP_SET_ACC_TRIM, data: data, retry: 2, callback: callback)
    }
    
    func sendSetModeRange(index: Int, range: ModeRange, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(index))
        data.append(UInt8(range.id))
        data.append(UInt8(range.auxChannelId))
        data.append(UInt8((range.start - 900) / 25))
        data.append(UInt8((range.end - 900) / 25))
        
        sendMessage(.MSP_SET_MODE_RANGE, data: data, retry: 2, callback: callback)
    }
    
    func sendSetArmingConfig(settings: Settings, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(settings.autoDisarmDelay))
        data.append(UInt8(settings.disarmKillSwitch ? 1 : 0))
        
        sendMessage(.MSP_SET_ARMING_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendSetRcTuning(settings: Settings, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(round(settings.rcRate * 100)))
        data.append(UInt8(round(settings.rcExpo * 100)))
        data.append(UInt8(round(settings.rollRate * 100)))
        data.append(UInt8(round(settings.pitchRate * 100)))
        data.append(UInt8(round(settings.yawRate * 100)))
        data.append(UInt8(round(settings.tpaRate * 100)))
        data.append(UInt8(round(settings.throttleMid * 100)))
        data.append(UInt8(round(settings.throttleExpo * 100)))
        data.appendContentsOf(writeInt16(settings.tpaBreakpoint))
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.10") {
            data.append(UInt8(round(settings.yawExpo * 100)))
            if config.isBetaflight {
                data.append(UInt8(round(settings.yawRate * 100)))
            }
        }
        
        sendMessage(.MSP_SET_RC_TUNING, data: data, retry: 2, callback: callback)
    }
    
    func sendSetRxMap(map: [UInt8], callback:((success:Bool) -> Void)?) {
        sendMessage(.MSP_SET_RX_MAP, data: map, retry: 2, callback: callback)
    }
    
    func sendPidController(pidController: Int, callback:((success:Bool) -> Void)?) {
        sendMessage(.MSP_SET_PID_CONTROLLER, data: [ UInt8(pidController) ], retry: 2, callback: callback)
    }
    
    func sendPid(settings: Settings, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        for (idx,pid) in settings.pidValues!.enumerate() {
            let p = pid[0]
            let i = pid[1]
            let d = pid[2]
            if Configuration.theConfig.isBetaflight {
                data.append(UInt8(round(p)))
                data.append(UInt8(round(i)))
                data.append(UInt8(round(d)))
            } else if idx <= 3 || idx >= 7 {   // ROLL, PITCH, YAW, ALT, LEVEL, MAG, VEL
                data.append(UInt8(round(p * 10)))
                data.append(UInt8(round(i * 1000)))
                data.append(UInt8(round(d)))
            } else if idx == 4 {        // Pos
                data.append(UInt8(round(p * 100)))
                data.append(UInt8(round(i * 100)))
                data.append(UInt8(round(d * 1000)))
            } else {                    // PosR, NavR
                data.append(UInt8(round(p * 10)))
                data.append(UInt8(round(i * 100)))
                data.append(UInt8(round(d * 1000)))
            }

        }
        sendMessage(.MSP_SET_PID, data: data, retry: 2, callback: callback)
    }
    
    func sendSelectProfile(profile: Int, callback:((success:Bool) -> Void)?) {
        // Note: this call includes a write eeprom
        sendMessage(.MSP_SELECT_SETTING, data: [ UInt8(profile) ], retry: 2, callback: callback)
    }
    
    // Betaflight
    func sendSelectRateProfile(rateProfile: Int, callback:((success:Bool) -> Void)?) {
        sendMessage(.MSP_SELECT_SETTING, data: [ UInt8(rateProfile & 0x80) ], retry: 2, callback: callback)
    }
    
    func sendDataflashRead(address: Int, callback:(data: [UInt8]?) -> Void) {
        let data = writeUInt32(address)
        let messageRetry = DataMessageRetryHandler(code: .MSP_DATAFLASH_READ, data: data, maxTries: 3, callback: callback)
        makeSendMessageTimer(messageRetry)
        
        objc_sync_enter(retriedMessageLock)
        retriedMessages[.MSP_DATAFLASH_READ] = messageRetry
        objc_sync_exit(retriedMessageLock)
        sendMessage(.MSP_DATAFLASH_READ, data: data, retry: 0, callback: nil)
    }
    
    // Waypoint number 0 is GPS Home location, waypoint number 16 is GPS Hold location, other values are ignored
    // Pass altitude=0 to keep current AltHold value
    func sendWaypoint(number: Int, latitude: Double, longitude: Double, altitude: Double, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(number))
        data.appendContentsOf(writeInt32(Int(latitude * 10000000.0)))
        data.appendContentsOf(writeInt32(Int(longitude * 10000000.0)))
        data.appendContentsOf(writeInt32(Int(altitude)))
        data.appendContentsOf([0, 0, 0, 0, 0])  // Future: heading (16), time to stay (16), nav flags
        
        sendMessage(.MSP_SET_WP, data: data, retry: 2, callback: callback)
    }
    
    func setServoConfig(servoIdx: Int, servoConfig: ServoConfig, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(servoIdx))
        data.appendContentsOf(writeInt16(servoConfig.minimumRC))
        data.appendContentsOf(writeInt16(servoConfig.maximumRC))
        data.appendContentsOf(writeInt16(servoConfig.middleRC))
        data.append(writeInt8(servoConfig.rate))
        data.append(UInt8(servoConfig.minimumAngle))
        data.append(UInt8(servoConfig.maximumAngle))
        data.append(UInt8(servoConfig.rcChannel == nil ? CHANNEL_FORWARDING_DISABLED : servoConfig.rcChannel!))
        data.appendContentsOf(writeUInt32(servoConfig.reversedSources))
        
        sendMessage(.MSP_SET_SERVO_CONFIGURATION, data: data, retry: 2, callback: callback)
    }
    
    func sendSerialConfig(settings: Settings, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        for portConfig in settings.portConfigs! {
            data.append(UInt8(portConfig.portIdentifier.rawValue))
            data.appendContentsOf(writeUInt16(portConfig.functions.rawValue))
            data.append(UInt8(portConfig.mspBaudRate.rawValue))
            data.append(UInt8(portConfig.gpsBaudRate.rawValue))
            data.append(UInt8(portConfig.telemetryBaudRate.rawValue))
            data.append(UInt8(portConfig.blackboxBaudRate.rawValue))
        }
        
        sendMessage(.MSP_SET_CF_SERIAL_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendRawRc(values: [Int]) {
        var data = [UInt8]()
        for v in values {
            data.appendContentsOf(writeUInt16(v))
        }
        sendMessage(.MSP_SET_RAW_RC, data: data)
    }
    
    func sendRxConfig(settings: Settings, midRc: Int, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(settings.serialRxType))
        data.appendContentsOf(writeUInt16(settings.maxCheck))
        data.appendContentsOf(writeUInt16(midRc))
        data.appendContentsOf(writeUInt16(settings.minCheck))
        data.append(UInt8(settings.spektrumSatBind))
        data.appendContentsOf(writeUInt16(settings.rxMinUsec))
        data.appendContentsOf(writeUInt16(settings.rxMaxUsec))
        sendMessage(.MSP_SET_RX_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendFailsafeConfig(settings: Settings, failsafeThrottle: Int, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(Int(settings.failsafeDelay * 10)))
        data.append(UInt8(Int(settings.failsafeOffDelay * 10)))
        data.appendContentsOf(writeUInt16(failsafeThrottle))
        data.append(UInt8(settings.failsafeKillSwitch ? 1 : 0))
        data.appendContentsOf(writeUInt16(Int(settings.failsafeThrottleLowDelay * 10)))
        data.append(UInt8(settings.failsafeProcedure))
        sendMessage(.MSP_SET_FAILSAFE_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendRxFailConfig(settings: Settings, index: Int = 0, callback:((success:Bool) -> Void)?) {
        if settings.rxFailMode!.count == 0 {
            // Happens when RX config is invalid
            callback?(success: true)
            return
        }
        var data = [UInt8]()
        data.append(UInt8(index))
        data.append(UInt8(settings.rxFailMode![index]))
        data.appendContentsOf(writeUInt16(settings.rxFailValue![index]))
        sendMessage(.MSP_SET_RXFAIL_CONFIG, data: data, retry: 2, callback: { success in
            if success {
                if index < settings.rxFailMode!.count - 1 {
                    self.sendRxFailConfig(settings, index: index + 1, callback: callback)
                } else {
                    callback?(success: true)
                }
            } else {
                callback?(success: false)
            }
        })
    }
    
    func sendLoopTime(settings: Settings, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.appendContentsOf(writeUInt16(settings.loopTime))
        sendMessage(.MSP_SET_LOOP_TIME, data: data, retry: 2, callback: callback)
    }
    
    // Betaflight
    
    func sendPidAdvancedConfig(settings: Settings, callback:((success: Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(settings.gyroSyncDenom))
        data.append(UInt8(settings.pidProcessDenom))
        data.append(UInt8(settings.useUnsyncedPwm ? 1 : 0))
        data.append(UInt8(settings.motorPwmProtocol))
        data.appendContentsOf(writeUInt16(settings.motorPwmRate))
        sendMessage(.MSP_SET_PID_ADVANCED_CONFIG, data: data, retry: 2, callback: callback)
    }

    func sendSensorConfig(settings: Settings, callback:((success: Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(settings.accelerometerDisabled ? 1 : 0))
        data.append(UInt8(settings.barometerDisabled ? 1 : 0))
        data.append(UInt8(settings.magnetometerDisabled ? 1 : 0))
        sendMessage(.MSP_SET_SENSOR_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func openCommChannel(commChannel: CommChannel) {
        self.commChannel = commChannel
        pingCommunicationStatusListeners(true)
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
        pingCommunicationStatusListeners(false)
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
    
    func nextOutputMessage() -> [UInt8]? {
        objc_sync_enter(self)
        if outputQueue.isEmpty {
            objc_sync_exit(self)
            return nil
        }
        let msg = outputQueue.removeFirst()
        
        if msg[0] == 36 {   // $
            if let mspCode = MSP_code(rawValue: Int(msg[4])) where latencyMsgs.contains(mspCode) {
                let sentDate = sentDates[mspCode]
                if sentDate == nil {
                    sentDates[mspCode] = NSDate()
                }
            }
        }
        objc_sync_exit(self)
        
        return msg
    }
    
    func addOutputMessage(msg: [UInt8], flush: Bool = true) {
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
    
    func setRssi(rssi: Double) {
        Configuration.theConfig.btRssi = Int(round(constrain((104 + rssi) / 78 * 100, min: 0, max: 100)))
        
        pingDataListeners()
    }
}
