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
    @IBOutlet weak var legacyMultiwiiSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        meterScaleField.delegate = self
        meterOffsetField.delegate = self
    }

    @IBAction func currentMeterSwitchChanged(sender: AnyObject) {
        if currentMeterSwitch.on {
            settings?.features.insert(.CurrentMeter)
        } else {
            settings?.features.remove(.CurrentMeter)
        }
        tableView.reloadData()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        currentMeterSwitch.on = settings!.features.contains(.CurrentMeter)
        meterScaleField.value = Double(settings!.currentScale)
        meterOffsetField.value = Double(settings!.currentOffset)
        legacyMultiwiiSwitch.on = misc!.multiwiiCurrentOutput == 1
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        settings!.currentScale = Int(meterScaleField.value)
        settings!.currentOffset = Int(meterOffsetField.value)
        misc!.multiwiiCurrentOutput = legacyMultiwiiSwitch.on ? 1 : 0
        configViewController?.refreshUI()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return currentMeterSwitch.on ? super.numberOfSectionsInTableView(tableView) : 1
    }
}
