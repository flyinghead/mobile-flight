//
//  MSP.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

enum ParserState : Int { case Sync1 = 0, Sync2, Direction, Length, Code, Payload, Checksum };

class MessageRetryHandler {
    let code: MSP_code
    let data: [UInt8]?
    let callback: ((success: Bool) -> Void)?
    let maxTries: Int
    var timer: NSTimer?
    
    var tries = 0
    
    init(code: MSP_code, data: [UInt8]?, maxTries: Int, callback: ((success: Bool) -> Void)?) {
        self.code = code
        self.data = data
        self.maxTries = maxTries
        self.callback = callback
    }
}

class MSPParser {
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
    var commChannel: CommChannel?
    
    var retriedMessages = Dictionary<MSP_code, MessageRetryHandler>()
    let retriedMessageLock = NSObject()
    
    func read(data: [UInt8]) {
        for b in data {
            switch state {
            case .Sync1:
                if (b == 36) { // $
                    state = .Sync2
                }
            case .Sync2:
                if (b == 77) { // M
                    state = .Direction
                }
            case .Direction:
                if (b == 62) { // >
                    directionOut = false
                } else {
                    directionOut = true
                }
                state = .Length
            case .Length:
                expectedMsgLength = Int(b);
                checksum = b;
                
                messageBuffer = [UInt8]()
                state = .Code
            case .Code:
                code = b
                checksum ^= b
                if (expectedMsgLength > 0) {
                    state = .Payload
                } else {
                    state = .Checksum       // No payload
                }
            case .Payload:
                messageBuffer?.append(b);
                checksum ^= b
                if (messageBuffer?.count >= expectedMsgLength) {
                    state = .Checksum
                }
            case .Checksum:
                let mspCode = MSP_code(rawValue: Int(code)) ?? .MSP_UNKNOWN
                if (checksum == b && mspCode != .MSP_UNKNOWN) {
                    //NSLog("Received MSP %d", code.rawValue)
                    if processMessage(mspCode, message: messageBuffer!) {
                        removeSendMessageTimer(mspCode)
                    }
                } else {
                    let datalog = NSData(bytes: messageBuffer!, length: expectedMsgLength)
                    if checksum != b {
                        NSLog("MSP code %d - checksum failed: %@", code, datalog)
                    } else {
                        NSLog("Unknown MSP code %d: %@", code, datalog)
                    }
                    errors++
                }
                state = .Sync1
            }
        }
    }
    
    private func getUInt16(array: [UInt8], index: Int) -> Int {
        return Int(array[index]) + Int(array[index+1]) * 256;
    }
    
    private func getInt16(array: [UInt8], index: Int) -> Int {
        return Int(array[index]) + Int(Int8(bitPattern: array[index+1])) * 256;
    }
    
    private func getUInt32(array: [UInt8], index: Int) -> UInt32 {
        var res = UInt32(array[index+3])
        res = res * 256 + UInt32(array[index+2])
        res = res * 256 + UInt32(array[index+1])
        res = res * 256 + UInt32(array[index])
        return res
    }
    
