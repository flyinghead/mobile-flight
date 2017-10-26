//
//  PortConfig.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 12/06/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

struct PortFunction : OptionSet, DictionaryCoding {
    let rawValue: Int
    
    static let None = PortFunction(rawValue: 0)
    static let MSP  = PortFunction(rawValue: 1 << 0)
    static let GPS = PortFunction(rawValue: 1 << 1)
    static let TelemetryFrsky  = PortFunction(rawValue: 1 << 2)
    static let TelemetryHott  = PortFunction(rawValue: 1 << 3)
    static let TelemetryLTM  = PortFunction(rawValue: 1 << 4)           // MSP telemetry for CF < 1.11, LTM telemetry for CF >= 1.11
    static let TelemetrySmartPort  = PortFunction(rawValue: 1 << 5)
    static let RxSerial  = PortFunction(rawValue: 1 << 6)
    static let Blackbox  = PortFunction(rawValue: 1 << 7)
    static let TelemetryMAVLinkOld  = PortFunction(rawValue: 1 << 8)
    static let TelemetryMAVLink  = PortFunction(rawValue: 1 << 9)
    static let MSPClient  = PortFunction(rawValue: 1 << 9)
    static let ESCSensor = PortFunction(rawValue: 1 << 10)
    static let VTXSmartAudio = PortFunction(rawValue: 1 << 11)
    static let TelemetryIBus  = PortFunction(rawValue: 1 << 12)
    static let VTXTramp  = PortFunction(rawValue: 1 << 13)
    static let RuncamSplit = PortFunction(rawValue: 1 << 14)            // BF 3.2

    static let TelemetryIBusINAV  = PortFunction(rawValue: 1 << 9)
    static let RuncamSplitINAV = PortFunction(rawValue: 1 << 10)        // iNav 1.7.3

    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    // MARK: DictionaryCoding
    func toDict() -> NSDictionary {
        return ["rawValue": rawValue]
    }
    
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let rawValue = dict["rawValue"] as? Int
            else { return nil }
        self.rawValue = rawValue
    }
}

enum PortIdentifier {
    enum Internal : Int {
        case none = -1
        case usart1 = 0
        case usart2 = 1
        case usart3 = 2
        case usart4 = 3
        case usb_VCP = 20
        case softSerial1 = 30
        case softSerial2 = 31
    }
    case known(Internal)
    case unknown(Int)
    
    init(value: Int) {
        if let intern = Internal(rawValue: value) {
            self = .known(intern)
        } else {
            self = .unknown(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .known(let intern):
            return intern.rawValue
        case .unknown(let value):
            return value
        }
    }
    
    var name: String {
        switch self {
        case .known(let intern):
            switch intern {
            case .none:
                return "None"
            case .usart1:
                return "UART1"
            case .usart2:
                return "UART2"
            case .usart3:
                return "UART3"
            case .usart4:
                return "UART4"
            case .usb_VCP:
                return "USB"
            case .softSerial1:
                return "SOFTSERIAL1"
            case .softSerial2:
                return "SOFTSERIAL2"
            }
        case .unknown(let value):
            return String(format: "PORT %d", value)
        }
    }
}

enum BaudRate : Equatable {
    case auto
    case baud1200
    case baud2400
    case baud4800
    case baud9600
    case baud19200
    case baud38400
    case baud57600
    case baud115200
    case baud230400
    case baud250000
    case baud400000
    case baud460800
    case baud500000
    case baud921600
    case baud1000000
    case baud1500000
    case baud2000000
    case baud2470000
    case unknown(value: Int)
    
