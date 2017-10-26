//
//  ReceiverConfigViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 11/12/15.
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

class ReceiverConfigViewController: ConfigChildViewController {
    @IBOutlet var serialReceiverCells: [UITableViewCell]!
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        var selected = false
        if indexPath.section == 0 {
            // Receiver type
            switch indexPath.row {
            case 0:     // PWM
                selected = settings!.features.contains(.RxParallel)
            case 1:     // PPM
                selected = settings!.features.contains(.RxPpm)
            case 2:     // Serial RX
                selected = settings!.features.contains(.RxSerial)
            case 3:     // MSP
                selected = settings!.features.contains(.RxMsp)
            default:
                break
            }
        } else {
            // Serial receiver type
            selected = settings!.serialRxType == indexPath.row
        }
        cell.accessoryType = selected ? .checkmark : .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            // Receiver type
            settings?.features.remove(.RxPpm)
            settings?.features.remove(.RxSerial)
            settings?.features.remove(.RxParallel)
            settings?.features.remove(.RxMsp)
            switch indexPath.row {
            case 0:     // PWM
                settings?.features.insert(.RxParallel)
            case 1:     // PPM
                settings?.features.insert(.RxPpm)
            case 2:     // Serial RX
                settings?.features.insert(.RxSerial)
            case 3:     // MSP
                settings?.features.insert(.RxMsp)
            default:
                break
            }
            cells(serialReceiverCells, setHidden: !settings!.features.contains(.RxSerial))
        } else {
            // Serial receiver type
            settings!.serialRxType = indexPath.row
        }
        reloadData(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        configViewController?.refreshUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cells(serialReceiverCells, setHidden: !settings!.features.contains(.RxSerial))
        reloadData(animated: false)
    }
    
    class func receiverConfigLabel(_ settings: Settings) -> String {
        if settings.features.contains(.RxParallel) {
            return "PWM"
        } else if settings.features.contains(.RxPpm) {
            return "PPM"
        } else if settings.features.contains(.RxMsp) {
            return "MSP"
        } else if settings.features.contains(.RxSerial) {
            switch settings.serialRxType {
            case 0:
                return "Spektrum 1024"
            case 1:
                return "Spektrum 2048"
            case 2:
                return "S.Bus"
            case 3:
                return "SUMD"
            case 4:
                return "SUMH"
            case 5:
                return "SRXL"
            case 6:
                return "XBUS RJ01"
            case 7:
                return "iBus"
            case 8:
                return "EX Bus"
            case 9:
                return "CRSF"
            case 10:
                return "SRXL"
            default:
                return "Unknown Serial"
            }
        }
        
        return "Unknown"
    }
}
