//
//  CommChannel.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 03/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

protocol CommChannel {
    func flushOut()
    func close()
    var connected: Bool { get }
}
