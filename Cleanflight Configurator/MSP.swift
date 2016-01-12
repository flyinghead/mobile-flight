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

enum ParserState : Int { case Sync1 = 0, Sync2, Direction, Length, Code, Payload, Checksum };

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
    
    var datalog: NSFileHandle?
    var datalogStart: NSDate?
    
    var state: ParserState = .Sync1
    var directionOut: Bool = false
    var expectedMsgLength: Int = 0
    var checksum: UInt8 = 0
    var messageBuffer: [UInt8]?
    var code: UInt8 = 0
    var errors: Int = 0
    var outputQueue = [UInt8]()
    
    var dataListeners = [FlightDataListener]()
    var dataListenersLock = NSObject()
    private var commChannel: CommChannel?
    
    var retriedMessages = Dictionary<MSP_code, MessageRetryHandler>()
    let retriedMessageLock = NSObject()
    
    var receiveStats = [(date: NSDate, size: Int)]()
    
    var incomingBytesPerSecond: Int {
        var byteCount = 0
        for (date, size) in receiveStats {
            if -date.timeIntervalSinceNow >= 1 {
                break
            }
            byteCount += size
        }
        return byteCount
    }
    
    func read(data: [UInt8]) {
        if datalog != nil {
            var logData = [UInt8]()
            // Timestamp in milliseconds since start of logging
            logData.appendContentsOf(writeUInt32(Int(round(-datalogStart!.timeIntervalSinceNow * 1000))))
            logData.appendContentsOf(writeUInt16(min(data.count, Int(UINT16_MAX))))
            datalog!.writeData(NSData(bytes: logData, length: logData.count))
            datalog!.writeData(NSData(bytes: data, length: data.count))
        }
        
        receiveStats.insert((NSDate(), data.count), atIndex: 0)
        while receiveStats.count > 500 {
            receiveStats.removeLast()
        }
            
        for b in data {
            switch state {
            case .Sync1:
                if b == 36 { // $
                    state = .Sync2
                }
            case .Sync2:
                if b == 77 { // M
                    state = .Direction
                } else {
                    state = .Sync1
                }
            case .Direction:
                if b == 62 { // >
                    directionOut = false
                    state = .Length
                } else if b == 60 {
                    directionOut = true
                    state = .Length
                } else {
                    state = .Sync1
                }
            case .Length:
                expectedMsgLength = Int(b);
                checksum = b;
                
                messageBuffer = [UInt8]()
                state = .Code
            case .Code:
                code = b
                checksum ^= b
                if expectedMsgLength > 0 {
                    state = .Payload
                } else {
                    state = .Checksum       // No payload
                }
            case .Payload:
                messageBuffer?.append(b);
                checksum ^= b
                if messageBuffer?.count >= expectedMsgLength {
                    state = .Checksum
                }
            case .Checksum:
                let mspCode = MSP_code(rawValue: Int(code)) ?? .MSP_UNKNOWN
                if checksum == b && mspCode != .MSP_UNKNOWN && !directionOut {
                    //NSLog("Received MSP %d", mspCode.rawValue)
                    if processMessage(mspCode, message: messageBuffer!) {
                        callSuccessCallback(mspCode, data: messageBuffer!)
                    }
                } else {
                    let datalog = NSData(bytes: messageBuffer!, length: expectedMsgLength)
                    if checksum != b {
                        NSLog("MSP code %d - checksum failed: %@", code, datalog)
                    } else if directionOut {
                        NSLog("MSP code %d - received outgoing message", code)
                    } else {
                        NSLog("Unknown MSP code %d: %@", code, datalog)
                    }
                    errors++
                }
                state = .Sync1
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
            NSLog("Received deprecated msp command: MSP_IDENT")
            // Deprecated
            config.version = String(format:"%d.%02d", message[0] / 100, message[0] % 100)
            config.multiType = Int(message[1])
            config.mspVersion = Int(message[2])
            config.capability = readUInt32(message, index: 3)
            pingDataListeners()
            
        case .MSP_STATUS:
            if message.count < 11 {
                return false
            }
            config.cycleTime = readUInt16(message, index: 0)
            config.i2cError = readUInt16(message, index: 2)
            config.activeSensors = readUInt16(message, index: 4)
            config.mode = readUInt32(message, index: 6)
            config.profile = Int(message[10])
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
            for var i = 0; i < 8; i++ {
                motorData.servoValue[i] = readUInt16(message, index: i*2)
            }
            pingMotorListeners()
        
        case .MSP_SERVO_CONFIGURATIONS:
            let servoConfSize = 14
            var servoConfigs = [ServoConfig]()
            for (var i = 0; (i + 1) * servoConfSize <= message.count; i++) {
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
            for (var i = 0; i < 8; i++) {
                motorData.throttle[i] = readUInt16(message, index: i*2)
                if (motorData.throttle[i] > 0) {
                    nMotors++
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
            for (var i = 0; i < channelCount; i++) {
                receiver.channels[i] = Int(readUInt16(message, index: (i * 2)));
            }
            pingReceiverListeners()
            
        case .MSP_RAW_GPS:
            if message.count < 16 {
                return false
            }
            gpsData.fix = message[0] != 0
            gpsData.numSat = Int(message[1])
            gpsData.latitude = Double(readInt32(message, index: 2)) / 10000000
            gpsData.longitude = Double(readInt32(message, index: 6)) / 10000000
            gpsData.altitude = readUInt16(message, index: 10)
            gpsData.speed = Double(readUInt16(message, index: 12)) * 0.036           // km/h = cm/s / 100 * 3.6
            gpsData.headingOverGround = Double(readUInt16(message, index: 14)) / 10  // 1/10 degree to degree
            
            if gpsData.fix {
                gpsData.lastKnownGoodLatitude = gpsData.latitude
                gpsData.lastKnownGoodLongitude = gpsData.longitude
                gpsData.lastKnownGoodAltitude = gpsData.altitude
                gpsData.lastKnownGoodTimestamp = NSDate()
                
                gpsData.positions.append(CLLocationCoordinate2D(latitude: gpsData.latitude, longitude: gpsData.longitude))
            }
            gpsData.maxAltitude = max(gpsData.maxAltitude, gpsData.altitude)
            gpsData.maxSpeed = max(gpsData.maxSpeed, gpsData.speed)
            pingGpsListeners()
            
        case .MSP_COMP_GPS:
            if message.count < 5 {
                return false
            }
            gpsData.distanceToHome = readUInt16(message, index: 0)
            gpsData.directionToHome = readUInt16(message, index: 2)
            gpsData.update = Int(message[4])
            gpsData.maxDistanceToHome = max(gpsData.maxDistanceToHome, gpsData.distanceToHome)
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
            if message.count < 4 {
                return false
            }
            sensorData.altitude = Double(readInt32(message, index: 0)) / 100.0 // correct scale factor
            sensorData.maxAltitude = max(sensorData.maxAltitude, sensorData.altitude)
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
            if settings.features.contains(.VBat) ?? false {
                if config.batteryCells == 0  && misc.vbatMaxCellVoltage > 0 {
                    config.batteryCells = Int(config.voltage / misc.vbatMaxCellVoltage + 1)
                }
            }
            config.maxAmperage = max(config.maxAmperage, config.amperage)
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
            for var i = 0; i < message.count / 3; i++ {
                settings.pidValues!.append([Double]())
                
                if i <= 3 || i >= 7 {   // ROLL, PITCH, YAW, ALT, LEVEL, MAG, VEL
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
            if message.count < 22 {
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
            misc.gpsType = Int(message[offset++])
            misc.gpsBaudRate = Int(message[offset++])
            misc.gpsUbxSbas = Int(message[offset++])
            misc.multiwiiCurrentOutput = Int(message[offset++])
            misc.rssiChannel = Int(message[offset++])
            misc.placeholder2 = Int(message[offset++])
            misc.magDeclination = Double(readInt16(message, index: offset)) / 10 // -18000-18000
            offset += 2;
            misc.vbatScale = Int(message[offset++]) // 10-200
            misc.vbatMinCellVoltage = Double(message[offset++]) / 10; // 10-50
            misc.vbatMaxCellVoltage = Double(message[offset++]) / 10; // 10-50
            misc.vbatWarningCellVoltage = Double(message[offset++]) / 10; // 10-50
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
            for (var i = 0; i < message.count; i++) {
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
            for (var i = 0; i < message.count; i++) {
                if message[i] == 0x3B {     // ; (delimiter char)
                    settings.pidNames?.append(NSString(bytes: buf, length: buf.count, encoding: NSASCIIStringEncoding) as! String)
                    buf.removeAll()
                } else {
                    buf.append(message[i])
                }
            }
            pingSettingsListeners()
            
        case .MSP_BOXIDS:
            settings.boxIds = [Int]()
            for (var i = 0; i < message.count; i++) {
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
            for (var i = 0; i < numSat; i++) {
                sats.append(Satellite(channel: Int(message[i * 4 + 1]), svid: Int(message[i * 4 + 2]), quality: GpsSatQuality(rawValue: Int(message[i * 4 + 3])), cno: Int(message[i * 4 + 4])))
            }
            gpsData.satellites = sats
            
            pingGpsListeners()
            
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
            if message.count >= 26 {
                let revision  = NSString(bytes: Array<UInt8>(message[19..<26]), length: 7, encoding: NSUTF8StringEncoding)
                NSLog("revision %@", revision!)
            }
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
            for (var i = 0; i < nRanges; i++) {
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
            .MSP_SET_SERVO_CONFIGURATION:
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
        // FIXME This sucks. NSTimer should not be scheduled on the main thread. Ideally they should be on their own run loop? or concurrent?
        dispatch_async(dispatch_get_main_queue(), {
            if !handler.cancelled {
                handler.timer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: "sendMessageTimedOut:", userInfo: handler, repeats: false)
            }
        })
    }
    
    func sendMessage(code: MSP_code, data: [UInt8]?, retry: Int, callback: ((success: Bool) -> Void)?) {
        if retry > 0 || callback != nil {
            let messageRetry = MessageRetryHandler(code: code, data: data, maxTries: retry, callback: callback)
            makeSendMessageTimer(messageRetry)
            
            objc_sync_enter(retriedMessageLock)
            retriedMessages[code] = messageRetry
            objc_sync_exit(retriedMessageLock)
        }
        let dataSize = data != nil ? data!.count : 0
        //                      $    M   <
        var buffer: [UInt8] = [36 , 77, 60, UInt8(dataSize), UInt8(code.rawValue)]
        var checksum: UInt8 = UInt8(code.rawValue) ^ buffer[3];
        
        if (data != nil) {
            buffer.appendContentsOf(data!)
            for b in data! {
                checksum ^= b
            }
        }
        buffer.append(checksum);
        
        objc_sync_enter(self)
        outputQueue.appendContentsOf(buffer);
        objc_sync_exit(self)
        commChannel?.flushOut()
    }
    
    func sendMessage(code: MSP_code, data: [UInt8]?) {
        sendMessage(code, data: data, retry: 0, callback: nil)
    }
    
    @objc
    func sendMessageTimedOut(timer: NSTimer) {
        let handler = timer.userInfo as! MessageRetryHandler
        if ++handler.tries > handler.maxTries {
            handler.cancelled = true
            NSLog("sendMessage %d failed", handler.code.rawValue)
            objc_sync_enter(retriedMessageLock)
            retriedMessages.removeValueForKey(handler.code)
            objc_sync_exit(retriedMessageLock)
            if handler is DataMessageRetryHandler {
                (handler as! DataMessageRetryHandler).dataCallback(data: nil)
            } else {
                handler.callback?(success: false)
            }
            return
        }
        NSLog("Retrying sendMessage %d", handler.code.rawValue)
        makeSendMessageTimer(handler)

        sendMessage(handler.code, data: handler.data, retry: 0, callback: nil)
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
        if Configuration.theConfig.isApiVersionAtLeast("1.10") {
            data.append(UInt8(round(settings.yawExpo * 100)))
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
            if idx <= 3 || idx >= 7 {   // ROLL, PITCH, YAW, ALT, LEVEL, MAG, VEL
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
    
    func sendSelectProfile(profile: Int,callback:((success:Bool) -> Void)?) {
        // Note: this call includes a write eeprom
        sendMessage(.MSP_SELECT_SETTING, data: [ UInt8(profile) ], retry: 2, callback: callback)
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

    func openCommChannel(commChannel: CommChannel) {
        self.commChannel = commChannel
        pingCommunicationStatusListeners(true)
    }
    
    func closeCommChannel() {
        cancelRetries()
        commChannel?.close()
        commChannel = nil
        FlightLogFile.close(self)
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
}