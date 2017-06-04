//
//  VBatConfigViewController.swift
//  Cleanflight Configurator
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
    @IBOutlet weak var meterTypeFIeld: UITextField!
    @IBOutlet weak var voltageScaleCell: UITableViewCell!
    
    var meterTypePicker: MyDownPicker!

    override func viewDidLoad() {
        super.viewDidLoad()

        meterTypePicker = MyDownPicker(textField: meterTypeFIeld, withData: [ "Onboard ADC", "ESC Sensor" ])
        meterTypePicker.addTarget(self, action: #selector(meterTypeChanged(_:)), forControlEvents: .ValueChanged)

        minVoltage.delegate = self
        warningVoltage.delegate = self
        maxVoltage.delegate = self
        voltageScale.delegate = self

    }

    private func hideCellsAsNeeded() {
        if vbatSwitch.on {
            var cellsToShow = hideableCells
            if meterTypePicker.selectedIndex > 0 {
                cellsToShow = Array(Set(cellsToShow).subtract(Set([ voltageScaleCell ])))
                cell(voltageScaleCell, setHidden: true)
            }
            cells(cellsToShow, setHidden: false)
        } else {
            cells(hideableCells, setHidden: true)
        }
    }
    
    @IBAction func vbatSwitchChanged(sender: AnyObject) {
        if vbatSwitch.on {
            settings?.features.insert(.VBat)
        } else {
            settings?.features.remove(.VBat)
        }
        hideCellsAsNeeded()
        reloadDataAnimated(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        vbatSwitch.on = settings!.features.contains(.VBat)
        minVoltage.value = settings!.vbatMinCellVoltage
        warningVoltage.value = settings!.vbatWarningCellVoltage
        maxVoltage.value = settings!.vbatMaxCellVoltage
        voltageScale.value = Double(settings!.vbatScale)
        meterTypePicker.selectedIndex = settings.vbatMeterType
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
        settings?.vbatMeterType = meterTypePicker.selectedIndex
        configViewController?.refreshUI()
    }
    
    @IBAction func meterTypeChanged(sender: AnyObject) {
        hideCellsAsNeeded()
        reloadDataAnimated(true)
    }
}
