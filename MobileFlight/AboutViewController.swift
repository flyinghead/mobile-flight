//
//  SecondViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 02/12/15.
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
import Firebase

class AboutViewController: UITableViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        msp.sendMessage(.msp_UID, data: nil, retry: 2, callback: { success in
            self.msp.sendMessage(.msp_FC_VERSION, data: nil, retry: 2, callback: { success in
                self.msp.sendMessage(.msp_BUILD_INFO, data: nil, retry: 2, callback: { success in
                    self.msp.sendMessage(.msp_BOARD_INFO, data: nil, retry: 2, callback: { success in
                        DispatchQueue.main.async(execute: {
                            let config = Configuration.theConfig
                            Analytics.logEvent("about_info", parameters: [ "fcIdentifier" :  config.fcIdentifier!, "fcVersion" : config.fcVersion ?? "(unknown)", "buildDate" : config.buildInfo ?? "(unknown)", "boardType" : config.boardInfo ?? "(unknown)"])
                            self.tableView.reloadData()
                        })
                    })
                })
            })
        })
    }

    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 5
        } else {
            return 3;
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Flight controller"
        } else {
            return "Board"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let config = Configuration.theConfig
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.textLabel!.text = "Identifier"
                cell.detailTextLabel!.text = config.fcIdentifier ?? " "         // Avoid nil text because of iOS8 bug
            case 1:
                cell.textLabel!.text = "Version"
                cell.detailTextLabel!.text = config.fcVersion ?? " "
            case 2:
                cell.textLabel!.text = "Protocol Version"
                cell.detailTextLabel!.text = String(format: "%d", config.msgProtocolVersion)
            case 3:
                cell.textLabel!.text = "API Version"
                cell.detailTextLabel!.text = config.apiVersion ?? " "
            case 4:
                cell.textLabel!.text = "Build Date"
                cell.detailTextLabel!.text = config.buildInfo ?? " "
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.textLabel!.text = "Type"
                cell.detailTextLabel!.text = config.boardInfo ?? " "
            case 1:
                cell.textLabel!.text = "Version"
                cell.detailTextLabel!.text = String(format: "%d", config.boardVersion)
            case 2:
                cell.textLabel!.text = "UID"
                cell.detailTextLabel!.text = config.uid ?? " "
            default:
                break
            }
        default:
            break
        }

        return cell
    }
}

