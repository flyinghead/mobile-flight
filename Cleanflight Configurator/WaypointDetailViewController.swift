//
//  WaypointDetailViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 10/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshUI()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if index >= waypointList.count {
            return
        }
        let waypoint = waypointList.waypointAt(index)
        waypoint.altitude = sameAltitudeSwitch.on ? 0.0 : localeAltToMeter(altitudeField.value)
        waypoint.speed = defaultSpeedSwitch.on ? 0.0 : localeSpeedToMs(speedField.value)
    }
    
    private func refreshUI() {
        let waypoint = waypointList.waypointAt(index)
        sameAltitudeSwitch.on = waypoint.altitude == 0.0
        if waypoint.altitude > 0.0 {
            altitudeField.value = meterToLocaleAlt(waypoint.altitude)
        }
        sameAltitudeChanged(self)
        
        defaultSpeedSwitch.on = waypoint.speed == 0.0
        if waypoint.speed > 0.0 {
            speedField.value = msToLocaleSpeed(waypoint.speed)
        }
        defaultSpeedChanged(self)
    }
    
    @IBAction func sameAltitudeChanged(sender: AnyObject) {
        cell(altitudeCell, setHidden: sameAltitudeSwitch.on)
        reloadDataAnimated(sender !== self)
    }
    
    @IBAction func defaultSpeedChanged(sender: AnyObject) {
        cell(speedCell, setHidden: defaultSpeedSwitch.on)
        reloadDataAnimated(sender !== self)
    }
    
    private func meterToLocaleAlt(alt: Double) -> Double {
        switch selectedUnitSystem() {
        case .Imperial, .Aviation:
            // feet
            return alt * FEET_PER_METER
        default:
            return alt
        }
    }
    
    private func localeAltToMeter(alt: Double) -> Double {
        switch selectedUnitSystem() {
        case .Imperial, .Aviation:
            // feet
            return alt / FEET_PER_METER
        default:
            return alt
        }
    }
    

}
