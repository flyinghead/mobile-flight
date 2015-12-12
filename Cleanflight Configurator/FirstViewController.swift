//
//  FirstViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController, FlightDataListener, BluetoothDelegate {

    var tcpComm: TCPComm?
    var btManager: BluetoothManager?
    var btComm: BluetoothComm?
    
    @IBOutlet weak var version: UILabel!
    @IBOutlet weak var multiType: UILabel!
    @IBOutlet weak var mspVersion: UILabel!
    @IBOutlet weak var fcIdentifier: UILabel!
    @IBOutlet weak var fcVersion: UILabel!
    @IBOutlet weak var apiVersion: UILabel!
    @IBOutlet weak var msgProtocol: UILabel!
    @IBOutlet weak var buildInfo: UILabel!
    @IBOutlet weak var boardInfo: UILabel!
    @IBOutlet weak var boardVersion: UILabel!
    @IBOutlet weak var UID: UILabel!
    
    @IBAction func onConnect(sender: AnyObject) {
        /*
        if (tcpComm != nil) {
            tcpComm!.close();
        }
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        tcpComm = TCPComm(msp: appDelegate.msp);
        tcpComm!.connect();
        tcpComm!.msp.sendMessage(.MSP_IDENT, data: nil)
        tcpComm!.msp.sendMessage(.MSP_API_VERSION, data: nil)
        tcpComm!.msp.sendMessage(.MSP_FC_VARIANT, data: nil)
        tcpComm!.msp.sendMessage(.MSP_FC_VERSION, data: nil)
        tcpComm!.msp.sendMessage(.MSP_BUILD_INFO, data: nil)
        tcpComm!.msp.sendMessage(.MSP_BOARD_INFO, data: nil)
        tcpComm!.msp.sendMessage(.MSP_UID, data: nil)
        //tcpComm?.sendIfAvailable()
*/
        if (btManager == nil) {
            btManager = BluetoothManager()
            btManager?.delegate = self
        }
        btManager!.startScanning()
    }
    
    // MARK: BluetoothDelegate
    func foundPeripheral(peripheral: BluetoothPeripheral) {
        btManager?.connect(peripheral)
    }
    
    func stoppedScanning() {
    }
    
    func connectedPeripheral(peripheral: BluetoothPeripheral) {
        NSLog("Connected to %@", peripheral.name)
        
        btComm = BluetoothComm(withBluetoothManager: btManager!, andPeripheral: peripheral, andMSP: msp)
        btManager!.delegate = btComm
        
        msp.sendMessage(.MSP_IDENT, data: nil)
        msp.sendMessage(.MSP_API_VERSION, data: nil)
        msp.sendMessage(.MSP_FC_VARIANT, data: nil)
        msp.sendMessage(.MSP_FC_VERSION, data: nil)
        msp.sendMessage(.MSP_BUILD_INFO, data: nil)
        msp.sendMessage(.MSP_BOARD_INFO, data: nil)
        msp.sendMessage(.MSP_UID, data: nil)
    }
    func failedToConnectToPeripheral(peripheral: BluetoothPeripheral, error: NSError?) {
        
    }
    
    func disconnectedPeripheral(peripheral: BluetoothPeripheral) {
        
    }

    func receivedData(peripheral: BluetoothPeripheral, data: [UInt8]) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        msp.addDataListener(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func receivedData() {
        let config = Configuration.theConfig
        
        version.text = config.version;
        if (config.multiType != nil) {
            multiType.text = String(format: "%d", config.multiType!)
        } else {
            multiType.text = ""
        }
        if (config.mspVersion != nil) {
            mspVersion.text = String(format: "%d", config.mspVersion!)
        } else {
            mspVersion.text = ""
        }
        apiVersion.text = config.apiVersion
        fcIdentifier.text = config.fcIdentifier
        fcVersion.text = config.fcVersion
        if (config.msgProtocolVersion != nil) {
            msgProtocol.text = String(format: "%d", config.msgProtocolVersion!)
        } else {
            msgProtocol.text = ""
        }
        buildInfo.text = config.buildInfo
        boardInfo.text = config.boardInfo
        if (config.boardVersion != nil) {
            boardVersion.text = String(format: "%d", config.boardVersion!)
        } else {
            boardVersion.text = ""
        }
        UID.text = config.uid ?? ""
        
        self.view.setNeedsDisplay();
    }


}

