//
//  MAVLink.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 20/02/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//
import Foundation
import UIKit

class MAVLink : ProtocolHandler {
    private let mySystemId = UInt8(255)         // See SYSID_MYGCS. APM will only accept rcoverride from corresponding GCS. 255: MissionPlanner and DriodPlanner, 252: APM Planner 2
    private let myComponentId = UInt8(MAV_COMP_ID_MISSIONPLANNER.rawValue)
    // Target system
    private var systemId: UInt8 = 1
    private var componentId: UInt8 = 1
    
    private(set) var protocolRecognized = false
    
    private var outputBuffer = [UInt8]()
    private var commChannel: CommChannel?
    
    private var lastDataReceived: NSDate?
    private var dataReceivedTimer: NSTimer?
    
    private var lastReveivedMessageIsHeartbeat = false
    private var heartbeatTimer: NSTimer?
    private var status = mavlink_status_t()
    
    private var failsafeBatteryVoltage: Double?
    
    private var messageHandlers = [Int32 : [MAVLinkMessageHandler]]()
    
    var datalog: NSFileHandle? {
        didSet {
            if datalog != nil {
                datalogStart = NSDate()
            } else {
                datalogStart = nil
            }
        }
    }
    private var datalogStart: NSDate?
    
    var _vehicle = MAVLinkVehicle()
    var vehicle: Vehicle { return _vehicle }
    
    var loadedParameters: [MAVLinkParameter?]?      // Set to the correct size as soon as the total number of params is known. nil entries are params not yet received.
    var lastParamReceived: NSDate?
    var requestingAllParams = false
    var allParamsLoaderListener: ((Int) -> Void)?
    var retryParameterIndex = -1
    
