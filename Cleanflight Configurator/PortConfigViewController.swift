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
    @IBOutlet weak var enableBlackbox: UISwitch!
    @IBOutlet weak var blackboxBaudrateField: UITextField!
    @IBOutlet weak var telemetryTypeField: UITextField!
    @IBOutlet weak var telemetryBaudrateField: UITextField!
    @IBOutlet weak var enableRx: UISwitch!
    @IBOutlet weak var enableGPS: UISwitch!
    @IBOutlet weak var gpsBaudrateField: UITextField!

    var mspBaudratePicker: MyDownPicker!
    var blackboxBaudratePicker: MyDownPicker!
    var telemetryTypePicker: MyDownPicker!
    var telemetryBaudratePicker: MyDownPicker!
    var gpsBaudratePicker: MyDownPicker!
    
    var portIndex: Int!
    var portsConfigViewController: PortsConfigViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mspBaudratePicker = MyDownPicker(textField: mspBaudrateField, withData: [ "9600", "19200", "38400", "57600", "115200" ])
        mspBaudratePicker.setPlaceholder("")
        blackboxBaudratePicker = MyDownPicker(textField: blackboxBaudrateField, withData: [ "19200", "38400", "57600", "115200", "230400", "250000" ])
        blackboxBaudratePicker.setPlaceholder("")
        telemetryTypePicker = MyDownPicker(textField: telemetryTypeField, withData: [ "Disabled", "Frsky", "Hott", Configuration.theConfig.isApiVersionAtLeast("1.15") ? "LTM" : "MSP", "SmartPort", "MAVLink" ])
        telemetryTypePicker.setPlaceholder("")
        telemetryBaudratePicker = MyDownPicker(textField: telemetryBaudrateField, withData: [ "Auto", "9600", "19200", "38400", "57600", "115200" ])
        telemetryBaudratePicker.setPlaceholder("")
        gpsBaudratePicker = MyDownPicker(textField: gpsBaudrateField, withData: [ "9600", "19200", "38400", "57600", "115200" ])
        gpsBaudratePicker.setPlaceholder("")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let port = settings.portConfigs![portIndex]
        
        enableMSP.on = port.functions.contains(.MSP)
        mspBaudratePicker.selectedIndex = port.mspBaudRate.rawValue - 1             // No auto
        
        enableBlackbox.on = port.functions.contains(.Blackbox)
        blackboxBaudratePicker.selectedIndex = port.blackboxBaudRate.rawValue - 2   // No auto or 9600
        
        if port.functions.contains(.TelemetryFrsky) {
            telemetryTypePicker.selectedIndex = 1
        } else if port.functions.contains(.TelemetryHott) {
            telemetryTypePicker.selectedIndex = 2
        } else if port.functions.contains(.TelemetryLTM) {
            telemetryTypePicker.selectedIndex = 3
        } else if port.functions.contains(.TelemetrySmartPort) {
            telemetryTypePicker.selectedIndex = 4
        } else if port.functions.contains(.TelemetryMAVLink) {
            telemetryTypePicker.selectedIndex = 5
        } else {
            telemetryTypePicker.selectedIndex = 0
        }
        telemetryBaudratePicker.selectedIndex = port.telemetryBaudRate.rawValue
        
        enableRx.on = port.functions.contains(.RxSerial)
        
        enableGPS.on = port.functions.contains(.GPS)
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
        
        if enableBlackbox.on {
            port.functions.insert(.Blackbox)
        } else {
            port.functions.remove(.Blackbox)
        }
        port.blackboxBaudRate = BaudRate(rawValue: blackboxBaudratePicker.selectedIndex + 2)!
        
        port.functions.remove(.TelemetryFrsky)
        port.functions.remove(.TelemetryHott)
        port.functions.remove(.TelemetryLTM)
        port.functions.remove(.TelemetrySmartPort)
        port.functions.remove(.TelemetryMAVLink)
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
            port.functions.insert(.TelemetryMAVLink)
        default:
            break
        }
        port.telemetryBaudRate = BaudRate(rawValue: telemetryBaudratePicker.selectedIndex)!
        
        if enableRx.on {
            port.functions.insert(.RxSerial)
        } else {
            port.functions.remove(.RxSerial)
        }
        
        if enableGPS.on {
            port.functions.insert(.GPS)
        } else {
            port.functions.remove(.GPS)
        }
        port.gpsBaudRate = BaudRate(rawValue: gpsBaudratePicker.selectedIndex + 1)!

        settings.portConfigs![portIndex] = port
        
        portsConfigViewController.tableView.reloadData()
    }
}
