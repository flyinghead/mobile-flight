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
    @IBOutlet weak var minVoltage: UITextField!
    @IBOutlet weak var warningVoltage: UITextField!
    @IBOutlet weak var maxVoltage: UITextField!
    @IBOutlet weak var voltageScale: UITextField!
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
            settings?.features!.insert(.VBat)
        } else {
            settings?.features!.remove(.VBat)
        }
        tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        vbatSwitch.on = settings!.features!.contains(.VBat)
        minVoltage.text = String(format: "%.1lf", misc!.vbatMinCellVoltage)
        warningVoltage.text = String(format: "%.1lf", misc!.vbatWarningCellVoltage)
        maxVoltage.text = String(format: "%.1lf", misc!.vbatMaxCellVoltage)
        voltageScale.text = String(format: "%d", misc!.vbatScale)
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        misc?.vbatMinCellVoltage = Double(minVoltage.text!) ?? 3.3
        misc?.vbatWarningCellVoltage = Double(warningVoltage.text!) ?? 3.4
        misc?.vbatMaxCellVoltage = Double(maxVoltage.text!) ?? 4.3
        misc?.vbatScale = Int(voltageScale.text!) ?? 110
        configViewController?.refreshUI()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return vbatSwitch.on ? super.numberOfSectionsInTableView(tableView) : 1
    }

}
