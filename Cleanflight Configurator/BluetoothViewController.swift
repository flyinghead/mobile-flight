//
//  BluetoothViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 28/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import SVProgressHUD

class BluetoothViewController: UITableViewController, BluetoothDelegate {

    var btPeripherals = [BluetoothPeripheral]()
    let btManager = BluetoothManager()
    var selectedPeripheral: BluetoothPeripheral?
    var refreshBluetoothButton: UIButton?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        btManager.delegate = self
        refreshBluetooth()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func refreshBluetooth() {
        NSLog("Starting bluetooth scanning")
        btPeripherals.removeAll()
        tableView.reloadData()
        btManager.startScanning()
        refreshBluetoothButton?.enabled = false
    }
    
    private func cancelBtConnection(btComm: BluetoothComm) {
        btManager.delegate = self
        btComm.close()
        if let peripheral = selectedPeripheral {
            selectedPeripheral = nil
            failedToConnectToPeripheral(peripheral, error: nil)
        }
    }

    // MARK: BluetoothDelegate
    func foundPeripheral(peripheral: BluetoothPeripheral) {
        dispatch_async(dispatch_get_main_queue(), {
            self.btPeripherals.append(peripheral)
            self.tableView.reloadData()
        })
    }
    
    func stoppedScanning() {
        dispatch_async(dispatch_get_main_queue(), {
            self.refreshBluetoothButton?.enabled = true
        })
    }
    
    func connectedPeripheral(peripheral: BluetoothPeripheral) {
        NSLog("Connected to %@", peripheral.name)
        
        let msp = self.msp
        let btComm = BluetoothComm(withBluetoothManager: btManager, andPeripheral: peripheral, andMSP: msp)
        btManager.delegate = btComm
        
        initiateHandShake({ success in
            if success {
                self.selectedPeripheral = nil
                (self.parentViewController as! MainConnectionViewController).presentNextViewController()
            } else {
                self.cancelBtConnection(btComm)
            }
        })
    }
    
    func failedToConnectToPeripheral(peripheral: BluetoothPeripheral, error: NSError?) {
        dispatch_async(dispatch_get_main_queue(), {
            if error != nil {
                SVProgressHUD.showErrorWithStatus(String(format: "Connection to %@ failed: %@", peripheral.name, error!), maskType: .None)
            } else {
                SVProgressHUD.showErrorWithStatus(String(format: "Connection to %@ failed", peripheral.name), maskType: .None)
            }
        })
    }
    
    func disconnectedPeripheral(peripheral: BluetoothPeripheral) {
        btManager.delegate = self
        if selectedPeripheral != nil {
            // Retry
            btManager.connect(selectedPeripheral!)
        }
    }
    
    func receivedData(peripheral: BluetoothPeripheral, data: [UInt8]) {
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? btPeripherals.count : 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Bluetooth Devices"
        default:
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BluetoothCell", forIndexPath: indexPath)
        
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = btPeripherals[indexPath.row].name
            cell.detailTextLabel?.text = btPeripherals[indexPath.row].uuid
        default:
            break
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case  0:
            selectedPeripheral = btPeripherals[indexPath.row]
            btManager.connect(selectedPeripheral!)
            let msg = String(format: "Connecting to %@...", selectedPeripheral!.name)
            SVProgressHUD.showWithStatus(msg, maskType: .Black)
        default:
            break
        }
    }
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 44.0
        } else {
            return UITableViewAutomaticDimension
        }
    }
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            let screenRect = UIScreen.mainScreen().applicationFrame;
            let view = UIView(frame: CGRect(x: 0, y: 0, width: screenRect.size.width, height: 44.0))
            view.autoresizesSubviews = true
            view.autoresizingMask = .FlexibleWidth
            view.userInteractionEnabled = true
            
            view.contentMode = .ScaleToFill
            
            if (refreshBluetoothButton == nil) {
                refreshBluetoothButton = UIButton(type: .System)
                refreshBluetoothButton!.addTarget(self, action: "refreshBluetooth", forControlEvents: .TouchDown)
                refreshBluetoothButton!.setTitle("Refresh", forState: .Normal)
                refreshBluetoothButton!.setTitle("Refreshing...", forState: .Disabled)
                refreshBluetoothButton!.frame = CGRectMake(0.0, 0.0, screenRect.size.width, 44.0)
            }
            view.addSubview(refreshBluetoothButton!)
            
            return view
        } else {
            return nil
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
