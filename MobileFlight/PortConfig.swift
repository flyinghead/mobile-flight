//
//  PortConfig.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 12/06/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

struct PortFunction : OptionSetType, DictionaryCoding {
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
        case None = -1
        case USART1 = 0
        case USART2 = 1
        case USART3 = 2
        case USART4 = 3
        case USB_VCP = 20
        case SoftSerial1 = 30
        case SoftSerial2 = 31
    }
    case Known(Internal)
    case Unknown(Int)
    
    init(value: Int) {
        if let intern = Internal(rawValue: value) {
            self = .Known(intern)
        } else {
            self = .Unknown(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .Known(let intern):
            return intern.rawValue
        case .Unknown(let value):
            return value
        }
    }
    
    var name: String {
        switch self {
        case .Known(let intern):
            switch intern {
            case .None:
                return "None"
            case .USART1:
                return "UART1"
            case .USART2:
                return "UART2"
            case .USART3:
                return "UART3"
            case .USART4:
                return "UART4"
            case .USB_VCP:
                return "USB"
            case .SoftSerial1:
                return "SOFTSERIAL1"
            case .SoftSerial2:
                return "SOFTSERIAL2"
            }
        case .Unknown(let value):
            return String(format: "PORT %d", value)
        }
    }
}

enum BaudRate : Equatable {
    case Auto
    case Baud1200
    case Baud2400
    case Baud4800
    case Baud9600
    case Baud19200
    case Baud38400
    case Baud57600
    case Baud115200
    case Baud230400
    case Baud250000
    case Baud400000
    case Baud460800
    case Baud500000
    case Baud921600
    case Baud1000000
    case Baud1500000
    case Baud2000000
    case Baud2470000
    case Unknown(value: Int)
    
    init(value: Int) {
        let values = BaudRate.values()
        if value >= 0 && value < values.count {
            self = values[value]
        } else {
            self = .Unknown(value: value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .Unknown(let value):
            return value
        default:
            let values = BaudRate.values()
            return values.indexOf(self) ?? 0
        }
    }
    
    var description: String {
        switch self {
        case Auto:
            return "Auto"
        case Baud1200:
            return "1200"
        case Baud2400:
            return "2400"
        case Baud4800:
            return "4800"
        case Baud9600:
            return "9600"
        case Baud19200:
            return "19200"
        case Baud38400:
            return "38400"
        case Baud57600:
            return "57600"
        case Baud115200:
            return "115200"
        case Baud230400:
            return "230400"
        case Baud250000:
            return "250000"
        case Baud400000:
            return "400000"
        case Baud460800:
            return "460800"
        case Baud500000:
            return "500000"
        case Baud921600:
            return "921600"
        case Baud1000000:
            return "1000000"
        case Baud1500000:
            return "1500000"
        case Baud2000000:
            return "2000000"
        case Baud2470000:
            return "2470000"
        case Unknown(let value):
            return String(format: "Unknown (%d)", value)
        }
    }
    
    static let inav17Values = [Auto, Baud1200, Baud2400, Baud4800, Baud9600, Baud19200, Baud38400, Baud57600, Baud115200, Baud230400, Baud250000, Baud460800, Baud921600]
    static let bfValues = [Auto, Baud9600, Baud19200, Baud38400, Baud57600, Baud115200, Baud230400, Baud250000, Baud400000, Baud460800, Baud500000, Baud921600, Baud1000000, Baud1500000, Baud2000000, Baud2470000]
    static let defaultValues =  [Auto, Baud9600, Baud19200, Baud38400, Baud57600, Baud115200, Baud230400, Baud250000]
    
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
    var portIdentifier = PortIdentifier.Known(.None)
    var functions = PortFunction.None
    var mspBaudRate = BaudRate.Auto
    var gpsBaudRate = BaudRate.Auto
    var telemetryBaudRate = BaudRate.Auto
    var blackboxBaudRate = BaudRate.Auto
    
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