    func read(data: [UInt8]) {
        var msg = mavlink_message_t()
        
        
        for c in data {
            if mavlink_parse_char(0, c, &msg, &status) == 1 {
                // Message received
                let msgId = Int32(msg.msgid)

                //NSLog("Received MAVLink msg %d (%d, %d)", msg.msgid, msg.sysid, msg.compid)
                
                if (msgId != MAVLINK_MSG_ID_RADIO_STATUS && msgId != MAVLINK_MSG_ID_RADIO) || msg.sysid != 51  || msg.compid != 68 {
                    // RADIO and RADIO_STATUS messages are injected into the stream by the local radio itself (system id '3', component id 'D')
                    if msgId != MAVLINK_MSG_ID_HEARTBEAT {
                        lastReveivedMessageIsHeartbeat = false
                    }
                    protocolRecognized = true
                    synchronized(self) {
                        self.lastDataReceived = NSDate()
                    }
                    vehicle.noDataReceived.value = false
                }

                switch msgId {
                case MAVLINK_MSG_ID_ATTITUDE:
                    vehicle.rollAngle.value = Double(mavlink_msg_attitude_get_roll(&msg)) * 180 / M_PI
                    vehicle.pitchAngle.value = -Double(mavlink_msg_attitude_get_pitch(&msg)) * 180 / M_PI
                    //vehicle.heading.value = Double(mavlink_msg_attitude_get_yaw(&msg)) * 180 / M_PI
                    vehicle.turnRate.value = Double(mavlink_msg_attitude_get_yawspeed(&msg)) * 180 / M_PI
                    
                case MAVLINK_MSG_ID_HEARTBEAT:      // Sent every second
                    systemId = msg.sysid
                    componentId = msg.compid
                    if lastReveivedMessageIsHeartbeat && !replaying {
                        // Not receiving other messages. Re-send our data streams request
                        requestMAVLinkRates()
                    }
                    lastReveivedMessageIsHeartbeat = true
                    //let autopilot = MAV_AUTOPILOT(UInt32(mavlink_msg_heartbeat_get_autopilot(&msg)))
                    let baseMode = MAV_MODE_FLAG(UInt32(mavlink_msg_heartbeat_get_base_mode(&msg)))
                    let wasArmed = vehicle.armed.value
                    vehicle.armed.value = baseMode.rawValue & MAV_MODE_FLAG_SAFETY_ARMED.rawValue != 0
                    if !wasArmed && vehicle.armed.value {
                        // Refresh home position when arming
                        requestHomePosition()
                    }
                    
                    _vehicle.flightMode.value = ArduCopterFlightMode(rawValue: Int(mavlink_msg_heartbeat_get_custom_mode(&msg))) ?? .UNKNOWN
                    //let systemStatus = MAV_STATE(UInt32(mavlink_msg_heartbeat_get_system_status(&msg)))
                    //let type = MAV_TYPE(UInt32(mavlink_msg_heartbeat_get_type(&msg)))
                    //NSLog("Heartbeat status=%d mode: %@", systemStatus.rawValue, _vehicle.flightMode.value.modeName())
                    
                case MAVLINK_MSG_ID_GLOBAL_POSITION_INT:
                    vehicle.position.value = Position(latitude: Double(mavlink_msg_global_position_int_get_lat(&msg)) / 10000000, longitude: Double(mavlink_msg_global_position_int_get_lon(&msg)) / 10000000)
                    vehicle.altitude.value = Double(mavlink_msg_global_position_int_get_relative_alt(&msg)) / 1000
                    vehicle.heading.value = Double(mavlink_msg_global_position_int_get_hdg(&msg)) / 100
                    let vz = Double(mavlink_msg_global_position_int_get_vz(&msg)) / 100
                    let vx = Double(mavlink_msg_global_position_int_get_vx(&msg)) / 100
                    let vy = Double(mavlink_msg_global_position_int_get_vy(&msg)) / 100
                    vehicle.verticalSpeed.value = vz
                    vehicle.speed.value = sqrt(vx * vx + vy * vy + vz * vz) / 1000 * 3600
                    
                    if (vehicle.position.value!.latitude != 0 || vehicle.position.value!.longitude != 0) {
                        if vehicle.homePosition.value == nil {
                            requestHomePosition()
                        }  else {
                            vehicle.distanceToHome.value = getDistance(vehicle.homePosition.value!.position2d, vehicle.position.value!)
                        }
                    }
                    
                case MAVLINK_MSG_ID_SYS_STATUS:
                    vehicle.batteryVolts.value = Double(mavlink_msg_sys_status_get_voltage_battery(&msg)) / 1000
                    vehicle.batteryAmps.value = Double(mavlink_msg_sys_status_get_current_battery(&msg)) / 100
                    _vehicle.batteryRemaining.value = Int(mavlink_msg_sys_status_get_battery_remaining(&msg))
                    //let present = mavlink_msg_sys_status_get_onboard_control_sensors_present(&msg)
                    //let enabled = mavlink_msg_sys_status_get_onboard_control_sensors_enabled(&msg)
                    //let healthy = mavlink_msg_sys_status_get_onboard_control_sensors_health(&msg)
                    //NSLog("Sensors: %0x %0x %0x", present, enabled, healthy)
                    // TODO sensors
                    
                case MAVLINK_MSG_ID_GPS_RAW_INT:
                    vehicle.gpsFix.value = mavlink_msg_gps_raw_int_get_fix_type(&msg) == 3
                    vehicle.gpsNumSats.value = Int(mavlink_msg_gps_raw_int_get_satellites_visible(&msg))
                
                case MAVLINK_MSG_ID_NAV_CONTROLLER_OUTPUT:
                    if altitudeHoldActive() {
                        vehicle.altitudeHold.value = vehicle.altitude.value + Double(mavlink_msg_nav_controller_output_get_alt_error(&msg)) // TODO Check
                    } else {
                        vehicle.altitudeHold.value = nil
                    }
                    if navigationActive() {
                        vehicle.navigationHeading.value = Double(mavlink_msg_nav_controller_output_get_nav_bearing(&msg))
                        vehicle.navigationSpeed.value = vehicle.speed.value + Double(mavlink_msg_nav_controller_output_get_aspd_error(&msg)) // TODO Check
                        vehicle.waypointDistance.value = Double(mavlink_msg_nav_controller_output_get_wp_dist(&msg))
                    } else {
                        vehicle.navigationHeading.value = nil
                        vehicle.navigationSpeed.value = nil
                        vehicle.waypointDistance.value = nil
                    }
                
                case MAVLINK_MSG_ID_MISSION_CURRENT:
                    _vehicle.currentMissionItem.value = Int(mavlink_msg_mission_current_get_seq(&msg))
                    
                case MAVLINK_MSG_ID_MISSION_ITEM:
                    let seq = mavlink_msg_mission_item_get_seq(&msg)
                    if seq == 0 {   // Home position
                        let latitude = mavlink_msg_mission_item_get_x(&msg)
                        let longitude = mavlink_msg_mission_item_get_y(&msg)
                        let altitude = mavlink_msg_mission_item_get_z(&msg)
                        vehicle.homePosition.value = Position3D(position2d: Position(latitude: Double(latitude), longitude: Double(longitude)), altitude: Double(altitude))
                    }
                    
                case MAVLINK_MSG_ID_STATUSTEXT:
                    var charBytes = [Int8](count: 51, repeatedValue: 0)
                    mavlink_msg_statustext_get_text(&msg, &charBytes)
                    let messageText = NSString(bytes: charBytes, length: charBytes.count, encoding: NSASCIIStringEncoding)!
                    let severity = UInt32(mavlink_msg_statustext_get_severity(&msg))
                    // BUG in APM < 3.4 (?) severity levels are: LOW=1, MEDIUM=2, HIGH=3, CRITICAL=4
                    NSLog("MESSAGE %d - %@", severity, messageText)
                    if severity > 1 {
                        VoiceMessage.theVoice.speak(messageText as String)
                    }
                    _vehicle.autopilotMessage.newEvent((severity: MAV_SEVERITY(6 - severity), message: messageText as String))
                    
                case MAVLINK_MSG_ID_PARAM_VALUE:
                    let totalParamCount = Int(mavlink_msg_param_value_get_param_count(&msg))
                    if loadedParameters == nil {
                        loadedParameters = [MAVLinkParameter?](count: totalParamCount, repeatedValue: nil)
                    }
                    
                    let mavlinkParameter = parseParamValueMessage(msg)
                    if mavlinkParameter.index != 65535 {    // Parameter index is not known
                        loadedParameters![mavlinkParameter.index] = mavlinkParameter
                        _vehicle.parametersById[mavlinkParameter.paramId] = mavlinkParameter
                    }
                    
                    paramReceived(mavlinkParameter.paramId, value: mavlinkParameter.value)

                    if _vehicle.parametersById.count == totalParamCount {
                        // All params received
                        NSLog("All params received")
                        lastParamReceived = nil
                        retryParameterIndex = -1
                        requestingAllParams = false
                        _vehicle.parametersLoaded = true
                        dispatch_async(dispatch_get_main_queue(), {
                            self.allParamsLoaderListener?(100)
                            self.allParamsLoaderListener = nil
                        })
                    } else {
                        lastParamReceived = NSDate()
                        dispatch_async(dispatch_get_main_queue(), {
                            self.allParamsLoaderListener?(self._vehicle.parametersById.count * 100 / totalParamCount)
                        })
                        if retryParameterIndex != -1 {
                            retryNextParameter()
                        }
                    }

                case MAVLINK_MSG_ID_RC_CHANNELS_RAW:
                    let rawRssi = mavlink_msg_rc_channels_raw_get_rssi(&msg)
                    if rawRssi == 255 {
                        vehicle.rssi.value = nil
                    } else {
                        vehicle.rssi.value = Int(rawRssi)
                    }
                    // Reverse pitch channel
                    var pitch = Int(mavlink_msg_rc_channels_raw_get_chan2_raw(&msg))
                    if pitch > 900 {
                        pitch = 3000 - pitch
                    }
                    var rcChannels = [
                        Int(mavlink_msg_rc_channels_raw_get_chan1_raw(&msg)), pitch, Int(mavlink_msg_rc_channels_raw_get_chan3_raw(&msg)), Int(mavlink_msg_rc_channels_raw_get_chan4_raw(&msg)), Int(mavlink_msg_rc_channels_raw_get_chan5_raw(&msg)), Int(mavlink_msg_rc_channels_raw_get_chan6_raw(&msg)), Int(mavlink_msg_rc_channels_raw_get_chan7_raw(&msg)), Int(mavlink_msg_rc_channels_raw_get_chan8_raw(&msg)) ]
                    while rcChannels.last == 65535 {
                        rcChannels.popLast()
                    }
                    for i in 0..<rcChannels.count {
                        if rcChannels[i] == 65535 {
                            rcChannels[i] = 0
                        }
                    }
                    vehicle.rcChannels.value = rcChannels
                    
                case MAVLINK_MSG_ID_COMMAND_ACK:
                    let cmd = mavlink_msg_command_ack_get_command(&msg)
                    let result = mavlink_msg_command_ack_get_result(&msg)
                    NSLog("Command %d result=%d", cmd, result)
                    
                case MAVLINK_MSG_ID_SERVO_OUTPUT_RAW:
                    // Servo/motors output
                    break
                
                case MAVLINK_MSG_ID_FENCE_STATUS:
                    _vehicle.fenceBreached.value = mavlink_msg_fence_status_get_breach_status(&msg) != 0
                    _vehicle.fenceBreachType.value = FENCE_BREACH(UInt32(mavlink_msg_fence_status_get_breach_type(&msg)))
                    
                case MAVLINK_MSG_ID_POWER_STATUS:
                    // 5V rail and servo rail voltage
                    break
                    
                case MAVLINK_MSG_ID_MEMINFO:
                    // Free/used APM RAM
                    break
                    
                case MAVLINK_MSG_ID_AHRS2:
                    // Status of secondary AHRS filter
                    break
                    
                case MAVLINK_MSG_ID_RADIO, MAVLINK_MSG_ID_RADIO_STATUS:
                    // TODO: SiK radio RSSI
                    break
                    
                default:
                    NSLog("Unknown MAVLink msg %d", msg.msgid)
                }
                
                // Match message handlers
                if let handlers = messageHandlers[msgId] {
                    for handler in handlers {
                        if handler.match(msg) {
                            break
                        }
                    }
                }
            }
        }
    }
    
