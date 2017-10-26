//
//  WaypointDetailViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 10/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
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

class WaypointDetailViewController: BaseWaypointDetailViewController {
    @IBOutlet weak var altitudeCell: UITableViewCell!
    @IBOutlet weak var speedCell: UITableViewCell!
    @IBOutlet weak var altitudeField: NumberField!
    @IBOutlet weak var speedField: NumberField!
    @IBOutlet weak var sameAltitudeSwitch: UISwitch!
    @IBOutlet weak var defaultSpeedSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        speedField.minimumValue = msToLocaleSpeed(0.5)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if index >= waypointList.count {
            return
        }
        let waypoint = waypointList.waypointAt(index)
        waypoint.altitude = sameAltitudeSwitch.isOn ? 0.0 : localeAltToMeter(altitudeField.value)
        waypoint.speed = defaultSpeedSwitch.isOn ? 0.0 : localeSpeedToMs(speedField.value)
    }
    
    fileprivate func refreshUI() {
        let waypoint = waypointList.waypointAt(index)
        sameAltitudeSwitch.isOn = waypoint.altitude == 0.0
        if waypoint.altitude > 0.0 {
            altitudeField.value = meterToLocaleAlt(waypoint.altitude)
        }
        sameAltitudeChanged(self)
        
        defaultSpeedSwitch.isOn = waypoint.speed == 0.0
        if waypoint.speed > 0.0 {
            speedField.value = msToLocaleSpeed(waypoint.speed)
        }
        defaultSpeedChanged(self)
    }
    
    @IBAction func sameAltitudeChanged(_ sender: AnyObject) {
        cell(altitudeCell, setHidden: sameAltitudeSwitch.isOn)
        reloadData(animated: sender !== self)
    }
    
    @IBAction func defaultSpeedChanged(_ sender: AnyObject) {
        cell(speedCell, setHidden: defaultSpeedSwitch.isOn)
        reloadData(animated: sender !== self)
    }
    
    fileprivate func meterToLocaleAlt(_ alt: Double) -> Double {
        switch selectedUnitSystem() {
        case .imperial, .aviation:
            // feet
            return alt * FEET_PER_METER
        default:
            return alt
        }
    }
    
    fileprivate func localeAltToMeter(_ alt: Double) -> Double {
        switch selectedUnitSystem() {
        case .imperial, .aviation:
            // feet
            return alt / FEET_PER_METER
        default:
            return alt
        }
    }
    

}
