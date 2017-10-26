//
//  PortsConfigViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 14/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
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

class PortsConfigViewController: ConfigChildViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.portConfigs?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PortCell", for: indexPath)

        let config = Configuration.theConfig
        let i = indexPath.row
        if i < settings.portConfigs?.count ??  0 {
            cell.textLabel?.text = settings.portConfigs![i].portIdentifier.name
            var detail = ""
            let functions = settings.portConfigs![i].functions
            if functions.contains(.MSP) {
                detail = "Data"
            }
            if functions.contains(.TelemetryFrsky) || functions.contains(.TelemetryHott) || functions.contains(.TelemetryLTM) || functions.contains(.TelemetrySmartPort)
                    || functions.contains(.TelemetryMAVLink) || functions.contains(.TelemetryMAVLinkOld) {
                if !detail.isEmpty {
                    detail += ", "
                }
                detail += "Telemetry"
            }
            if functions.contains(.RxSerial) {
                if !detail.isEmpty {
                    detail += ", "
                }
                detail += "RX"
            }
            if functions.contains(.GPS) {
                if !detail.isEmpty {
                    detail += ", "
                }
                detail += "GPS"
            }
            if !config.isINav && functions.contains(.ESCSensor) {
                if !detail.isEmpty {
                    detail += ", "
                }
                detail += "ESC"
            }
            if functions.contains(.Blackbox) {
                if !detail.isEmpty {
                    detail += ", "
                }
                detail += "Blackbox"
            }
            if !config.isINav && functions.contains(.VTXSmartAudio) || functions.contains(.VTXTramp) {
                if !detail.isEmpty {
                    detail += ", "
                }
                detail += "VTX"
            }
            if (!config.isINav && functions.contains(.RuncamSplit)) || (config.isINav && functions.contains(.RuncamSplitINAV)) {
                if !detail.isEmpty {
                    detail += ", "
                }
                detail += "CAM"
            }
            if detail.isEmpty {
                detail = " "        // iOS8 bug
            }
            cell.detailTextLabel?.text = detail
        }
        
        return cell
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as! PortConfigViewController
        viewController.portIndex = tableView.indexPathForSelectedRow?.row ?? 0
        viewController.portsConfigViewController = self
        viewController.setReference(configViewController!, newSettings: settings!, newMisc: misc!)
    }
}
