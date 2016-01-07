//
//  SecondViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class AboutViewController: UITableViewController {

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        msp.sendMessage(.MSP_FC_VARIANT, data: nil, retry: 2, callback: { success in
            self.msp.sendMessage(.MSP_FC_VERSION, data: nil, retry: 2, callback: { success in
                self.msp.sendMessage(.MSP_BUILD_INFO, data: nil, retry: 2, callback: { success in
                    self.msp.sendMessage(.MSP_BOARD_INFO, data: nil, retry: 2, callback: { success in
                        dispatch_async(dispatch_get_main_queue(), {
                            self.tableView.reloadData()
                        })
                    })
                })
            })
        })
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
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let config = Configuration.theConfig;
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.textLabel!.text = "Identifier"
                cell.detailTextLabel!.text = config.fcIdentifier
            case 1:
                cell.textLabel!.text = "Version"
                cell.detailTextLabel!.text = config.fcVersion
            case 2:
                cell.textLabel!.text = "Protocol Version"
                cell.detailTextLabel!.text = String(format: "%d", config.msgProtocolVersion)
            case 3:
                cell.textLabel!.text = "API Version"
                cell.detailTextLabel!.text = config.apiVersion
            case 4:
                cell.textLabel!.text = "Build Date"
                cell.detailTextLabel!.text = config.buildInfo
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.textLabel!.text = "Type"
                cell.detailTextLabel!.text = config.boardInfo
            case 1:
                cell.textLabel!.text = "Version"
                cell.detailTextLabel!.text = String(format: "%d", config.boardVersion)
            case 2:
                cell.textLabel!.text = "UID"
                cell.detailTextLabel!.text = config.uid ?? ""
            default:
                break
            }
        default:
            break
        }

        return cell
    }
}

