//
//  ServosViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 31/12/15.
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
import SVProgressHUD

class ServosViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(ServosViewController.refreshServoConfig), forControlEvents: .ValueChanged)
    }

    @objc
    private func refreshServoConfig() {
        msp.sendMessage(.MSP_SERVO_CONFIGURATIONS, data: nil, retry: 4, callback: { success in
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
                if !success {
                    SVProgressHUD.showErrorWithStatus("Communication error or servos not supported")
                }
            })
        })

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshServoConfig()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Settings.theSettings.servoConfigs?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ServoCell", forIndexPath: indexPath) as! ServoCell

        cell.servoLabel.text = String(format: "Servo %d", indexPath.row + 1)
        let settings = Settings.theSettings
        if settings.servoConfigs != nil && indexPath.row < settings.servoConfigs!.count {
            let servoConfig = settings.servoConfigs![indexPath.row]
            cell.rcRangeLabel.text = String(format: "%d-%d-%d", servoConfig.minimumRC, servoConfig.middleRC, servoConfig.maximumRC)
            cell.anglesLabel.text = String(format: "%d°-%d°", servoConfig.minimumAngle, servoConfig.maximumAngle)
            cell.rateLabel.text = String(format: "%d%%", servoConfig.rate)
            
            if servoConfig.rcChannel == nil {
                cell.rcChannelLabel.text = ""
            } else {
                cell.rcChannelLabel.text = ReceiverViewController.channelLabel(servoConfig.rcChannel!)
            }
        }
        
        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let viewController = segue.destinationViewController as! ServoConfigViewController
        viewController.servoIdx = tableView.indexPathForSelectedRow?.row
    }

}

class ServoCell : UITableViewCell {
    @IBOutlet weak var servoLabel: UILabel!
    @IBOutlet weak var rcRangeLabel: UILabel!
    @IBOutlet weak var anglesLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var rcChannelLabel: UILabel!
    
}
