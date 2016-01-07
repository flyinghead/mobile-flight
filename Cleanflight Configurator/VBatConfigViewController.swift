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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        minVoltage.delegate = self
        warningVoltage.delegate = self
        maxVoltage.delegate = self
        voltageScale.delegate = self
    }

    @IBAction func vbatSwitchChanged(sender: AnyObject) {
        if vbatSwitch.on {
            settings?.features.insert(.VBat)
        } else {
            settings?.features.remove(.VBat)
        }
        tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        vbatSwitch.on = settings!.features.contains(.VBat)
        minVoltage.value = misc!.vbatMinCellVoltage
        warningVoltage.value = misc!.vbatWarningCellVoltage
        maxVoltage.value = misc!.vbatMaxCellVoltage
        voltageScale.value = Double(misc!.vbatScale)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        misc?.vbatMinCellVoltage = minVoltage.value
        misc?.vbatWarningCellVoltage = warningVoltage.value
        misc?.vbatMaxCellVoltage = maxVoltage.value
        misc?.vbatScale = Int(voltageScale.value)
        configViewController?.refreshUI()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return vbatSwitch.on ? super.numberOfSectionsInTableView(tableView) : 1
    }

}
