//
//  MotorTestViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 28/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import SVProgressHUD

class MotorTestViewController: UITableViewController, UseMAVLinkVehicle {
    let colors = [UIColor(hex6: 0xf1453d), UIColor(hex6: 0x673fb4), UIColor(hex6: 0x2b98f0), UIColor(hex6: 0x1fbcd2),
        UIColor(hex6: 0x159588), UIColor(hex6: 0x50ae55), UIColor(hex6: 0xcdda49), UIColor(hex6: 0xfdc02f)]
    
    @IBOutlet weak var enableButton: UIBarButtonItem!
    private var motorTestEnabled = false

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        vehicle.motors.addObserver(self) {_ in
            self.tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        vehicle.motors.removeObserver(self)
    }
    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mavlinkVehicle.motorCount
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("motorCell", forIndexPath: indexPath) as! MotorTestTableCell

        cell.motorIndex = indexPath.row
        cell.motorLabel.text = String(format: "Motor %d", indexPath.row + 1)
        cell.motorGauge.color = colors[min(indexPath.row, colors.count - 1)]
        if let motors = mavlinkVehicle.motors.value {
            cell.motorGauge.value = indexPath.row < motors.count ? Double(motors[indexPath.row]) : 0
        } else {
            cell.motorGauge.value = 1000
        }
        cell.motorSlider.enabled = motorTestEnabled
        cell.motorSlider.hidden = !motorTestEnabled
        if !motorTestEnabled {
            cell.motorSlider.value = 0
        }
        cell.motorSlider.setNeedsDisplay()

        return cell
    }

    @IBAction func enableMotorTesting(sender: AnyObject) {
        motorTestEnabled = !motorTestEnabled
        enableButton.title = motorTestEnabled ? "Disable" : "Enable"
        tableView.reloadData()
    }
}

class MotorTestTableCell : UITableViewCell, UseMAVLinkVehicle {
    @IBOutlet weak var motorLabel: UILabel!
    @IBOutlet weak var motorGauge: LinearGauge!
    @IBOutlet weak var motorSlider: UISlider!
    
    var motorIndex = 0
    
    @IBAction func motorSliderChanged(sender: AnyObject) {
        mavlinkProtocolHandler.motorTest(motorIndex + 1, throttle: Int(motorSlider.value), timeout: 30, callback: { success in
            if !success {
                SVProgressHUD.showErrorWithStatus("Command failed")
            }
        })
    }
}
