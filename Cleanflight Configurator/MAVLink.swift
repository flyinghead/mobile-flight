//
//  MAVLink.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 20/02/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//
import Foundation
import UIKit

enum ArduCopterFlightMode : Int {
    case STABILIZE = 0
    case ACRO = 1
    case ALT_HOLD = 2
    case AUTO = 3
    case GUIDED = 4
    case LOITER = 5
    case RTL = 6
    case CIRCLE = 7
    case LAND = 9
    case DRIFT = 11
    case SPORT = 13
    case FLIP = 14
    case AUTOTUNE = 15
    case POSHOLD = 16
    case BRAKE = 17
    case THROW = 18
    case UNKNOWN = 999
}

class MAVLink : ProtocolHandler {
    private let mySystemId = UInt8(144)
    private let myComponentId = UInt8(MAV_COMP_ID_SYSTEM_CONTROL.rawValue)
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
    
    private var flightMode = ArduCopterFlightMode.UNKNOWN
    private var failsafeBatteryVoltage: Double?
    
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
    
    var vehicle = Vehicle()
    
    func read(data: [UInt8]) {
        lastDataReceived = NSDate()
        vehicle.noDataReceived.value = false
        
        var msg = mavlink_message_t()
        var status = mavlink_status_t()
        
        for c in data {
            if mavlink_parse_char(0, c, &msg, &status) == 1 {
                protocolRecognized = true
                //let sensorData = SensorData.theSensorData
                

                // Message received
                let msgId = Int32(msg.msgid)
                if msgId != MAVLINK_MSG_ID_HEARTBEAT {
                    lastReveivedMessageIsHeartbeat = false
                }
                //NSLog("Received MAVLink msg %d", msg.msgid)

                switch msgId {
                case MAVLINK_MSG_ID_ATTITUDE:
                    vehicle.rollAngle.value = Double(mavlink_msg_attitude_get_roll(&msg)) * 180 / M_PI
                    vehicle.pitchAngle.value = -Double(mavlink_msg_attitude_get_pitch(&msg)) * 180 / M_PI
                    //vehicle.heading.value = Double(mavlink_msg_attitude_get_yaw(&msg)) * 180 / M_PI
                    vehicle.turnRate.value = Double(mavlink_msg_attitude_get_yawspeed(&msg)) * 180 / M_PI
                    //pingSensorListeners()
                    
                case MAVLINK_MSG_ID_HEARTBEAT:      // Sent every second
                    systemId = msg.sysid
                    componentId = msg.compid
                    if lastReveivedMessageIsHeartbeat && !replaying {
                        // Not receiving other messages. Re-send our data streams request
                        requestMAVLinkRates()
                    }
                    lastReveivedMessageIsHeartbeat = true
                    let autopilot = MAV_AUTOPILOT(UInt32(mavlink_msg_heartbeat_get_autopilot(&msg)))
                    let baseMode = MAV_MODE_FLAG(UInt32(mavlink_msg_heartbeat_get_base_mode(&msg)))
                    let wasArmed = vehicle.armed.value
                    vehicle.armed.value = baseMode.rawValue & MAV_MODE_FLAG_SAFETY_ARMED.rawValue != 0
                    if !wasArmed && vehicle.armed.value {
                        // Refresh home position when arming
                        requestHomePosition()
                    }
                    
                    flightMode = ArduCopterFlightMode(rawValue: Int(mavlink_msg_heartbeat_get_custom_mode(&msg))) ?? .UNKNOWN
                    let systemStatus = MAV_STATE(UInt32(mavlink_msg_heartbeat_get_system_status(&msg)))
                    let type = MAV_TYPE(UInt32(mavlink_msg_heartbeat_get_type(&msg)))
                    NSLog("Heartbeat status=%d mode=%d", systemStatus.rawValue, flightMode.rawValue)
                    
                case MAVLINK_MSG_ID_GLOBAL_POSITION_INT:
                    vehicle.position.value = Position(latitude: Double(mavlink_msg_global_position_int_get_lat(&msg)) * 10000000, longitude: Double(mavlink_msg_global_position_int_get_lon(&msg)) * 10000000)
                    vehicle.altitude.value = Double(mavlink_msg_global_position_int_get_relative_alt(&msg)) / 1000
                    vehicle.heading.value = Double(mavlink_msg_global_position_int_get_hdg(&msg)) / 100
                    let vz = Double(mavlink_msg_global_position_int_get_vz(&msg)) / 100
                    let vx = Double(mavlink_msg_global_position_int_get_vx(&msg)) / 100
                    let vy = Double(mavlink_msg_global_position_int_get_vy(&msg)) / 100
                    vehicle.verticalSpeed.value = vz
                    vehicle.speed.value = sqrt(vx * vx + vy * vy + vz * vz) / 1000 * 3600
                    
                    if (vehicle.position.value!.latitude != 0 || vehicle.position.value!.longitude != 0) {
                        if vehicle.homePosition.value == nil {
                            //executeCommand(410)     // GET_HOME_POSITION. Not supported on Copter 3.3
                            requestHomePosition()
                        }  else {
                            vehicle.distanceToHome.value = getDistance(vehicle.homePosition.value!.position2d, vehicle.position.value!)
                        }
                    }
                    
                case MAVLINK_MSG_ID_SYS_STATUS:
                    vehicle.batteryVolts.value = Double(mavlink_msg_sys_status_get_voltage_battery(&msg)) / 1000
                    vehicle.batteryAmps.value = Double(mavlink_msg_sys_status_get_current_battery(&msg)) / 100
                    // TODO battery remaining % (?)
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
                    // Current waypoint #
                    break
                    
                case MAVLINK_MSG_ID_MISSION_ITEM:
                    let seq = mavlink_msg_mission_item_get_seq(&msg)
                    if seq == 0 {   // Home position
                        let latitude = mavlink_msg_mission_item_get_x(&msg)
                        let longitude = mavlink_msg_mission_item_get_y(&msg)
                        let altitude = mavlink_msg_mission_item_get_z(&msg)
                        vehicle.homePosition.value = Position3D(position2d: Position(latitude: Double(latitude), longitude: Double(longitude)), altitude: Double(altitude))
                    }
                    
                case MAVLINK_MSG_ID_STATUSTEXT:
                    var charBytes = [Int8](count: 50, repeatedValue: 0)
                    mavlink_msg_statustext_get_text(&msg, &charBytes)
                    let messageText = NSString(bytes: charBytes, length: charBytes.count, encoding: NSASCIIStringEncoding)!
                    let severity = MAV_SEVERITY(UInt32(mavlink_msg_statustext_get_severity(&msg)))
                    NSLog("MESSAGE %d - %@", severity.rawValue, messageText)
                    VoiceMessage.speak(messageText as String)
                
                case MAVLINK_MSG_ID_PARAM_VALUE:
                    var charBytes = [Int8](count: 16, repeatedValue: 0)
                    mavlink_msg_param_value_get_param_id(&msg, &charBytes)
                    let paramId = NSString(CString: charBytes, encoding: NSASCIIStringEncoding)! as String
                    let paramType = MAV_PARAM_TYPE(rawValue: UInt32(mavlink_msg_param_value_get_param_type(&msg)))
                    switch paramType {
                    case MAV_PARAM_TYPE_REAL32:
                        let floatValue = mavlink_msg_param_value_get_param_value(&msg)
                        paramReceived(paramId, value: NSNumber(float: floatValue))
                    default:
                        NSLog("Unhandled type %d", paramType.rawValue)
                    }
                case MAVLINK_MSG_ID_RC_CHANNELS_RAW:
                    let rawRssi = mavlink_msg_rc_channels_raw_get_rssi(&msg)
                    if rawRssi == 255 {
                        vehicle.rssi.value = nil
                    } else {
                        vehicle.rssi.value = Int(rawRssi)
                    }
                    var rcChannels = [
                        Int(mavlink_msg_rc_channels_raw_get_chan1_raw(&msg)), 3000 - Int(mavlink_msg_rc_channels_raw_get_chan2_raw(&msg)), Int(mavlink_msg_rc_channels_raw_get_chan3_raw(&msg)), Int(mavlink_msg_rc_channels_raw_get_chan4_raw(&msg)), Int(mavlink_msg_rc_channels_raw_get_chan5_raw(&msg)), Int(mavlink_msg_rc_channels_raw_get_chan6_raw(&msg)), Int(mavlink_msg_rc_channels_raw_get_chan7_raw(&msg)), Int(mavlink_msg_rc_channels_raw_get_chan8_raw(&msg)) ]
                    while rcChannels.last == 65535 {
                        rcChannels.popLast()
                    }
                    for var i = 0; i < rcChannels.count; i++ {
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
                    
                default:
                    NSLog("Unknown MAVLink msg %d", msg.msgid)
                }
            }
        }
        if protocolRecognized && failsafeBatteryVoltage == nil {
            requestParam("FS_BATT_VOLTAGE")
        }
    }
    
    private func requestMAVLinkRates() {
        var msg = mavlink_message_t()
        //mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_RAW_SENSORS.rawValue), 2, 1)         // 2Hz: RAW_IMU, SCALED_PRESSURE, (Enable IMU_RAW, GPS_RAW, GPS_STATUS packets)
        //sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTENDED_STATUS.rawValue), 2, 1)     // SYS_STATUS, GPS_RAW_INT, MISSION_CURRENT, NAV_CONTROLLER_OUTPUT (Enable GPS_STATUS, CONTROL_STATUS, AUX_STATUS)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_RC_CHANNELS.rawValue), 5, 1)         // 5Hz: RC_CHANNELS_RAW, SERVO_OUTPUT_RAW (Enable RC_CHANNELS_SCALED, RC_CHANNELS_RAW, SERVO_OUTPUT_RAW)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_POSITION.rawValue), 2, 1)            // GLOBAL_POSITION_INT (Enable LOCAL_POSITION, GLOBAL_POSITION/GLOBAL_POSITION_INT messages)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTRA1.rawValue), 5, 1)              // ATTITUDE
        sendMAVLinkMsg(msg)
        //mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTRA2.rawValue), 2, 1)              // VFR_HUD
        //sendMAVLinkMsg(msg)
    }
    
    private func cancelMAVLinkRates() {
        var msg = mavlink_message_t()
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_RAW_SENSORS.rawValue), 0, 0)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTENDED_STATUS.rawValue), 0, 0)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_RC_CHANNELS.rawValue), 0, 0)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_POSITION.rawValue), 0, 0)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTRA1.rawValue), 0, 0)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTRA2.rawValue), 0, 0)
        sendMAVLinkMsg(msg)
    }

    private func sendMAVLinkMsg(var msg: mavlink_message_t) {
        var buf = [UInt8](count: 128, repeatedValue: 0)  // Max size?
        let len = mavlink_msg_to_send_buffer(&buf, &msg)
        outputBuffer.appendContentsOf(buf.prefix(Int(len)))
        commChannel?.flushOut()
    }
    
    func addDataListener(listener: FlightDataListener) {
        
    }
    func removeDataListener(listener: FlightDataListener) {
        
    }
    
    func sendRawRc(values: [Int]) {
        
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
            heartbeatTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "heartbeatTimer:", userInfo: nil, repeats: true)
            dataReceivedTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "dataReceivedTimer:", userInfo: nil, repeats: true)
        }
        vehicle.replaying.value = commChannel is ReplayComm
        vehicle.connected.value = true
        vehicle.rcOutEnabled.value = true       // Can send RC_OVERRIDE
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
            var msg = mavlink_message_t()
            mavlink_msg_heartbeat_pack(mySystemId, myComponentId, &msg, UInt8(MAV_TYPE_GCS.rawValue), UInt8(MAV_AUTOPILOT_INVALID.rawValue), 0, 0, 0)
            sendMAVLinkMsg(msg)
        }
    }
    
    @objc
    private func dataReceivedTimer(timer: NSTimer) {
        if lastDataReceived != nil && -lastDataReceived!.timeIntervalSinceNow > 0.75 && communicationHealthy {
            // Set warning if no data received for 0.75 sec
            vehicle.noDataReceived.value = true
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
        objc_sync_enter(self)
        var tmpOut: [UInt8]? = outputBuffer
        if tmpOut!.isEmpty {
            tmpOut = nil
        } else {
            outputBuffer.removeAll()
        }
        objc_sync_exit(self)

        return tmpOut;
    }

    private func altitudeHoldActive() -> Bool {
        return flightMode != .STABILIZE && flightMode != .DRIFT && flightMode != .ACRO && flightMode != .FLIP && flightMode != .UNKNOWN  && flightMode != .THROW
    }
    
    private func navigationActive() -> Bool {
        return flightMode == .AUTO || flightMode == .GUIDED || flightMode == .LOITER || flightMode == .RTL || flightMode == .CIRCLE || flightMode == .POSHOLD
    }
    
    private func requestParam(param: String) {
        var msg = mavlink_message_t()
        let nsparam = param as NSString
        mavlink_msg_param_request_read_pack(mySystemId, myComponentId, &msg, systemId, componentId, nsparam.cStringUsingEncoding(NSASCIIStringEncoding), -1)
        sendMAVLinkMsg(msg)
    }
    
    private func paramReceived(paramId: String, value: NSNumber) {
        switch paramId {
            case "FS_BATT_VOLTAGE":
            failsafeBatteryVoltage = value.doubleValue
            vehicle.batteryVoltsWarning.value = failsafeBatteryVoltage! * 1.03
            vehicle.batteryVoltsCritical.value = failsafeBatteryVoltage
            
        default:
            NSLog("Unrequested parameter: %@=%@", paramId, value)
        }
    }
    
    func executeCommand(command: UInt32) {
        var msg = mavlink_message_t()
        mavlink_msg_command_long_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt16(command), 0, 0, 0, 0, 0, 0, 0, 0)
        sendMAVLinkMsg(msg)
    }
    
    func requestHomePosition() {
        var msg = mavlink_message_t()
        // Waypoint #0 is Home/Launch location
        mavlink_msg_mission_request_pack(mySystemId, myComponentId, &msg, systemId, componentId, 0)
        sendMAVLinkMsg(msg)
    }
}