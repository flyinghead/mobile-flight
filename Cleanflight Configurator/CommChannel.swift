//
//  CommChannel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 03/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

protocol CommChannel {
    func flushOut()
    func close()
}