    private func getInt32(array: [UInt8], index: Int) -> Int {
        var res = Int(Int8(bitPattern: array[index+3]))
        res = res * 256 + Int(array[index+2])
        res = res * 256 + Int(array[index+1])
        res = res * 256 + Int(array[index])
        return res
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
            NSLog("Using deprecated msp command: MSP_IDENT")
            // Deprecated
            config.version = String(format:"%d.%02d", message[0] / 100, message[0] % 100)
            config.multiType = Int(message[1])
            config.mspVersion = Int(message[2])
            config.capability = getUInt32(message, index: 3)
            pingDataListeners()
            
        case .MSP_STATUS:
            if message.count < 11 {
                return false
            }
            config.cycleTime = getUInt16(message, index: 0)
            config.i2cError = getUInt16(message, index: 2)
            config.activeSensors = getUInt16(message, index: 4)
            config.mode = getUInt32(message, index: 6)
            config.profile = Int(message[10])
            pingDataListeners()
            
        case .MSP_RAW_IMU:
            if message.count < 18 {
                return false
            }
            // 512 for mpu6050, 256 for mma
            // currently we are unable to differentiate between the sensor types, so we are going with 512
            sensorData.accelerometerX = Double(getInt16(message, index: 0)) / 512.0
            sensorData.accelerometerY = Double(getInt16(message, index: 2)) / 512.0
            sensorData.accelerometerZ = Double(getInt16(message, index: 4)) / 512.0
            // properly scaled
            sensorData.gyroscopeX = Double(getInt16(message, index: 6)) * (4 / 16.4)
            sensorData.gyroscopeY = Double(getInt16(message, index: 8)) * (4 / 16.4)
            sensorData.gyroscopeZ = Double(getInt16(message, index: 10)) * (4 / 16.4)
            // no clue about scaling factor
            sensorData.magnetometerX = Double(getInt16(message, index: 12)) / 1090
            sensorData.magnetometerY = Double(getInt16(message, index: 14)) / 1090
            sensorData.magnetometerZ = Double(getInt16(message, index: 16)) / 1090
            
            pingSensorListeners()
            
        case .MSP_MOTOR:
            if message.count < 16 {
                return false
            }
            var nMotors = 0
            for (var i = 0; i < 8; i++) {
                motorData.throttle[i] = getUInt16(message, index: i*2)
                if (motorData.throttle[i] > 0) {
                    nMotors++
                }
            }
            motorData.nMotors = nMotors
            pingMotorListeners()
            
        case .MSP_RC:
            var channelCount = message.count / 2
            if (channelCount > receiver.channels.count) {
                NSLog("MSP_RC Received %d channels instead of %d max", channelCount, receiver.channels.count)
                channelCount = receiver.channels.count
            }
            receiver.activeChannels = channelCount
            for (var i = 0; i < channelCount; i++) {
                receiver.channels[i] = Int(getUInt16(message, index: (i * 2)));
            }
            pingReceiverListeners()
            
        case .MSP_RAW_GPS:
            if message.count < 16 {
                return false
            }
            gpsData.fix = message[0] != 0
            gpsData.numSat = Int(message[1])
            gpsData.latitude = Double(getInt32(message, index: 2)) / 10000000
            gpsData.longitude = Double(getInt32(message, index: 6)) / 10000000
            gpsData.altitude = getUInt16(message, index: 10)
            gpsData.speed = getUInt16(message, index: 12)
            gpsData.headingOverGround = getUInt16(message, index: 14)
            pingGpsListeners()
            
        case .MSP_COMP_GPS:
            if message.count < 5 {
                return false
            }
            gpsData.distanceToHome = getUInt16(message, index: 0)
            gpsData.directionToHome = getUInt16(message, index: 2)
            gpsData.update = Int(message[4])
            pingGpsListeners()
            
        case .MSP_ATTITUDE:
            if message.count < 6 {
                return false
            }
            sensorData.kinematicsX = Double(getInt16(message, index: 0)) / 10.0   // x
            sensorData.kinematicsY = Double(getInt16(message, index: 2)) / 10.0   // y
            sensorData.kinematicsZ = Double(getInt16(message, index: 4))          // z
            pingSensorListeners()
            
        case .MSP_ALTITUDE:
            if message.count < 2 {
                return false
            }
            sensorData.altitude = Double(getInt32(message, index: 0)) / 100.0 // correct scale factor
            pingSensorListeners()
            
        case .MSP_SONAR:
            if message.count < 2 {
                return false
            }
            sensorData.sonar = getInt32(message,  index: 0);
            pingSensorListeners()

        case .MSP_ANALOG:
            if message.count < 7 {
                return false
            }
            config.voltage = Double(message[0]) / 10
            config.mAhDrawn = getUInt16(message, index: 1)
            config.rssi = getUInt16(message, index: 3)                      // 0-1023
            config.amperage = Double(getInt16(message, index: 5)) / 100     // A
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
            settings.dynamicThrottlePid = Double(message[5]) / 100
            settings.throttleMid = Double(message[6]) / 100
            settings.throttleExpo = Double(message[7]) / 100
            settings.dynamicThrottleBreakpoint = getUInt16(message, index: 8)
            if message.count >= 11 {
                settings.yawExpo = Double(message[10]) / 100
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
            misc.midRC = getInt16(message, index: offset)
            offset += 2
            misc.minThrottle = getInt16(message, index: offset) // 0-2000
            offset += 2
            misc.maxThrottle = getInt16(message, index: offset) // 0-2000
            offset += 2
            misc.minCommand = getInt16(message, index: offset) // 0-2000
            offset += 2
            misc.failsafeThrottle = getInt16(message, index: offset) // 0-2000
            offset += 2
            misc.gpsType = Int(message[offset++])
            misc.gpsBaudRate = Int(message[offset++])
            misc.gpsUbxSbas = Int(message[offset++])
            misc.multiwiiCurrentOutput = Int(message[offset++])
            misc.rssiChannel = Int(message[offset++])
            misc.placeholder2 = Int(message[offset++])
            misc.magDeclination = Double(getInt16(message, index: offset)) / 10 // -18000-18000
            offset += 2;
            misc.vbatScale = Int(message[offset++]) // 10-200
            misc.vbatMinCellVoltage = Double(message[offset++]) / 10; // 10-50
            misc.vbatMaxCellVoltage = Double(message[offset++]) / 10; // 10-50
            misc.vbatWarningCellVoltage = Double(message[offset++]) / 10; // 10-50
            pingDataListeners()
            
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
                sats.append(Satellite(channel: Int(message[i * 4 + 1]), svid: Int(message[i * 4 + 2]), quality: GpsSatQuality(rawValue: message[i * 4 + 3]), cno: Int(message[i * 4 + 4])))
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
            settings.features = BaseFlightFeature(rawValue: getUInt32(message, index: 1))
            settings.serialRxType = Int(message[5])
            settings.boardAlignRoll = Int(getInt16(message, index: 6))
            settings.boardAlignPitch = Int(getInt16(message, index: 8))
            settings.boardAlignYaw = Int(getInt16(message, index: 10))
            settings.currentScale = Int(getInt16(message, index: 12))
            settings.currentOffset = Int(getInt16(message, index: 14))
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
            if message.count < 11 {
                return false
            }
            let date = NSString(bytes: message, length: 11, encoding: NSUTF8StringEncoding)
            let time = NSString(bytes: Array<UInt8>(message[11..<message.count]), length: 8, encoding: NSUTF8StringEncoding)
            config.buildInfo = String(format: "%@ %@", date!, time!)
            pingDataListeners()
            
        case .MSP_BOARD_INFO:
            if message.count < 6 {
                return false
            }
            config.boardInfo = String(format: "%c%c%c%c", message[0], message[1], message[2], message[3])
            config.boardVersion = getUInt16(message, index: 4)
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
            
        case .MSP_UID:
            if message.count < 12 {
                return false
            }
            config.uid = String(format: "%04x%04x%04x", getUInt32(message, index: 0), getUInt32(message, index: 4), getUInt32(message, index: 8))
            pingDataListeners()
            
        case .MSP_ACC_TRIM:
            if message.count < 4 {
                return false
            }
            config.accelerometerTrimPitch = getInt16(message, index: 0)
            config.accelerometerTrimRoll = getInt16(message, index: 2)
            pingDataListeners()
            
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
            .MSP_SET_RX_MAP:
            break
            
        default:
            NSLog("Unhandled message %d", code.rawValue)
            break
        }
        
        return true
    }
    
