//
//  SecondViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class AboutViewController: UITableViewController, FlightDataListener {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        msp.addDataListener(self)
    }
    override func viewWillAppear(animated: Bool) {
        msp.sendMessage(.MSP_FC_VARIANT, data: nil, retry: 2, callback: nil)
        msp.sendMessage(.MSP_FC_VERSION, data: nil, retry: 2, callback: nil)
        msp.sendMessage(.MSP_BUILD_INFO, data: nil, retry: 2, callback: nil)
        msp.sendMessage(.MSP_BOARD_INFO, data: nil, retry: 2, callback: nil)
    }
    
    func receivedData() {
        //FIXME This doesn't always work, perhaps b/c we call it too fast/much. race condition?
        tableView.reloadData()
    }

    // MARK: - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 5
        } else {
            return 3;
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Flight controller"
        } else {
            return "Board"
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Value1, reuseIdentifier: "Cell")
        }
        
        let config = Configuration.theConfig;
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell!.textLabel!.text = "Identifier"
                cell!.detailTextLabel!.text = config.fcIdentifier
            case 1:
                cell!.textLabel!.text = "Version"
                cell!.detailTextLabel!.text = config.fcVersion
            case 2:
                cell!.textLabel!.text = "Protocol Version"
                cell!.detailTextLabel!.text = config.msgProtocolVersion == nil ? "" : String(format: "%d", config.msgProtocolVersion!)
            case 3:
                cell!.textLabel!.text = "API Version"
                cell!.detailTextLabel!.text = config.apiVersion
            case 4:
                cell!.textLabel!.text = "Build Date"
                cell!.detailTextLabel!.text = config.buildInfo
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell!.textLabel!.text = "Type"
                cell!.detailTextLabel!.text = config.boardInfo
            case 1:
                cell!.textLabel!.text = "Version"
                cell!.detailTextLabel!.text = config.boardVersion == nil ? "" : String(format: "%d", config.boardVersion!)
            case 2:
                cell!.textLabel!.text = "UID"
                cell!.detailTextLabel!.text = config.uid ?? ""
            default:
                break
            }
        default:
            break
        }

        return cell!
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            //            objects!.removeAtIndex(indexPath.row)
            //            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }

}

