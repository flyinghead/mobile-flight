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
    let gpsTypeLabels = ["NMEA", "u-blox"]
    let gpsRegionLabels = ["Auto-detect", "Europe", "North America", "Japan", "India"]
    @IBOutlet weak var gpsSwitch: UISwitch!
    @IBOutlet weak var gpsProtocolField: UITextField!
    @IBOutlet weak var gpsRegionField: UITextField!
    @IBOutlet weak var magDeclinationField: NumberField!
    @IBOutlet var hideableCells: [UITableViewCell]!

    var gpsProtocolPicker: MyDownPicker?
    var gpsRegionPicker: MyDownPicker?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        gpsProtocolPicker = MyDownPicker(textField: gpsProtocolField, withData: gpsTypeLabels)
        
        gpsRegionPicker = MyDownPicker(textField: gpsRegionField, withData: gpsRegionLabels)
        
        magDeclinationField.delegate = self
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if gpsProtocolPicker!.selectedIndex >= 0 {
            settings?.gpsType = gpsProtocolPicker!.selectedIndex
        }
        if gpsRegionPicker!.selectedIndex >= 0 {
            settings?.gpsUbxSbas = gpsRegionPicker!.selectedIndex
        }
        settings?.magDeclination = magDeclinationField.value
        configViewController?.refreshUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        gpsSwitch.on = settings!.features.contains(BaseFlightFeature.GPS) ?? false
        gpsProtocolPicker?.selectedIndex = settings!.gpsType
        gpsRegionPicker?.selectedIndex = settings!.gpsUbxSbas
        magDeclinationField.value = settings!.magDeclination
        cells(hideableCells, setHidden: !gpsSwitch.on)
        reloadDataAnimated(false)
    }
    
    @IBAction func gpsSwitchChanged(sender: AnyObject) {
        if (gpsSwitch.on) {
            settings!.features.insert(BaseFlightFeature.GPS)
            cells(hideableCells, setHidden: false)
        } else {
            settings!.features.remove(BaseFlightFeature.GPS)
            cells(hideableCells, setHidden: true)
        }
        reloadDataAnimated(true)
    }
}
