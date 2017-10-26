//
//  GPSConfigViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 09/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

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

    override func viewWillDisappear(_ animated: Bool) {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gpsSwitch.isOn = settings!.features.contains(BaseFlightFeature.GPS)
        gpsProtocolPicker?.selectedIndex = settings!.gpsType
        gpsRegionPicker?.selectedIndex = settings!.gpsUbxSbas
        magDeclinationField.value = settings!.magDeclination
        cells(hideableCells, setHidden: !gpsSwitch.isOn)
        reloadData(animated: false)
    }
    
    @IBAction func gpsSwitchChanged(_ sender: Any) {
        if (gpsSwitch.isOn) {
            settings!.features.insert(BaseFlightFeature.GPS)
            cells(hideableCells, setHidden: false)
        } else {
            settings!.features.remove(BaseFlightFeature.GPS)
            cells(hideableCells, setHidden: true)
        }
        reloadData(animated: true)
    }
}
