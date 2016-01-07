//
//  FailsafeConfigViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 12/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class FailsafeConfigViewController: ConfigChildViewController {
    @IBOutlet weak var failsafeSwitch: UISwitch!
    @IBOutlet weak var throttleField: ThrottleField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        throttleField.delegate = self
    }
    
    @IBAction func failsafeSwitchChanged(sender: AnyObject) {
        tableView.reloadData()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if !failsafeSwitch.on {
            return 1
        }
        return super.numberOfSectionsInTableView(tableView)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if failsafeSwitch.on {
            settings!.features.insert(.Failsafe)
        } else {
            settings!.features.remove(.Failsafe)
        }
        misc!.failsafeThrottle = Int(throttleField.value)
        configViewController?.refreshUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        failsafeSwitch.on = settings!.features.contains(.Failsafe)
        throttleField.value = Double(misc!.failsafeThrottle)
        tableView.reloadData()
    }
}
