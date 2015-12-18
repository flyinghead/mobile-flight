//
//  GPSConfigViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 09/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import DownPicker

class GPSConfigViewController: ConfigChildViewController {
    let gpsTypeLabels = ["NMEA", "UBLOX"]
    let gpsRegionLabels = ["Auto-detect", "Europe", "North America", "Japan", "India"]
    @IBOutlet weak var gpsSwitch: UISwitch!
    @IBOutlet weak var gpsProtocolField: UITextField!
    @IBOutlet weak var gpsRegionField: UITextField!
    @IBOutlet weak var magDeclinationField: NumberField!

    var gpsProtocolPicker: MyDownPicker?
    var gpsRegionPicker: MyDownPicker?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        gpsProtocolPicker = MyDownPicker(textField: gpsProtocolField, withData: gpsTypeLabels)
        gpsProtocolPicker?.showArrowImage(true)
        gpsRegionPicker = MyDownPicker(textField: gpsRegionField, withData: gpsRegionLabels)
        gpsRegionPicker?.showArrowImage(true)
        
        magDeclinationField.delegate = self
    }

    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return gpsSwitch.on ? super.numberOfSectionsInTableView(tableView) : 1
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if gpsProtocolPicker!.selectedIndex >= 0 {
            misc?.gpsType = gpsProtocolPicker!.selectedIndex
        }
        if gpsRegionPicker!.selectedIndex >= 0 {
            misc?.gpsUbxSbas = gpsRegionPicker!.selectedIndex
        }
        misc?.magDeclination = magDeclinationField.value
        configViewController?.refreshUI()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        gpsSwitch.on = settings!.features?.contains(BaseFlightFeature.GPS) ?? false
        gpsProtocolPicker?.selectedIndex = misc!.gpsType
        gpsRegionPicker?.selectedIndex = misc!.gpsUbxSbas
        magDeclinationField.value = misc!.magDeclination
    }
    
    @IBAction func gpsSwitchChanged(sender: AnyObject) {
        if (gpsSwitch.on) {
            settings!.features!.insert(BaseFlightFeature.GPS)
        } else {
            settings!.features!.remove(BaseFlightFeature.GPS)
        }
        tableView.reloadData()
    }
}
