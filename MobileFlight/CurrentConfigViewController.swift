//
//  CurrentConfigViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 02/02/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

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
    
    class func isCurrentMonitoringEnabled(settings: Settings) -> Bool {
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
        meterTypePicker.addTarget(self, action: #selector(meterTypeChanged(_:)), forControlEvents: .ValueChanged)

        meterScaleField.delegate = self
        meterOffsetField.delegate = self
    }

    private func hideCellsAsNeeded() {
        if currentMeterSwitch.on {
            var cellsToShow = hideableCells
            if meterTypePicker.selectedIndex > 1 {
                cellsToShow = Array(Set(cellsToShow).subtract(Set(currentScaleCells)))
                cells(currentScaleCells, setHidden: true)
            }
            cells(cellsToShow, setHidden: false)
        } else {
            cells(hideableCells, setHidden: true)
        }
    }
    
    @IBAction func currentMeterSwitchChanged(sender: AnyObject) {
        if CurrentConfigViewController.hasMultipleCurrentMeters() {
            if !currentMeterSwitch.on {
                settings.currentMeterSource = 0
            }
        } else {
            if currentMeterSwitch.on {
                settings?.features.insert(.CurrentMeter)
            } else {
                settings?.features.remove(.CurrentMeter)
            }
        }
        hideCellsAsNeeded()
        reloadDataAnimated(true)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        currentMeterSwitch.on = CurrentConfigViewController.isCurrentMonitoringEnabled(settings)
        meterScaleField.value = Double(settings.currentScale)
        meterOffsetField.value = Double(settings.currentOffset)

        if CurrentConfigViewController.hasMultipleCurrentMeters() {
            if currentMeterSwitch.on {
                meterTypePicker.selectedIndex = settings.currentMeterSource - 1
            }
        } else {
            meterTypePicker.selectedIndex = settings.currentMeterType - 1
        }
        batteryCapacityField.value = Double(settings.batteryCapacity)
        hideCellsAsNeeded()
        reloadDataAnimated(false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if CurrentConfigViewController.hasMultipleCurrentMeters() {
            if currentMeterSwitch.on {
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
    
    @IBAction func meterTypeChanged(sender: AnyObject) {
        hideCellsAsNeeded()
        reloadDataAnimated(true)
    }
    
    private class func hasMultipleCurrentMeters() -> Bool {
        let config = Configuration.theConfig
        return config.isApiVersionAtLeast("1.35") && !config.isINav
    }
}
