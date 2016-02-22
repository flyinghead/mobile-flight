//
//  MAVLink.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 20/02/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//
import Foundation

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
                let sensorData = SensorData.theSensorData
                // Message received
                switch Int32(msg.msgid) {
                case MAVLINK_MSG_ID_ATTITUDE:
                    sensorData.rollAngle = Double(mavlink_msg_attitude_get_roll(&msg)) * 180 / M_PI
                    sensorData.pitchAngle = -Double(mavlink_msg_attitude_get_pitch(&msg)) * 180 / M_PI
                    sensorData.heading = Double(mavlink_msg_attitude_get_yaw(&msg)) * 180 / M_PI
                    sensorData.turnRate = Double(mavlink_msg_attitude_get_yawspeed(&msg)) * 180 / M_PI
                    //pingSensorListeners()
                    
                case MAVLINK_MSG_ID_HEARTBEAT:
                    let autopilot = MAV_AUTOPILOT(UInt32(mavlink_msg_heartbeat_get_autopilot(&msg)))
                    let baseMode = MAV_MODE_FLAG(UInt32(mavlink_msg_heartbeat_get_base_mode(&msg)))
                    let customMode = mavlink_msg_heartbeat_get_custom_mode(&msg)
                    let systemStatus = MAV_STATE(UInt32(mavlink_msg_heartbeat_get_system_status(&msg)))
                    let type = MAV_TYPE(UInt32(mavlink_msg_heartbeat_get_type(&msg)))
                    NSLog("Heartbeat status=%d", systemStatus.rawValue)
                    
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