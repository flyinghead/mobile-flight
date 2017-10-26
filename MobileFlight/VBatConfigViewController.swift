//
//  VBatConfigViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 11/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
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

    class func isVBatMonitoringEnabled(_ settings: Settings) -> Bool {
        if hasMultipleVoltageMeters() {
            return settings.voltageMeterSource > 0
        } else {
            return settings.features.contains(.VBat)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        meterTypePicker = MyDownPicker(textField: meterTypeFIeld, withData: [ "Onboard ADC", "ESC Sensor" ])
        meterTypePicker.addTarget(self, action: #selector(meterTypeChanged(_:)), for: .valueChanged)

        minVoltage.delegate = self
        warningVoltage.delegate = self
        maxVoltage.delegate = self
        voltageScale.delegate = self
        showCells(hideableCells, show: true)
    }

    fileprivate func hideCellsAsNeeded() {
        if vbatSwitch.isOn {
            var cellsToShow = hideableCells!
            if meterTypePicker.selectedIndex > 0 {
                cellsToShow = Array(Set(cellsToShow).subtracting(Set(adcCells)))
                cells(adcCells, setHidden: true)
            }
            showCells(cellsToShow, show: true)
        } else {
            cells(hideableCells, setHidden: true)
        }
    }
    
    @IBAction func vbatSwitchChanged(_ sender: Any) {
        if VBatConfigViewController.hasMultipleVoltageMeters() {
            if vbatSwitch.isOn {
                settings.voltageMeterSource = 1
            } else {
                settings.voltageMeterSource = 0
            }
        } else {
            if vbatSwitch.isOn {
                settings?.features.insert(.VBat)
            } else {
                settings?.features.remove(.VBat)
            }
        }
        hideCellsAsNeeded()
        reloadData(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        vbatSwitch.isOn = VBatConfigViewController.isVBatMonitoringEnabled(settings)
        minVoltage.value = settings!.vbatMinCellVoltage
        warningVoltage.value = settings!.vbatWarningCellVoltage
        maxVoltage.value = settings!.vbatMaxCellVoltage
        voltageScale.value = Double(settings!.vbatScale)
        if VBatConfigViewController.hasMultipleVoltageMeters() {
            if vbatSwitch.isOn {
                meterTypePicker.selectedIndex = settings.voltageMeterSource - 1
            }
        } else {
            meterTypePicker.selectedIndex = settings.vbatMeterType
        }
        dividerField.value = Double(settings.vbatResistorDividerValue)
        multiplierField.value = Double(settings.vbatResistorDividerMultiplier)
        cells(hideableCells, setHidden: !vbatSwitch.isOn)
        hideCellsAsNeeded()
        reloadData(animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        settings?.vbatMinCellVoltage = minVoltage.value
        settings?.vbatWarningCellVoltage = warningVoltage.value
        settings?.vbatMaxCellVoltage = maxVoltage.value
        settings?.vbatScale = Int(voltageScale.value)
        if VBatConfigViewController.hasMultipleVoltageMeters() {
            if vbatSwitch.isOn {
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
    
    @IBAction func meterTypeChanged(_ sender: Any) {
        hideCellsAsNeeded()
        reloadData(animated: true)
    }
    
    fileprivate class func hasMultipleVoltageMeters() -> Bool {
        let config = Configuration.theConfig
        return config.isApiVersionAtLeast("1.35") && !config.isINav
    }
}
