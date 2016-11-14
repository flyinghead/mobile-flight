//
//  PortsConfigViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 14/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class PortsConfigViewController: ConfigChildViewController {

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.portConfigs?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PortCell", forIndexPath: indexPath)

        let i = indexPath.row
        if i < settings.portConfigs?.count ??  0 {
            switch settings.portConfigs![i].portIdentifier {
            case .USART1:
                cell.textLabel?.text = "UART1"
            case .USART2:
                cell.textLabel?.text = "UART2"
            case .USART3:
                cell.textLabel?.text = "UART3"
            case .USART4:
                cell.textLabel?.text = "UART4"
            case .USB_VCP:
                cell.textLabel?.text = "USB"
            case .SoftSerial1:
                cell.textLabel?.text = "SOFTSERIAL1"
            case .SoftSerial2:
                cell.textLabel?.text = "SOFTSERIAL2"
            default:
                cell.textLabel?.text = String(format: "%d", settings.portConfigs![i].portIdentifier.rawValue)
            }
            var detail = ""
            let functions = settings.portConfigs![i].functions
            if functions.contains(.MSP) {
                detail = "Data"
            }
            if functions.contains(.TelemetryFrsky) || functions.contains(.TelemetryHott) || functions.contains(.TelemetryLTM) || functions.contains(.TelemetrySmartPort) || functions.contains(.TelemetryMAVLink) {
                if !detail.isEmpty {
                    detail += ", "
                }
                detail += "Telemetry"
            }
            if functions.contains(.RxSerial) {
                if !detail.isEmpty {
                    detail += ", "
                }
                detail += "RX"
            }
            if functions.contains(.GPS) {
                if !detail.isEmpty {
                    detail += ", "
                }
                detail += "GPS"
            }
            if functions.contains(.Blackbox) {
                if !detail.isEmpty {
                    detail += ", "
                }
                detail += "Logging"
            }
            if detail.isEmpty {
                detail = " "        // iOS8 bug
            }
            cell.detailTextLabel?.text = detail
        }
        
        return cell
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let viewController = segue.destinationViewController as! PortConfigViewController
        viewController.portIndex = tableView.indexPathForSelectedRow?.row ?? 0
        viewController.portsConfigViewController = self
        viewController.setReference(configViewController!, newSettings: settings!, newMisc: misc!)
    }
}
