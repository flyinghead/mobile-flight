//
//  CurrentConfigViewController.swift
//  Cleanflight Configurator
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

    var meterTypePicker: MyDownPicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        meterTypePicker = MyDownPicker(textField: meterTypeField, withData: [ "None", "Onboard ADC", "Virtual", "ESC Sensor" ])
        meterTypePicker.setPlaceholder("")
        meterTypePicker.addTarget(self, action: #selector(meterTypeChanged(_:)), forControlEvents: .ValueChanged)

        meterScaleField.delegate = self
        meterOffsetField.delegate = self
    }

    private func hideCellsAsNeeded() {
        if currentMeterSwitch.on {
            var cellsToShow = hideableCells
            if meterTypePicker.selectedIndex < 1 || meterTypePicker.selectedIndex > 2 {
                cellsToShow = Array(Set(cellsToShow).subtract(Set(currentScaleCells)))
                cells(currentScaleCells, setHidden: true)
            }
            cells(cellsToShow, setHidden: false)
        } else {
            cells(hideableCells, setHidden: true)
        }
    }
    
    @IBAction func currentMeterSwitchChanged(sender: AnyObject) {
        if currentMeterSwitch.on {
            settings?.features.insert(.CurrentMeter)
        } else {
            settings?.features.remove(.CurrentMeter)
        }
        hideCellsAsNeeded()
        reloadDataAnimated(true)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        currentMeterSwitch.on = settings!.features.contains(.CurrentMeter)
        meterScaleField.value = Double(settings!.currentScale)
        meterOffsetField.value = Double(settings!.currentOffset)
        meterTypePicker.selectedIndex = settings.currentMeterType
        hideCellsAsNeeded()
        reloadDataAnimated(false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        settings!.currentScale = Int(meterScaleField.value)
        settings!.currentOffset = Int(meterOffsetField.value)
        settings.currentMeterType = meterTypePicker.selectedIndex
        configViewController?.refreshUI()
    }
    
    @IBAction func meterTypeChanged(sender: AnyObject) {
        hideCellsAsNeeded()
        reloadDataAnimated(true)
    }
}
