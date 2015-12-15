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
    @IBOutlet weak var gpsSwitch: UISwitch!
    @IBOutlet weak var gpsProtocolField: UITextField!
    @IBOutlet weak var gpsRegionField: UITextField!
    @IBOutlet weak var magDeclinationField: UITextField!

    var gpsProtocolPicker: DownPicker?
    var gpsRegionPicker: DownPicker?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        gpsProtocolPicker = DownPicker(textField: gpsProtocolField, withData: ["NMEA", "UBLOX"])
        gpsProtocolPicker?.showArrowImage(true)
        gpsRegionPicker = DownPicker(textField: gpsRegionField, withData: ["Auto-detect", "Europe", "North America", "Japan", "India"])
        gpsRegionPicker?.showArrowImage(true)
        
        magDeclinationField.delegate = self
    }

    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return gpsSwitch.on ? super.numberOfSectionsInTableView(tableView) : 1
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        misc?.gpsType = gpsProtocolPicker!.selectedIndex
        misc?.gpsUbxSbas = gpsProtocolPicker!.selectedIndex
        misc?.magDeclination = Double(magDeclinationField.text!) ?? 0.0
        configViewController?.refreshUI()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        gpsSwitch.on = settings!.features?.contains(BaseFlightFeature.GPS) ?? false
        gpsProtocolPicker?.selectedIndex = misc!.gpsType
        gpsRegionPicker?.selectedIndex = misc!.gpsUbxSbas
        magDeclinationField.text = String(format: "%.1lf", misc!.magDeclination)
    }
    @IBAction func gpsSwitchChanged(sender: AnyObject) {
        tableView.reloadData()
        if (gpsSwitch.on) {
            settings!.features!.insert(BaseFlightFeature.GPS)
        } else {
            settings!.features!.remove(BaseFlightFeature.GPS)
        }
    }
}
