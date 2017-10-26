//
//  GPSViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 03/12/15.
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

class GPSViewController : UITableViewController {
    var gpsEventHandler: Disposable?
    var slowTimer: Timer?
    
    func receivedGpsData() {
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        gpsEventHandler = msp.gpsEvent.addHandler(self, handler: GPSViewController.receivedGpsData)
        if (slowTimer == nil) {
            // Cleanflight configurator uses 75ms interval. Cleanflight firmware polls every second with ublox GPS.
            slowTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(GPSViewController.slowTimerDidFire(_:)), userInfo: nil, repeats: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        gpsEventHandler?.dispose()
        
        slowTimer?.invalidate()
        slowTimer = nil
    }
    
    func slowTimerDidFire(_ sender: Any) {
        if Configuration.theConfig.isGPSActive() {
            msp.sendMessage(.msp_GPSSVINFO, data: nil)
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 9
        } else {
            return GPSData.theGPSData.satellites.count;
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "GPS"
        } else {
            return "Satellites"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let gpsData = GPSData.theGPSData;
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GPSCell", for: indexPath)
            
            cell.detailTextLabel!.textColor = UIColor.lightGray      // FIXME How to reset to default (ie as set in storyboard)
            switch indexPath.row {
            case 0:
                cell.textLabel!.text = "3D Fix"
                
                if (gpsData.fix) {
                    cell.detailTextLabel!.text = "Yes"
                    cell.detailTextLabel!.textColor = UIColor.green
                } else {
                    cell.detailTextLabel!.text = "No"
                    cell.detailTextLabel!.textColor = UIColor.red
                }
            case 1:
                cell.textLabel!.text = "Altitude"
                cell.detailTextLabel!.text = formatAltitude(Double(gpsData.altitude))
            case 2:
                cell.textLabel!.text = "Latitude"
                cell.detailTextLabel!.text = String(format: "%@°", formatNumber(gpsData.latitude, precision: 4))
            case 3:
                cell.textLabel!.text = "Longitude"
                cell.detailTextLabel!.text = String(format: "%@°", formatNumber(gpsData.longitude, precision: 4))
            case 4:
                cell.textLabel!.text = "Speed"
                cell.detailTextLabel!.text = formatSpeed(gpsData.speed)
            case 5:
                cell.textLabel!.text = "Heading"
                cell.detailTextLabel!.text = String(format: "%@°", formatNumber(gpsData.headingOverGround, precision: 0))
            case 6:
                cell.textLabel!.text = "Satellites"
                cell.detailTextLabel!.text = String(format: "%d", gpsData.numSat)
            case 7:
                cell.textLabel!.text = "Distance to Home"
                cell.detailTextLabel!.text = formatDistance(Double(gpsData.distanceToHome))
            case 8:
                cell.textLabel!.text = "Direction to Home"
                cell.detailTextLabel!.text = String(format: "%d°", gpsData.directionToHome)
            default:
                break
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GPSSatCell", for: indexPath) as! GPSSatCell
            
            let sats = gpsData.satellites
            if indexPath.row < sats.count {
                cell.satIdLabel!.text = String(format: "%d", sats[indexPath.row].svid)
                cell.gauge!.color = sats[indexPath.row].quality.contains(.svUsed) ? cell.green : cell.blue
                cell.gauge!.value = Double(sats[indexPath.row].cno)
            }
            
            return cell
        }
    }
}

class GPSSatCell : UITableViewCell {
    let green = UIColor(red: 0, green: 0.5, blue: 0, alpha: 1)
    let blue = UIColor(red: 0, green: 0.25, blue: 0.5, alpha: 1)
    
    @IBOutlet weak var satIdLabel: UILabel!
    @IBOutlet weak var gauge: LinearGauge!
    
}
