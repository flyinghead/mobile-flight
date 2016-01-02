//
//  GPSViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 03/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class GPSViewController : UITableViewController, FlightDataListener {
    
    var fastTimer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        msp.addDataListener(self)
    }
    
    func receivedGpsData() {
        tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (fastTimer == nil) {
            // Cleanflight/chrome uses 75ms interval
            fastTimer = NSTimer.scheduledTimerWithTimeInterval(0.15, target: self, selector: "fastTimerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        fastTimer?.invalidate()
        fastTimer = nil
    }
    
    func fastTimerDidFire(sender: AnyObject) {
        if Configuration.theConfig.isGPSActive() {
            msp.sendMessage(.MSP_RAW_GPS, data: nil)
            msp.sendMessage(.MSP_COMP_GPS, data: nil)
            msp.sendMessage(.MSP_GPSSVINFO, data: nil)
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 9
        } else {
            return GPSData.theGPSData.satellites.count;
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "GPS"
        } else {
            return "Satellites"
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let gpsData = GPSData.theGPSData;
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("GPSCell", forIndexPath: indexPath)
            
            cell.detailTextLabel!.textColor = UIColor.lightGrayColor()      // FIXME How to reset to default (ie as set in storyboard)
            switch indexPath.row {
            case 0:
                cell.textLabel!.text = "3D Fix"
                
                if (gpsData.fix) {
                    cell.detailTextLabel!.text = "Yes"
                    cell.detailTextLabel!.textColor = UIColor.greenColor()
                } else {
                    cell.detailTextLabel!.text = "No"
                    cell.detailTextLabel!.textColor = UIColor.redColor()
                }
            case 1:
                cell.textLabel!.text = "Altitude"
                cell.detailTextLabel!.text = String(format: "%dm", locale: NSLocale.currentLocale(), gpsData.altitude)
            case 2:
                cell.textLabel!.text = "Latitude"
                cell.detailTextLabel!.text = String(format: "%.4f°", locale: NSLocale.currentLocale(), gpsData.latitude)
            case 3:
                cell.textLabel!.text = "Longitude"
                cell.detailTextLabel!.text = String(format: "%.4f°", locale: NSLocale.currentLocale(), gpsData.longitude)
            case 4:
                cell.textLabel!.text = "Speed"
                cell.detailTextLabel!.text = formatWithUnit(gpsData.speed, unit: "km/h")
            case 5:
                cell.textLabel!.text = "Heading"
                cell.detailTextLabel!.text = String(format: "%.0f°", locale: NSLocale.currentLocale(), gpsData.headingOverGround)
            case 6:
                cell.textLabel!.text = "Satellites"
                cell.detailTextLabel!.text = String(format: "%d", locale: NSLocale.currentLocale(), gpsData.numSat)
            case 7:
                cell.textLabel!.text = "Distance to Home"
                cell.detailTextLabel!.text = String(format: "%dm", locale: NSLocale.currentLocale(), gpsData.distanceToHome)
            case 8:
                cell.textLabel!.text = "Direction to Home"
                cell.detailTextLabel!.text = String(format: "%d°", locale: NSLocale.currentLocale(), gpsData.directionToHome)
            default:
                break
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("GPSSatCell", forIndexPath: indexPath) as! GPSSatCell
            
            let sats = gpsData.satellites
            if indexPath.row < sats.count {
                cell.satIdLabel!.text = String(format: "%d", locale: NSLocale.currentLocale(), sats[indexPath.row].svid)
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