//
//  GPSConfigViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 09/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import DownPicker

class GPSConfigViewController: UITableViewController, ConfigChildViewController {
    @IBOutlet weak var gpsSwitch: UISwitch!
    @IBOutlet weak var gpsProtocolField: UITextField!
    @IBOutlet weak var gpsRegionField: UITextField!
    @IBOutlet weak var magDeclinationField: UITextField!

    var gpsProtocolPicker: DownPicker?
    var gpsRegionPicker: DownPicker?
    
    var configViewController: ConfigurationViewController?
    var settings: Settings?
    var misc: Misc?
    
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
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && !gpsSwitch.on {
            return 0.0
        }
        return UITableViewAutomaticDimension
    }
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 1 && !gpsSwitch.on {
            return 0.0
        }
        return UITableViewAutomaticDimension
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 && !gpsSwitch.on {
            return 0.0
        }
        return UITableViewAutomaticDimension
    }

    func setReference(configViewController: ConfigurationViewController, newSettings: Settings, newMisc: Misc) {
        self.configViewController = configViewController
        self.settings = newSettings
        self.misc = newMisc
    }
    override func viewWillDisappear(animated: Bool) {
        misc?.gpsType = gpsProtocolPicker!.selectedIndex
        misc?.gpsUbxSbas = gpsProtocolPicker!.selectedIndex
        misc?.magDeclination = Double(magDeclinationField.text!) ?? 0.0
        configViewController?.refreshData()
    }
    override func viewWillAppear(animated: Bool) {
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