    func removeSendMessageTimer(code: MSP_code) {
        var callback: ((success: Bool) -> Void)?
        objc_sync_enter(retriedMessageLock)
        if let retriedMessage = retriedMessages.removeValueForKey(code) {
            retriedMessage.timer!.invalidate()
            callback = retriedMessage.callback
        }
        objc_sync_exit(retriedMessageLock)
        if callback != nil {
            callback!(success: true)
        }
    }
    
    func makeSendMessageTimer(handler: MessageRetryHandler) -> NSTimer {
        return NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: "sendMessageTimedOut:", userInfo: handler, repeats: false)
    }
    
    func sendMessage(code: MSP_code, data: [UInt8]?, retry: Int, callback: ((success: Bool) -> Void)?) {
        if retry > 0 || callback != nil {
            let messageRetry = MessageRetryHandler(code: code, data: data, maxTries: retry, callback: callback)
            messageRetry.timer = makeSendMessageTimer(messageRetry)
            
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
            NSLog("sendMessage %d failed", handler.code.rawValue)
            objc_sync_enter(retriedMessageLock)
            retriedMessages.removeValueForKey(handler.code)
            objc_sync_exit(retriedMessageLock)
            if handler.callback != nil {
                handler.callback!(success: false)
            }
            return
        }
        NSLog("Retrying sendMessage %d", handler.code.rawValue)
        handler.timer = makeSendMessageTimer(handler)

        sendMessage(handler.code, data: handler.data, retry: 0, callback: nil)
    }
    
    func cancelRetries() {
        objc_sync_enter(retriedMessageLock)
        for handler in retriedMessages.values {
            handler.timer!.invalidate()
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
        data.appendContentsOf(writeInt16(Int(misc.magDeclination * 10)))
        data.append(UInt8(misc.vbatScale))
        data.append(UInt8(misc.vbatMinCellVoltage * 10))
        data.append(UInt8(misc.vbatMaxCellVoltage * 10))
        data.append(UInt8(misc.vbatWarningCellVoltage * 10))
        
        sendMessage(.MSP_SET_MISC, data: data, retry: 2, callback: callback)
    }
    
    func sendSetBfConfig(settings: Settings, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(settings.mixerConfiguration!))
        data.appendContentsOf(writeUInt32(settings.features!.rawValue))
        data.append(UInt8(settings.serialRxType!))
        data.appendContentsOf(writeInt16(settings.boardAlignRoll!))
        data.appendContentsOf(writeInt16(settings.boardAlignPitch!))
        data.appendContentsOf(writeInt16(settings.boardAlignYaw!))
        data.appendContentsOf(writeInt16(settings.currentScale!))
        data.appendContentsOf(writeInt16(settings.currentOffset!))
        
        sendMessage(.MSP_SET_BF_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendSetAccTrim(config: Configuration, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.appendContentsOf(writeInt16(config.accelerometerTrimPitch))
        data.appendContentsOf(writeInt16(config.accelerometerTrimRoll))
        
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
        data.append(UInt8(settings.autoDisarmDelay!))
        data.append(UInt8(settings.disarmKillSwitch ? 1 : 0))
        
        sendMessage(.MSP_SET_ARMING_CONFIG, data: data, retry: 2, callback: callback)
    }
    
    func sendSetRcTuning(settings: Settings, callback:((success:Bool) -> Void)?) {
        var data = [UInt8]()
        data.append(UInt8(settings.rcRate * 100))
        data.append(UInt8(settings.rcExpo * 100))
        data.append(UInt8(settings.rollRate * 100))
        data.append(UInt8(settings.pitchRate * 100))
        data.append(UInt8(settings.yawRate * 100))
        data.append(UInt8(settings.dynamicThrottlePid * 100))
        data.append(UInt8(settings.throttleMid * 100))
        data.append(UInt8(settings.throttleExpo * 100))
        data.appendContentsOf(writeInt16(settings.dynamicThrottleBreakpoint))
        if Configuration.theConfig.isApiVersionAtLeast("1.10") {
            data.append(UInt8(settings.yawExpo * 100))
        }
        
        sendMessage(.MSP_SET_RC_TUNING, data: data, retry: 2, callback: callback)
    }
    
    func sendSetRxMap(map: [UInt8], callback:((success:Bool) -> Void)?) {
        sendMessage(.MSP_SET_RX_MAP, data: map, retry: 2, callback: callback)
    }
    
    func writeUInt32(i: UInt32) -> [UInt8] {
        return [UInt8(i % 256), UInt8((i >> 8) % 256), UInt8((i >> 16) % 256), UInt8(i >> 24)]
    }
    func writeInt16(i: Int) -> [UInt8] {
        return [UInt8(UInt(bitPattern: i) & 0xFF), UInt8((UInt(bitPattern: i) >> 8) & 0xFF)]
    }
}