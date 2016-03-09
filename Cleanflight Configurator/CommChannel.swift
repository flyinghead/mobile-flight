//
//  CommChannel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 03/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

protocol CommChannel {
    var protocolHandler: ProtocolHandler? { get set }
    func flushOut()
    func close()
    var connected: Bool { get }
}