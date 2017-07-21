//
//  VBatConfigViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 11/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class VBatConfigViewController: ConfigChildViewController {
    @IBOutlet weak var vbatSwitch: UISwitch!
    @IBOutlet weak var minVoltage: NumberField!
    @IBOutlet weak var warningVoltage: NumberField!
    @IBOutlet weak var maxVoltage: NumberField!
    @IBOutlet weak var voltageScale: NumberField!
    @IBOutlet var hideableCells: [UITableViewCell]!
    @IBOutlet var adcCells: [UITableViewCell]!
    @IBOutlet weak var meterTypeFIeld: UITextField!
    @IBOutlet weak var voltageScaleCell: UITableViewCell!
    @IBOutlet weak var dividerField: NumberField!
    @IBOutlet weak var multiplierField: NumberField!
    
    var meterTypePicker: MyDownPicker!

    class func isVBatMonitoringEnabled(settings: Settings) -> Bool {
        if Configuration.theConfig.isApiVersionAtLeast("1.35") {
            return settings.voltageMeterSource > 0
        } else {
            return settings.features.contains(.VBat)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        meterTypePicker = MyDownPicker(textField: meterTypeFIeld, withData: [ "Onboard ADC", "ESC Sensor" ])
        meterTypePicker.addTarget(self, action: #selector(meterTypeChanged(_:)), forControlEvents: .ValueChanged)

        minVoltage.delegate = self
        warningVoltage.delegate = self
        maxVoltage.delegate = self
        voltageScale.delegate = self
        showCells(hideableCells, show: true)
    }

    private func hideCellsAsNeeded() {
        if vbatSwitch.on {
            var cellsToShow = hideableCells
            if meterTypePicker.selectedIndex > 0 {
                cellsToShow = Array(Set(cellsToShow).subtract(Set(adcCells)))
                cells(adcCells, setHidden: true)
            }
            showCells(cellsToShow, show: true)
        } else {
            cells(hideableCells, setHidden: true)
        }
    }
    
    @IBAction func vbatSwitchChanged(sender: AnyObject) {
        if Configuration.theConfig.isApiVersionAtLeast("1.35") {
            if vbatSwitch.on {
                settings.voltageMeterSource = 1
            } else {
                settings.voltageMeterSource = 0
            }
        } else {
            if vbatSwitch.on {
                settings?.features.insert(.VBat)
            } else {
                settings?.features.remove(.VBat)
            }
        }
        hideCellsAsNeeded()
        reloadDataAnimated(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        vbatSwitch.on = VBatConfigViewController.isVBatMonitoringEnabled(settings)
        minVoltage.value = settings!.vbatMinCellVoltage
        warningVoltage.value = settings!.vbatWarningCellVoltage
        maxVoltage.value = settings!.vbatMaxCellVoltage
        voltageScale.value = Double(settings!.vbatScale)
        if Configuration.theConfig.isApiVersionAtLeast("1.35") {
            if vbatSwitch.on {
                meterTypePicker.selectedIndex = settings.voltageMeterSource - 1
            }
        } else {
            meterTypePicker.selectedIndex = settings.vbatMeterType
        }
        dividerField.value = Double(settings.vbatResistorDividerValue)
        multiplierField.value = Double(settings.vbatResistorDividerMultiplier)
        cells(hideableCells, setHidden: !vbatSwitch.on)
        hideCellsAsNeeded()
        reloadDataAnimated(false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        settings?.vbatMinCellVoltage = minVoltage.value
        settings?.vbatWarningCellVoltage = warningVoltage.value
        settings?.vbatMaxCellVoltage = maxVoltage.value
        settings?.vbatScale = Int(voltageScale.value)
        if Configuration.theConfig.isApiVersionAtLeast("1.35") {
            if vbatSwitch.on {
                settings.voltageMeterSource = meterTypePicker.selectedIndex + 1
            } else {
                settings.voltageMeterSource = 0
            }
        } else {
            settings?.vbatMeterType = meterTypePicker.selectedIndex
        }
        settings?.vbatResistorDividerValue = Int(dividerField.value)
        settings?.vbatResistorDividerMultiplier = Int(multiplierField.value)
        configViewController?.refreshUI()
    }
    
    @IBAction func meterTypeChanged(sender: AnyObject) {
        hideCellsAsNeeded()
        reloadDataAnimated(true)
    }
}
