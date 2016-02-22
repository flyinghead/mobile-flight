//
//  ProtocolHandler.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 21/02/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

protocol ProtocolHandler  : class {
    func read(data: [UInt8])
    
    func addDataListener(listener: FlightDataListener)
    func removeDataListener(listener: FlightDataListener)
    
    func sendRawRc(values: [Int])
    
    func openCommChannel(commChannel: CommChannel)
    func closeCommChannel()
    
    var communicationEstablished: Bool { get }
    var communicationHealthy: Bool { get }
    var replaying: Bool { get }
    func nextOutputMessage() -> [UInt8]?

}