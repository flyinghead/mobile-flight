//
//  ConnectionViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 09/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class ConnectionViewController: UITableViewController, UIAlertViewDelegate, BluetoothDelegate {
    var btPeripherals = [BluetoothPeripheral]()
    let btManager = BluetoothManager()
    
    var selectedPeripheral: BluetoothPeripheral?
    var waitIndicator: UIAlertView?
    
    var refreshBluetoothButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        btManager.delegate = self
        refreshBluetooth()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return btPeripherals.count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Bluetooth Devices"
        default:
            return "Other"
        }
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BluetoothCell", forIndexPath: indexPath)

        cell.textLabel?.text = btPeripherals[indexPath.row].name
        cell.detailTextLabel?.text = btPeripherals[indexPath.row].uuid

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedPeripheral = btPeripherals[indexPath.row]
        btManager.connect(selectedPeripheral!)
        let msg = String(format: "Connecting to %@...", selectedPeripheral!.name)
        waitIndicator = UIAlertView(title: "Connecting", message: msg, delegate: self, cancelButtonTitle: "Cancel")
        waitIndicator!.show()
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let screenRect = UIScreen.mainScreen().applicationFrame;
        let view = UIView(frame: CGRect(x: 0, y: 0, width: screenRect.size.width, height: 44.0))
        view.autoresizesSubviews = true
        view.autoresizingMask = .FlexibleWidth
        view.userInteractionEnabled = true

        view.contentMode = .ScaleToFill
//        view.backgroundColor = UIColor.clearColor()
        
        if (refreshBluetoothButton == nil) {
            refreshBluetoothButton = UIButton(type: .System)
            refreshBluetoothButton!.addTarget(self, action: "refreshBluetooth", forControlEvents: .TouchDown)
            refreshBluetoothButton!.setTitle("Refresh", forState: .Normal)
            refreshBluetoothButton!.setTitle("Refreshing...", forState: .Disabled)
            refreshBluetoothButton!.frame = CGRectMake(0.0, 0.0, 160.0, 44.0)
        }
        view.addSubview(refreshBluetoothButton!)
        
        return view
    }
    
    // MARK
    
    func refreshBluetooth() {
        btPeripherals.removeAll()
        tableView.reloadData()
        btManager.startScanning()
        refreshBluetoothButton?.enabled = false
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
        
        dispatch_async(dispatch_get_main_queue(), {
            self.waitIndicator?.message = String(format: "Fetching information...")
            _ = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("waitForFetchComplete:"), userInfo: nil, repeats: true)
            
            msp.sendMessage(.MSP_IDENT, data: nil, retry: true)
            msp.sendMessage(.MSP_API_VERSION, data: nil, retry: true)
//            msp.sendMessage(.MSP_FC_VARIANT, data: nil)
//            msp.sendMessage(.MSP_FC_VERSION, data: nil)
//            msp.sendMessage(.MSP_BUILD_INFO, data: nil)
//            msp.sendMessage(.MSP_BOARD_INFO, data: nil)
            msp.sendMessage(.MSP_UID, data: nil, retry: true)
            // FIXME This one is often truncated when received, buffer overrun? (that was in telemetryViewController)
            msp.sendMessage(.MSP_BOXNAMES, data: nil, retry: true)
        })
        

    }
    
    func waitForFetchComplete(timer : NSTimer) {
//        if Configuration.theConfig.uid != nil || waitIndicator == nil {
        if Settings.theSettings.boxNames != nil || waitIndicator == nil {
            timer.invalidate()
            
            if waitIndicator != nil {
                waitIndicator?.dismissWithClickedButtonIndex(0, animated: true)
                waitIndicator = nil
                performSegueWithIdentifier("next", sender: self)
            }
        }
    }
    
    func failedToConnectToPeripheral(peripheral: BluetoothPeripheral, error: NSError?) {
        dispatch_async(dispatch_get_main_queue(), {
            self.waitIndicator?.message = String(format: "Connection to %@ failed: %@", peripheral.name, error!)
        })
    }
    
    func disconnectedPeripheral(peripheral: BluetoothPeripheral) {
        btManager.delegate = self
        if waitIndicator != nil {
            // Retry
            btManager.connect(selectedPeripheral!)
        }
    }
    
    func receivedData(peripheral: BluetoothPeripheral, data: [UInt8]) {
    }

    // MARK: UIAlertViewDelegate

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if let selection = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(selection, animated: false)
        }
        waitIndicator = nil
        btManager.delegate = self
        if selectedPeripheral != nil {
            btManager.disconnect(selectedPeripheral!)
            selectedPeripheral = nil
        }
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
