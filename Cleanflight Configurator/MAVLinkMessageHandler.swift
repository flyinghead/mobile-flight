//
//  MAVLinkMessageHandler.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 16/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class MAVLinkMessageHandler : AnyObject {
    let mavlink: MAVLink
    var message: mavlink_message_t          // Can't take the address of a let constant?
    let expectedReply: Int32
    let callback: ((success: Bool) -> Void)?
    let maxTries = 5
    
    var timer: NSTimer!
    var failures = 0
    
    init(_ mavlink: MAVLink, msg: mavlink_message_t, expectedReply: Int32, callback: ((success: Bool) -> Void)? = nil) {
        self.mavlink = mavlink
        self.message = msg
        self.expectedReply = expectedReply
        self.callback = callback
        mavlink.addMessageHandler(expectedReply, handler: self)
        sendMessage()
    }
    
    private func sendMessage() {
        timer?.invalidate()
        timer = NSTimer(timeInterval: 0.5, target: self, selector: "receiveTimeOut:", userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
        mavlink.sendMAVLinkMsg(message)
    }
    
    @objc
    private func receiveTimeOut(timer: NSTimer) {
        if ++failures >= maxTries {
            NSLog("Message %d FAILED", expectedReply)
            finish(false)
        } else {
            NSLog("Message %d Retrying", expectedReply)
            sendMessage()
        }
    }
    
    func finish(status: Bool) {
        timer?.invalidate()
        mavlink.removeMessageHandler(expectedReply, handler: self)
        callback?(success: status)
    }
    
    func match(msg: mavlink_message_t) -> Bool {
        success()
        return true
    }
    
    func success() {
        finish(true)
    }
}

class ParamGetSetMessageHandler : MAVLinkMessageHandler {
    let paramIndex: Int
    let paramId: String?
    
    init(_ mavlink: MAVLink, msg: mavlink_message_t, paramIndex: Int, paramId: String?, callback: ((success: Bool) -> Void)? = nil) {
        self.paramIndex = paramIndex
        self.paramId = paramId
        super.init(mavlink, msg: msg, expectedReply: MAVLINK_MSG_ID_PARAM_VALUE, callback: callback)
    }

    override func match(msg: mavlink_message_t) -> Bool {
        let param = mavlink.parseParamValueMessage(msg)
        if paramIndex != 65535 && paramIndex == param.index {
            success()
            return true
        }
        
        if paramId == param.paramId {
            success()
            return true
        }
    
        return false
    }
}

class CommandMessageHandler : MAVLinkMessageHandler {
    init(_ mavlink: MAVLink, msg: mavlink_message_t, callback: ((success: Bool) -> Void)? = nil) {
        super.init(mavlink, msg: msg, expectedReply: MAVLINK_MSG_ID_COMMAND_ACK, callback: callback)
    }

    override func match(var msg: mavlink_message_t) -> Bool {
        if mavlink_msg_command_ack_get_command(&msg) == mavlink_msg_command_ack_get_command(&self.message) {
            finish(mavlink_msg_command_ack_get_result(&msg) == 0)
            
            return true
        }
        
        return false
    }
}