    init(value: Int) {
        let values = BaudRate.values()
        if value >= 0 && value < values.count {
            self = values[value]
        } else {
            self = .unknown(value: value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .unknown(let value):
            return value
        default:
            let values = BaudRate.values()
            return values.index(of: self) ?? 0
        }
    }
    
    var description: String {
        switch self {
        case .auto:
            return "Auto"
        case .baud1200:
            return "1200"
        case .baud2400:
            return "2400"
        case .baud4800:
            return "4800"
        case .baud9600:
            return "9600"
        case .baud19200:
            return "19200"
        case .baud38400:
            return "38400"
        case .baud57600:
            return "57600"
        case .baud115200:
            return "115200"
        case .baud230400:
            return "230400"
        case .baud250000:
            return "250000"
        case .baud400000:
            return "400000"
        case .baud460800:
            return "460800"
        case .baud500000:
            return "500000"
        case .baud921600:
            return "921600"
        case .baud1000000:
            return "1000000"
        case .baud1500000:
            return "1500000"
        case .baud2000000:
            return "2000000"
        case .baud2470000:
            return "2470000"
        case .unknown(let value):
            return String(format: "Unknown (%d)", value)
        }
    }
    
    static let inav17Values = [auto, baud1200, baud2400, baud4800, baud9600, baud19200, baud38400, baud57600, baud115200, baud230400, baud250000, baud460800, baud921600]
    static let bfValues = [auto, baud9600, baud19200, baud38400, baud57600, baud115200, baud230400, baud250000, baud400000, baud460800, baud500000, baud921600, baud1000000, baud1500000, baud2000000, baud2470000]
    static let defaultValues =  [auto, baud9600, baud19200, baud38400, baud57600, baud115200, baud230400, baud250000]
    
    static func values() -> [BaudRate] {
        let config = Configuration.theConfig
        if config.isINav && config.isApiVersionAtLeast("1.25") {    // INav 1.7
            return inav17Values
        }
        else if !config.isINav && config.isApiVersionAtLeast("1.31") {    // BF3.1, CF2
            return bfValues
        }
        else {
            return defaultValues
        }
    }
}

func ==(lhs: BaudRate, rhs: BaudRate) -> Bool {
    return lhs.description == rhs.description
}

struct PortConfig : DictionaryCoding {
    var portIdentifier = PortIdentifier.known(.none)
    var functions = PortFunction.None
    var mspBaudRate = BaudRate.auto
    var gpsBaudRate = BaudRate.auto
    var telemetryBaudRate = BaudRate.auto
    var blackboxBaudRate = BaudRate.auto
    
    init(portIdentifier: PortIdentifier, functions: PortFunction, mspBaudRate: BaudRate, gpsBaudRate: BaudRate, telemetryBaudRate: BaudRate, blackboxBaudRate: BaudRate) {
        self.portIdentifier = portIdentifier
        self.functions = functions
        self.mspBaudRate = mspBaudRate
        self.gpsBaudRate = gpsBaudRate
        self.telemetryBaudRate = telemetryBaudRate
        self.blackboxBaudRate = blackboxBaudRate
    }
    
    // MARK: DictionaryCoding
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let portIdentifier = dict["portIdentifier"] as? Int,
            let functions = dict["functions"] as? Int,
            let mspBaudRate = dict["mspBaudRate"] as? Int,
            let gpsBaudRate = dict["gpsBaudRate"] as? Int,
            let telemetryBaudRate = dict["telemetryBaudRate"] as? Int,
            let blackboxBaudRate = dict["blackboxBaudRate"] as? Int
            else { return nil }
        
        self.init(portIdentifier: PortIdentifier(value: portIdentifier), functions: PortFunction(rawValue: functions), mspBaudRate: BaudRate(value: mspBaudRate), gpsBaudRate: BaudRate(value: gpsBaudRate), telemetryBaudRate: BaudRate(value: telemetryBaudRate), blackboxBaudRate: BaudRate(value: blackboxBaudRate))
    }
    
    func toDict() -> NSDictionary {
        return [ "portIdentifier": portIdentifier.intValue, "functions": functions.rawValue, "mspBaudRate": mspBaudRate.intValue, "gpsBaudRate": gpsBaudRate.intValue, "telemetryBaudRate": telemetryBaudRate.intValue, "blackboxBaudRate": blackboxBaudRate.intValue ]
    }
}
