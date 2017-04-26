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

    var meterTypePicker: MyDownPicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        meterTypePicker = MyDownPicker(textField: meterTypeField, withData: [ "None", "Onboard ADC", "Virtual", "ESC Sensor" ])
        meterTypePicker.setPlaceholder("")
        
        meterScaleField.delegate = self
        meterOffsetField.delegate = self
    }

    @IBAction func currentMeterSwitchChanged(sender: AnyObject) {
        if currentMeterSwitch.on {
            settings?.features.insert(.CurrentMeter)
            cells(hideableCells, setHidden: false)
        } else {
            settings?.features.remove(.CurrentMeter)
            cells(hideableCells, setHidden: true)
        }
        reloadDataAnimated(true)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        currentMeterSwitch.on = settings!.features.contains(.CurrentMeter)
        meterScaleField.value = Double(settings!.currentScale)
        meterOffsetField.value = Double(settings!.currentOffset)
        meterTypePicker.selectedIndex = settings.currentMeterType
        cells(hideableCells, setHidden: !currentMeterSwitch.on)
        reloadDataAnimated(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        settings!.currentScale = Int(meterScaleField.value)
        settings!.currentOffset = Int(meterOffsetField.value)
        settings.currentMeterType = meterTypePicker.selectedIndex
        configViewController?.refreshUI()
    }
}
