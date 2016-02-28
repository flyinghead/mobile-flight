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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        minVoltage.delegate = self
        warningVoltage.delegate = self
        maxVoltage.delegate = self
        voltageScale.delegate = self
    }

    @IBAction func vbatSwitchChanged(sender: AnyObject) {
        if vbatSwitch.on {
            settings?.features.insert(.VBat)
            cells(hideableCells, setHidden: false)
        } else {
            settings?.features.remove(.VBat)
            cells(hideableCells, setHidden: true)
        }
        reloadDataAnimated(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        vbatSwitch.on = settings!.features.contains(.VBat)
        minVoltage.value = misc!.vbatMinCellVoltage
        warningVoltage.value = misc!.vbatWarningCellVoltage
        maxVoltage.value = misc!.vbatMaxCellVoltage
        voltageScale.value = Double(misc!.vbatScale)
        cells(hideableCells, setHidden: !vbatSwitch.on)
        reloadDataAnimated(false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        misc?.vbatMinCellVoltage = minVoltage.value
        misc?.vbatWarningCellVoltage = warningVoltage.value
        misc?.vbatMaxCellVoltage = maxVoltage.value
        misc?.vbatScale = Int(voltageScale.value)
        configViewController?.refreshUI()
    }
}
