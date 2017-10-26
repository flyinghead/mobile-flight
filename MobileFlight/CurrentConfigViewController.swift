//
//  CurrentConfigViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 02/02/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
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

class CurrentConfigViewController: ConfigChildViewController {
    @IBOutlet weak var currentMeterSwitch: UISwitch!
    @IBOutlet weak var meterScaleField: NumberField!
    @IBOutlet weak var meterOffsetField: NumberField!
    @IBOutlet weak var meterTypeField: UITextField!
    @IBOutlet var hideableCells: [UITableViewCell]!
    @IBOutlet var currentScaleCells: [UITableViewCell]!
    @IBOutlet weak var batteryCapacityField: NumberField!

    var meterTypePicker: MyDownPicker!
    
    class func isCurrentMonitoringEnabled(_ settings: Settings) -> Bool {
        if hasMultipleCurrentMeters() {
            return settings.currentMeterSource > 0
        } else {
            return settings.features.contains(.CurrentMeter)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let sensorTypes: [String]
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.31") && !config.isINav {
            sensorTypes = [ "Onboard ADC", "Virtual", "ESC Sensor" ]
        } else {
            sensorTypes = [ "Onboard ADC", "Virtual" ]
        }
        meterTypePicker = MyDownPicker(textField: meterTypeField, withData: sensorTypes)
        meterTypePicker.addTarget(self, action: #selector(meterTypeChanged(_:)), for: .valueChanged)

        meterScaleField.delegate = self
        meterOffsetField.delegate = self
    }

    fileprivate func hideCellsAsNeeded() {
        if currentMeterSwitch.isOn {
            var cellsToShow = hideableCells
            if meterTypePicker.selectedIndex > 1 {
                cellsToShow = Array(Set(cellsToShow!).subtracting(Set(currentScaleCells)))
                cells(currentScaleCells, setHidden: true)
            }
            cells(cellsToShow, setHidden: false)
        } else {
            cells(hideableCells, setHidden: true)
        }
    }
    
    @IBAction func currentMeterSwitchChanged(_ sender: Any) {
        if CurrentConfigViewController.hasMultipleCurrentMeters() {
            if !currentMeterSwitch.isOn {
                settings.currentMeterSource = 0
            }
        } else {
            if currentMeterSwitch.isOn {
                settings?.features.insert(.CurrentMeter)
            } else {
                settings?.features.remove(.CurrentMeter)
            }
        }
        hideCellsAsNeeded()
        reloadData(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        currentMeterSwitch.isOn = CurrentConfigViewController.isCurrentMonitoringEnabled(settings)
        meterScaleField.value = Double(settings.currentScale)
        meterOffsetField.value = Double(settings.currentOffset)

        if CurrentConfigViewController.hasMultipleCurrentMeters() {
            if currentMeterSwitch.isOn {
                meterTypePicker.selectedIndex = settings.currentMeterSource - 1
            }
        } else {
            meterTypePicker.selectedIndex = settings.currentMeterType - 1
        }
        batteryCapacityField.value = Double(settings.batteryCapacity)
        hideCellsAsNeeded()
        reloadData(animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if CurrentConfigViewController.hasMultipleCurrentMeters() {
            if currentMeterSwitch.isOn {
                settings.currentMeterSource = meterTypePicker.selectedIndex + 1
            } else {
                settings.currentMeterSource = 0
            }
        } else {
            settings.currentMeterType = meterTypePicker.selectedIndex + 1
        }
        settings.currentScale = Int(meterScaleField.value)
        settings.currentOffset = Int(meterOffsetField.value)
        settings.batteryCapacity = Int(round(batteryCapacityField.value))
        configViewController?.refreshUI()
    }
    
    @IBAction func meterTypeChanged(_ sender: Any) {
        hideCellsAsNeeded()
        reloadData(animated: true)
    }
    
    fileprivate class func hasMultipleCurrentMeters() -> Bool {
        let config = Configuration.theConfig
        return config.isApiVersionAtLeast("1.35") && !config.isINav
    }
}
