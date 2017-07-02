//
//  ReceiverConfigViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 11/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class ReceiverConfigViewController: ConfigChildViewController {
    @IBOutlet var serialReceiverCells: [UITableViewCell]!
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
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
        cell.accessoryType = selected ? .Checkmark : .None
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
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
        reloadDataAnimated(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        configViewController?.refreshUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        cells(serialReceiverCells, setHidden: !settings!.features.contains(.RxSerial))
        reloadDataAnimated(false)
    }
    
    class func receiverConfigLabel(settings: Settings) -> String {
        if settings.features.contains(.RxParallel) {
            return "PWM"
        } else if settings.features.contains(.RxPpm) {
            return "PPM"
        } else if settings.features.contains(.RxMsp) {
            return "MSP"
        } else if settings.features.contains(.RxSerial) {
            switch settings.serialRxType ?? 0 {
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