    private func requestMAVLinkRates() {
        var msg = mavlink_message_t()
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_RAW_SENSORS.rawValue), 0, 0)         // 2Hz: RAW_IMU, SCALED_PRESSURE, (Enable IMU_RAW, GPS_RAW, GPS_STATUS packets)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTENDED_STATUS.rawValue), 2, 1)     // 2Hz: SYS_STATUS, GPS_RAW_INT, MISSION_CURRENT, NAV_CONTROLLER_OUTPUT, FENCE_STATUS (Enable GPS_STATUS, CONTROL_STATUS, AUX_STATUS)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_RC_CHANNELS.rawValue), 5, 1)         // 5Hz: RC_CHANNELS_RAW, SERVO_OUTPUT_RAW (Enable RC_CHANNELS_SCALED, RC_CHANNELS_RAW, SERVO_OUTPUT_RAW)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_RAW_CONTROLLER.rawValue), 0, 0)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_POSITION.rawValue), 2, 1)            // 2Hz: GLOBAL_POSITION_INT (Enable LOCAL_POSITION, GLOBAL_POSITION/GLOBAL_POSITION_INT messages)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTRA1.rawValue), 5, 1)              // 5Hz: ATTITUDE, AHRS2
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTRA2.rawValue), 0, 0)              // 2Hz: VFR_HUD
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTRA3.rawValue), 0, 0)
        sendMAVLinkMsg(msg)
    }
    
    private func cancelMAVLinkRates() {
        var msg = mavlink_message_t()
        //mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_RAW_SENSORS.rawValue), 0, 0)
        //sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTENDED_STATUS.rawValue), 0, 0)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_RC_CHANNELS.rawValue), 0, 0)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_POSITION.rawValue), 0, 0)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTRA1.rawValue), 0, 0)
        sendMAVLinkMsg(msg)
        //mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTRA2.rawValue), 0, 0)
        //sendMAVLinkMsg(msg)
    }

    func sendMAVLinkMsg(var msg: mavlink_message_t) {
        var buf = [UInt8](count: 128, repeatedValue: 0)  // Max size?
        let len = mavlink_msg_to_send_buffer(&buf, &msg)
        synchronized(self) {
            self.outputBuffer.appendContentsOf(buf.prefix(Int(len)))
        }
        commChannel?.flushOut()
    }
    
    func recognizeProtocol(commChannel: CommChannel) {
        self.commChannel = commChannel
    }
    
    func detachCommChannel() {
        self.commChannel = nil
    }
    
    func openCommChannel(commChannel: CommChannel) {
        self.commChannel = commChannel
        if !replaying {
            heartbeatTimer = NSTimer(timeInterval: 1.0, target: self, selector: "heartbeatTimer:", userInfo: nil, repeats: true)
            NSRunLoop.mainRunLoop().addTimer(heartbeatTimer!, forMode: NSRunLoopCommonModes)
            dataReceivedTimer = NSTimer(timeInterval: 0.1, target: self, selector: "dataReceivedTimer:", userInfo: nil, repeats: true)
            NSRunLoop.mainRunLoop().addTimer(dataReceivedTimer!, forMode: NSRunLoopCommonModes)
        }
        vehicle.replaying.value = commChannel is ReplayComm
        vehicle.connected.value = true
        vehicle.rcOutEnabled.value = true       // Can send RC_OVERRIDE
        
        requestMAVLinkRates()
        requestParam("FS_BATT_VOLTAGE")
    }
    
    func closeCommChannel() {
        vehicle.connected.value = false
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        dataReceivedTimer?.invalidate()
        dataReceivedTimer = nil
        
        cancelMAVLinkRates()
        commChannel?.close()
        commChannel = nil
    }
    
    @objc
    private func heartbeatTimer(timer: NSTimer) {
        if communicationHealthy {
            let chanStatus = mavlink_get_channel_status(0)
            NSLog("MAVLink stats: %d overruns, %d drops, %d parse errors", chanStatus.memory.buffer_overrun, chanStatus.memory.packet_rx_drop_count, chanStatus.memory.parse_error)
            
            // Needed?
            //var msg = mavlink_message_t()
            //mavlink_msg_heartbeat_pack(mySystemId, myComponentId, &msg, UInt8(MAV_TYPE_GCS.rawValue), UInt8(MAV_AUTOPILOT_INVALID.rawValue), 0, 0, 0)
            //sendMAVLinkMsg(msg)
        }
    }
    
    @objc
    private func dataReceivedTimer(timer: NSTimer) {
        var lastDataReceivedInterval: NSTimeInterval!
        synchronized(self) {
            lastDataReceivedInterval = -(self.lastDataReceived?.timeIntervalSinceNow ?? 0)
        }
        if lastDataReceivedInterval > 0.75 && communicationHealthy {
            // Set warning if no data received for 0.75 sec
            vehicle.noDataReceived.value = true
        } else {
            if requestingAllParams {
                var lastParamReceivedInterval: NSTimeInterval!
                synchronized(self) {
                    lastParamReceivedInterval = -(self.lastParamReceived?.timeIntervalSinceNow ?? 0)
                }
                if lastParamReceivedInterval > 0.5 {
                    NSLog("Param receive timeout")
                    lastParamReceived = NSDate()
                    if _vehicle.parametersById.count < 400 {
                        var msg = mavlink_message_t()
                        mavlink_msg_param_request_list_pack(mySystemId, myComponentId, &msg, systemId, componentId)
                        sendMAVLinkMsg(msg)
                    } else {
                        // Re-request missing parameters (10 max)
                        if retryParameterIndex == -1 {
                            retryParameterIndex = 0
                        }
                        for _ in 0..<10  {
                            retryNextParameter()
                        }
                    }
                }
            }
        }
    }
    
    var communicationEstablished: Bool {
        return commChannel != nil
    }
    var communicationHealthy: Bool {
        return communicationEstablished && (commChannel?.connected ?? false)
    }
    var replaying: Bool {
        return commChannel is ReplayComm
    }
    func nextOutputMessage() -> [UInt8]? {
        var tmpOut: [UInt8]?
        synchronized(self) {
            tmpOut = self.outputBuffer
            if tmpOut!.isEmpty {
                tmpOut = nil
            } else {
                self.outputBuffer.removeAll()
            }
        }

        return tmpOut;
    }

    private func altitudeHoldActive() -> Bool {
        let flightMode = _vehicle.flightMode.value
        return flightMode != .STABILIZE && flightMode != .DRIFT && flightMode != .ACRO && flightMode != .FLIP && flightMode != .UNKNOWN  && flightMode != .THROW
    }
    
    private func navigationActive() -> Bool {
        let flightMode = _vehicle.flightMode.value
        return flightMode == .AUTO || flightMode == .GUIDED || flightMode == .LOITER || flightMode == .RTL || flightMode == .CIRCLE || flightMode == .POSHOLD
    }
    
    private func requestParam(param: String) {
        NSLog("Requesting param %@", param)
        var msg = mavlink_message_t()
        let nsparam = param as NSString
        mavlink_msg_param_request_read_pack(mySystemId, myComponentId, &msg, systemId, componentId, nsparam.cStringUsingEncoding(NSASCIIStringEncoding), -1)
        _ = ParamGetSetMessageHandler(self, msg: msg, paramIndex: -1, paramId: param)
    }
    
    private func requestParam(index: Int) {
        NSLog("Requesting param %d", index)
        var msg = mavlink_message_t()
        mavlink_msg_param_request_read_pack(mySystemId, myComponentId, &msg, systemId, componentId, nil, Int16(index))
        sendMAVLinkMsg(msg)
    }
    
    private func paramReceived(paramId: String, value: Double) {
        switch paramId {
            case "FS_BATT_VOLTAGE":
            failsafeBatteryVoltage = value
            vehicle.batteryVoltsWarning.value = failsafeBatteryVoltage! * 1.03
            vehicle.batteryVoltsCritical.value = failsafeBatteryVoltage
            
        default:
            break
        }
    }
    
    func executeCommand(command: UInt32) {
        var msg = mavlink_message_t()
        mavlink_msg_command_long_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt16(command), 0, 0, 0, 0, 0, 0, 0, 0)
        sendMAVLinkMsg(msg)
    }
    
    func requestHomePosition() {
        //executeCommand(MAV_CMD_GET_HOME_POSITION)     // APM 3.4+

        var msg = mavlink_message_t()
        // Waypoint #0 is Home/Launch location
        mavlink_msg_mission_request_pack(mySystemId, myComponentId, &msg, systemId, componentId, 0)
        _ = MAVLinkMessageHandler(self, msg: msg, expectedReply: MAVLINK_MSG_ID_MISSION_ITEM)
    }
    
    func requestAllParameters(listener: ((Int) -> Void)?) {
        allParamsLoaderListener = listener
        if !requestingAllParams {
            requestingAllParams = true
            retryParameterIndex = -1
            _vehicle.parametersById.removeAll()
            loadedParameters = nil
            _vehicle.parametersLoaded = false
            lastParamReceived = NSDate()
            var msg = mavlink_message_t()
            mavlink_msg_param_request_list_pack(mySystemId, myComponentId, &msg, systemId, componentId)
            sendMAVLinkMsg(msg)
        }
    }
    
    private func retryNextParameter() {
        for _ in 0..<loadedParameters!.count {
            if retryParameterIndex >= loadedParameters!.count {
                retryParameterIndex = 0
            }
            if loadedParameters![retryParameterIndex] == nil {
                requestParam(retryParameterIndex++)
                return
            } else {
                retryParameterIndex++
            }
        }
    }
    
    func parseParamValueMessage(var msg: mavlink_message_t) -> MAVLinkParameter {
        var charBytes = [Int8](count: 17, repeatedValue: 0)
        mavlink_msg_param_value_get_param_id(&msg, &charBytes)
        let paramId = NSString(CString: charBytes, encoding: NSASCIIStringEncoding)! as String
        
        let paramType = MAV_PARAM_TYPE(rawValue: UInt32(mavlink_msg_param_value_get_param_type(&msg)))
        // Avoid rounding errors when converting directly from float to double
        let doubleValue = Double(NSNumber(float: mavlink_msg_param_value_get_param_value(&msg)).stringValue)!
        
        var paramIndex = Int(mavlink_msg_param_value_get_param_index(&msg))
        if paramIndex == 65535 {
            if let existingParam = _vehicle.parametersById[paramId] {
                paramIndex = existingParam.index
            }
        }
        return MAVLinkParameter(paramId: paramId, index: paramIndex, type: paramType, value: doubleValue)
    }

    func addMessageHandler(msgid: Int32, handler: MAVLinkMessageHandler) {
        messageHandlers[msgid] = (messageHandlers[msgid] ?? []) + [handler]
    }
    
    func removeMessageHandler(msgid: Int32, handler: MAVLinkMessageHandler) {
        if let handlersArray = messageHandlers[msgid] {
            messageHandlers[msgid] = handlersArray.filter({ $0 !== handler })
        }
    }
    
    func setParameter(param: MAVLinkParameter, callback: ((success: Bool) -> Void)?) {
        var msg = mavlink_message_t()
        let value = Float(String(param.value))!
        var cstring = param.paramId.cStringUsingEncoding(NSASCIIStringEncoding)!
        mavlink_msg_param_set_pack(mySystemId, myComponentId, &msg, systemId, componentId, &cstring, value, UInt8(param.type.rawValue))
        _ = ParamGetSetMessageHandler(self, msg: msg, paramIndex: -1, paramId: param.paramId) { success in
            dispatch_async(dispatch_get_main_queue(), {
                callback?(success: success)
            })
        }
    }
    
    // This doesn't seem to be supported on APM and is not necessary anyway
    func writeParamsToEeprom(callback: ((success: Bool) -> Void)?) {
        var msg = mavlink_message_t()
        mavlink_msg_command_long_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt16(MAV_CMD_PREFLIGHT_STORAGE.rawValue), 0, 1, 0, 0, 0, 0, 0, 0)
        _ = CommandMessageHandler(self, msg: msg) { success in
            dispatch_async(dispatch_get_main_queue()) {
                callback?(success: success)
            }
        }
    }
}
