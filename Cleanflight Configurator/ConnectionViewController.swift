//
//  ConnectionViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 09/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import SVProgressHUD

class ConnectionViewController: UITableViewController, BluetoothDelegate {

    var btPeripherals = [BluetoothPeripheral]()
    let btManager = BluetoothManager()
    
    var selectedPeripheral: BluetoothPeripheral?
    
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
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? btPeripherals.count : 1
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Bluetooth Devices"
        default:
            return "TCP/IP"
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return 94
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(indexPath.section == 0 ? "BluetoothCell" : "TCPCell", forIndexPath: indexPath)

        if let tcpCell = cell as? TCPTableViewCell {
            tcpCell.viewController = self
        } else {
            cell.textLabel?.text = btPeripherals[indexPath.row].name
            cell.detailTextLabel?.text = btPeripherals[indexPath.row].uuid
        }
        
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            selectedPeripheral = btPeripherals[indexPath.row]
            btManager.connect(selectedPeripheral!)
            let msg = String(format: "Connecting to %@...", selectedPeripheral!.name)
            SVProgressHUD.showWithStatus(msg, maskType: .Black)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
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
    
    // MARK
    
    func refreshBluetooth() {
        NSLog("Starting bluetooth scanning")
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
        
        initiateHandShake({ self.cancelConnection(btComm) })
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

    // MARK:
    
    func initiateHandShake(errorCallback: () -> Void) {
        let msp = self.msp

        dispatch_async(dispatch_get_main_queue(), {
            SVProgressHUD.setStatus("Fetching information...")
            
            msp.sendMessage(.MSP_IDENT, data: nil, retry: 2, callback: { success in
                if success {
                    msp.sendMessage(.MSP_API_VERSION, data: nil, retry: 2, callback: { success in
                        if success {
                            if !Configuration.theConfig.isApiVersionAtLeast("1.7") {
                                dispatch_async(dispatch_get_main_queue(), {
                                    errorCallback()
                                    SVProgressHUD.showErrorWithStatus("This version of the API is not supported", maskType: .None)
                                })
                            } else {
                                msp.sendMessage(.MSP_UID, data: nil, retry: 2, callback: { success in
                                    if success {
                                        msp.sendMessage(.MSP_BOXNAMES, data: nil, retry: 2, callback: { success in
                                            if success {
                                                dispatch_async(dispatch_get_main_queue(), {
                                                    SVProgressHUD.dismiss()
                                                    self.selectedPeripheral = nil
                                                    self.performSegueWithIdentifier("next", sender: self)
                                                })
                                            } else {
                                                errorCallback()
                                            }
                                        })
                                    } else {
                                        errorCallback()
                                    }
                                })
                            }
                        } else {
                            errorCallback()
                        }
                    })
                } else {
                    errorCallback()
                }
            })
        })
    }
    
    private func cancelConnection(btComm: BluetoothComm) {
        let peripheral = selectedPeripheral!
        selectedPeripheral = nil
        btManager.delegate = self
        btComm.close()
        failedToConnectToPeripheral(peripheral, error: nil)
    }
    
    func connectTcp(host: String, port: String) {
        let msg = String(format: "Connecting to %@:%@...", host, port)
        SVProgressHUD.showWithStatus(msg, maskType: .Black)

        let tcpComm = TCPComm(msp: msp, host: host, port: Int(port))
        tcpComm.connect({ success in
            if success {
                self.initiateHandShake({
                    tcpComm.close()
                    SVProgressHUD.showErrorWithStatus("Handshake failed")
                })
            } else {
                SVProgressHUD.showErrorWithStatus("Connection failed")
            }
        })
        
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

class TCPTableViewCell : UITableViewCell {
    @IBOutlet weak var ipAddressField: UITextField!
    @IBOutlet weak var ipPortField: UITextField!
    
    var viewController: ConnectionViewController?
    
    @IBAction func connectAction(sender: AnyObject) {
        viewController!.connectTcp(ipAddressField.text!, port: ipPortField.text!)
    }
}
