//
//  PortConfigViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 14/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class PortConfigViewController: ConfigChildViewController {
    @IBOutlet weak var enableMSP: UISwitch!
    @IBOutlet weak var mspBaudrateField: UITextField!
    @IBOutlet weak var peripheralsTypeField: UITextField!
    @IBOutlet weak var blackboxBaudrateField: UITextField!
    @IBOutlet weak var telemetryTypeField: UITextField!
    @IBOutlet weak var telemetryBaudrateField: UITextField!
    @IBOutlet weak var enableRx: UISwitch!
    @IBOutlet weak var sensorTypeField: UITextField!
    @IBOutlet weak var gpsBaudrateField: UITextField!

    var mspBaudratePicker: MyDownPicker!
    var peripheralsTypePicker: MyDownPicker!
    var blackboxBaudratePicker: MyDownPicker!
    var telemetryTypePicker: MyDownPicker!
    var telemetryBaudratePicker: MyDownPicker!
    var sensorTypePicker: MyDownPicker!
    var gpsBaudratePicker: MyDownPicker!
    
    var portIndex: Int!
    var portsConfigViewController: PortsConfigViewController!

    var telemetryMAVLink: PortFunction!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        telemetryMAVLink = Configuration.theConfig.isApiVersionAtLeast("1.31") ? .TelemetryMAVLink : .TelemetryMAVLinkOld
        
        mspBaudratePicker = MyDownPicker(textField: mspBaudrateField, withData: [ "9600", "19200", "38400", "57600", "115200" ])
        mspBaudratePicker.setPlaceholder("")
        peripheralsTypePicker = MyDownPicker(textField: peripheralsTypeField, withData: [ "Disabled", "Blackbox", "TBS SmartAudio", "IRC Tramp" ])
        peripheralsTypePicker.setPlaceholder("")
        blackboxBaudratePicker = MyDownPicker(textField: blackboxBaudrateField, withData: [ "19200", "38400", "57600", "115200", "230400", "250000" ])
        blackboxBaudratePicker.setPlaceholder("")
        telemetryTypePicker = MyDownPicker(textField: telemetryTypeField, withData: [ "Disabled", "Frsky", "Hott", "LTM", "SmartPort", "MAVLink" ])
        telemetryTypePicker.setPlaceholder("")
        telemetryBaudratePicker = MyDownPicker(textField: telemetryBaudrateField, withData: [ "Auto", "9600", "19200", "38400", "57600", "115200" ])
        telemetryBaudratePicker.setPlaceholder("")
        sensorTypePicker = MyDownPicker(textField: sensorTypeField, withData: [ "Disabled", "GPS", "ESC" ])
        sensorTypePicker.setPlaceholder("")
        gpsBaudratePicker = MyDownPicker(textField: gpsBaudrateField, withData: [ "9600", "19200", "38400", "57600", "115200" ])
        gpsBaudratePicker.setPlaceholder("")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let port = settings.portConfigs![portIndex]
        
        enableMSP.on = port.functions.contains(.MSP)
        mspBaudratePicker.selectedIndex = port.mspBaudRate.rawValue - 1             // No auto
        
        if port.functions.contains(.Blackbox) {
            peripheralsTypePicker.selectedIndex = 1
        } else if port.functions.contains(.VTXSmartAudio) {
            peripheralsTypePicker.selectedIndex = 2
        } else if port.functions.contains(.VTXTramp) {
            peripheralsTypePicker.selectedIndex = 3
        } else {
            peripheralsTypePicker.selectedIndex = 0
        }
        blackboxBaudratePicker.selectedIndex = port.blackboxBaudRate.rawValue - 2   // No auto or 9600
        
        if port.functions.contains(.TelemetryFrsky) {
            telemetryTypePicker.selectedIndex = 1
        } else if port.functions.contains(.TelemetryHott) {
            telemetryTypePicker.selectedIndex = 2
        } else if port.functions.contains(.TelemetryLTM) {
            telemetryTypePicker.selectedIndex = 3
        } else if port.functions.contains(.TelemetrySmartPort) {
            telemetryTypePicker.selectedIndex = 4
        } else if port.functions.contains(telemetryMAVLink) {
            telemetryTypePicker.selectedIndex = 5
        } else {
            telemetryTypePicker.selectedIndex = 0
        }
        telemetryBaudratePicker.selectedIndex = port.telemetryBaudRate.rawValue
        
        enableRx.on = port.functions.contains(.RxSerial)
        
        if port.functions.contains(.GPS) {
            sensorTypePicker.selectedIndex = 1
        } else if port.functions.contains(.ESCSensor) {
            sensorTypePicker.selectedIndex = 2
        } else {
            sensorTypePicker.selectedIndex = 0
        }
        gpsBaudratePicker.selectedIndex = port.gpsBaudRate.rawValue - 1         // No auto
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        var port = settings.portConfigs![portIndex]
        
        if enableMSP.on {
            port.functions.insert(.MSP)
        } else {
            port.functions.remove(.MSP)
        }
        port.mspBaudRate = BaudRate(rawValue: mspBaudratePicker.selectedIndex + 1)!
        
        port.functions.remove(.Blackbox)
        port.functions.remove(.VTXSmartAudio)
        port.functions.remove(.VTXTramp)
        switch peripheralsTypePicker.selectedIndex {
        case 1:
            port.functions.insert(.Blackbox)
        case 2:
            port.functions.insert(.VTXSmartAudio)
        case 3:
            port.functions.insert(.VTXTramp)
        default:
            break
        }
        port.blackboxBaudRate = BaudRate(rawValue: blackboxBaudratePicker.selectedIndex + 2)!
        
        port.functions.remove(.TelemetryFrsky)
        port.functions.remove(.TelemetryHott)
        port.functions.remove(.TelemetryLTM)
        port.functions.remove(.TelemetrySmartPort)
        port.functions.remove(telemetryMAVLink)
        switch telemetryTypePicker.selectedIndex {
        case 1:
            port.functions.insert(.TelemetryFrsky)
        case 2:
            port.functions.insert(.TelemetryHott)
        case 3:
            port.functions.insert(.TelemetryLTM)
        case 4:
            port.functions.insert(.TelemetrySmartPort)
        case 5:
            port.functions.insert(telemetryMAVLink)
        default:
            break
        }
        port.telemetryBaudRate = BaudRate(rawValue: telemetryBaudratePicker.selectedIndex)!
        
        if enableRx.on {
            port.functions.insert(.RxSerial)
        } else {
            port.functions.remove(.RxSerial)
        }
        
        switch sensorTypePicker.selectedIndex {
        case 1:
            port.functions.insert(.GPS)
            port.functions.remove(.ESCSensor)
        case 2:
            port.functions.remove(.GPS)
            port.functions.insert(.ESCSensor)
        default:
            port.functions.remove(.GPS)
            port.functions.remove(.ESCSensor)
        }
        port.gpsBaudRate = BaudRate(rawValue: gpsBaudratePicker.selectedIndex + 1)!

        settings.portConfigs![portIndex] = port
        
        portsConfigViewController.tableView.reloadData()
    }
}
