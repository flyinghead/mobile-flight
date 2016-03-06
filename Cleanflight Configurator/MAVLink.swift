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
    let mySystemId = UInt8(144)
    let myComponentId = UInt8(MAV_COMP_ID_SYSTEM_CONTROL.rawValue)
    // Target system
    var systemId: UInt8 = 1
    let componentId = UInt8(1)
    
    var outputBuffer = [UInt8]()
    var commChannel: CommChannel!
    
    func read(data: [UInt8]) {
        var msg = mavlink_message_t()
        var status = mavlink_status_t()
        
        for c in data {
            if mavlink_parse_char(0, c, &msg, &status) == 1 {
                //let sensorData = SensorData.theSensorData
                let vehicle = (UIApplication.sharedApplication().delegate as! AppDelegate).vehicle

                // Message received
                switch Int32(msg.msgid) {
                case MAVLINK_MSG_ID_ATTITUDE:
                    vehicle.rollAngle.value = Double(mavlink_msg_attitude_get_roll(&msg)) * 180 / M_PI
                    vehicle.pitchAngle.value = -Double(mavlink_msg_attitude_get_pitch(&msg)) * 180 / M_PI
                    //vehicle.heading.value = Double(mavlink_msg_attitude_get_yaw(&msg)) * 180 / M_PI
                    vehicle.turnRate.value = Double(mavlink_msg_attitude_get_yawspeed(&msg)) * 180 / M_PI
                    //pingSensorListeners()
                    
                case MAVLINK_MSG_ID_HEARTBEAT:
                    let autopilot = MAV_AUTOPILOT(UInt32(mavlink_msg_heartbeat_get_autopilot(&msg)))
                    let baseMode = MAV_MODE_FLAG(UInt32(mavlink_msg_heartbeat_get_base_mode(&msg)))
                    vehicle.armed.value = baseMode.rawValue & MAV_MODE_FLAG_SAFETY_ARMED.rawValue != 0
                    let customMode = mavlink_msg_heartbeat_get_custom_mode(&msg)
                    let systemStatus = MAV_STATE(UInt32(mavlink_msg_heartbeat_get_system_status(&msg)))
                    let type = MAV_TYPE(UInt32(mavlink_msg_heartbeat_get_type(&msg)))
                    NSLog("Heartbeat status=%d", systemStatus.rawValue)
                    
                case MAVLINK_MSG_ID_GLOBAL_POSITION_INT:
                    vehicle.altitude.value = Double(mavlink_msg_global_position_int_get_relative_alt(&msg)) / 1000
                    vehicle.heading.value = Double(mavlink_msg_global_position_int_get_hdg(&msg)) / 100
                    let vz = Double(mavlink_msg_global_position_int_get_vz(&msg)) / 100
                    let vx = Double(mavlink_msg_global_position_int_get_vx(&msg)) / 100
                    let vy = Double(mavlink_msg_global_position_int_get_vy(&msg)) / 100
                    vehicle.verticalSpeed.value = vz
                    vehicle.speed.value = sqrt(vx * vx + vy * vy + vz * vz) / 1000 * 3600
                    
                case MAVLINK_MSG_ID_SYS_STATUS:
                    vehicle.batteryVolts.value = Double(mavlink_msg_sys_status_get_voltage_battery(&msg)) / 1000
                    vehicle.batteryAmps.value = Double(mavlink_msg_sys_status_get_current_battery(&msg)) / 100
                    // TODO battery remaining % (?)
                    // TODO sensors
                    
                case MAVLINK_MSG_ID_GPS_RAW_INT:
                    vehicle.gpsFix.value = mavlink_msg_gps_raw_int_get_fix_type(&msg) == 3
                    vehicle.gpsNumSats.value = Int(mavlink_msg_gps_raw_int_get_satellites_visible(&msg))
                    
                default:
                    NSLog("Unknown MAVLink msg %d", msg.msgid)
                }
            }
        }
    }
    
    func requestMAVLinkRates() {
        var msg = mavlink_message_t()
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_RAW_SENSORS.rawValue), 2, 1)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTENDED_STATUS.rawValue), 2, 1)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_RC_CHANNELS.rawValue), 5, 1)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_POSITION.rawValue), 2, 1)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTRA1.rawValue), 5, 1)
        sendMAVLinkMsg(msg)
        mavlink_msg_request_data_stream_pack(mySystemId, myComponentId, &msg, systemId, componentId, UInt8(MAV_DATA_STREAM_EXTRA2.rawValue), 2, 1)
        sendMAVLinkMsg(msg)
    }
    
    private func sendMAVLinkMsg(var msg: mavlink_message_t) {
        var buf = [UInt8](count: 128, repeatedValue: 0)  // Max size?
        let len = mavlink_msg_to_send_buffer(&buf, &msg)
        outputBuffer.appendContentsOf(buf.prefix(Int(len)))
        commChannel.flushOut()
    }
    
    func addDataListener(listener: FlightDataListener) {
        
    }
    func removeDataListener(listener: FlightDataListener) {
        
    }
    
    func sendRawRc(values: [Int]) {
        
    }
    
    func openCommChannel(commChannel: CommChannel) {
        self.commChannel = commChannel
    }
    func closeCommChannel() {
        commChannel.close()
        commChannel = nil
    }
    
    var communicationEstablished: Bool {
        return commChannel != nil
    }
    var communicationHealthy: Bool {
        return communicationEstablished && commChannel.connected
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

}