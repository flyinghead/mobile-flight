//
//  ServosViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 31/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class ServosViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        //initialFetch()
    }
    
    private func initialFetch() {
        msp.sendMessage(.MSP_SERVO_CONFIGURATIONS, data: nil, retry: 2, callback: { success in
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
            })
        })

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initialFetch()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

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
