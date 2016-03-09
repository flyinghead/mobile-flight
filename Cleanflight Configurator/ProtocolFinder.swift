//
//  ProtocolFinder.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 08/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class ProtocolFinder : ProtocolHandler {
    var datalog: NSFileHandle?
    var callback: ((ProtocolHandler) -> Void)?
    
    private var mspProtocolHandler = MSPParser()
    private var mavlinkProtocolHandler = MAVLink()
    private var commChannel: CommChannel!
    
    func read(data: [UInt8]) {
        mspProtocolHandler.read(data)
        if mspProtocolHandler.protocolRecognized {
            mavlinkProtocolHandler.detachCommChannel()
            setupHandlerAndCallback(mspProtocolHandler)
        }
        mavlinkProtocolHandler.read(data)
        if mavlinkProtocolHandler.protocolRecognized {
            mspProtocolHandler.detachCommChannel()
            setupHandlerAndCallback(mavlinkProtocolHandler)
        }
    }
    
    func setupHandlerAndCallback(protocolHandler: ProtocolHandler) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        commChannel.protocolHandler = protocolHandler
        protocolHandler.openCommChannel(commChannel)
        appDelegate.protocolHandler = protocolHandler
        appDelegate.vehicle = protocolHandler.vehicle
        callback?(protocolHandler)
    }
    
    func nextOutputMessage() -> [UInt8]? {
        var msg = mspProtocolHandler.nextOutputMessage()
        if msg != nil {
            return msg
        }
        msg = mavlinkProtocolHandler.nextOutputMessage()
        return msg
    }
    
    func recognizeProtocol(commChannel: CommChannel) {
        self.commChannel = commChannel
        mspProtocolHandler.recognizeProtocol(commChannel)
        mavlinkProtocolHandler.recognizeProtocol(commChannel)
    }
    
    func detachCommChannel() {
        mspProtocolHandler.detachCommChannel()
        mavlinkProtocolHandler.detachCommChannel()
    }
    
    func addDataListener(listener: FlightDataListener) {}
    func removeDataListener(listener: FlightDataListener) {}
    
    func sendRawRc(values: [Int]) {}
    
    func openCommChannel(commChannel: CommChannel) {}
    func closeCommChannel() {}
    
    var communicationEstablished: Bool { return false }
    var communicationHealthy: Bool { return true }
    var replaying: Bool { return false }
    
    var vehicle: Vehicle {
        return Vehicle()
    }
    
    var protocolRecognized: Bool {
        return mspProtocolHandler.protocolRecognized || mavlinkProtocolHandler.protocolRecognized
    }
}