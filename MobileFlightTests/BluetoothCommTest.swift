//
//  BluetoothCommTest.swift
//  MobileFlight
//
//  Created by Raphael Jean-Leconte on 01/08/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import XCTest
@testable import MobileFlight

class BluetoothCommTest: XCTestCase, BluetoothDelegate {
    let btManager = BluetoothManager()
    var foundDeviceExpect: XCTestExpectation!
    var device: BluetoothPeripheral!
    var comm: BluetoothComm!

    override func setUp() {
        super.setUp()
        foundDeviceExpect = expectationWithDescription("FoundBluetoothDevice")
        btManager.delegate = self
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func foundPeripheral(peripheral: BluetoothPeripheral) {
        device = peripheral
        btManager.connect(peripheral)
    }
    
    func stoppedScanning() {
        
    }
    
    func connectedPeripheral(peripheral: BluetoothPeripheral) {
        let msp = (UIApplication.sharedApplication().delegate as! AppDelegate).msp
        comm = BluetoothComm(withBluetoothManager: btManager, andPeripheral: peripheral, andMSP: msp)
        btManager.delegate = comm
        
        msp.sendMessage(.MSP_FILTER_CONFIG, data: nil, retry: 0, flush: true) { success in
            if !success {
                XCTFail("send MSP_FILTER_CONFIG failed")
            } else {
                self.sendMessage()
            }
        }
    }
    
    func failedToConnectToPeripheral(peripheral: BluetoothPeripheral, error: NSError?) {
        
    }
    func disconnectedPeripheral(peripheral: BluetoothPeripheral) {
        
    }
    func receivedData(peripheral: BluetoothPeripheral, data: [UInt8]) {
    }

    func sendMessage() {
        let msp = (UIApplication.sharedApplication().delegate as! AppDelegate).msp
        msp.sendFilterConfig(Settings.theSettings) { success in
            if !success {
                XCTFail("send MSP_SET_FILTER_CONFIG failed")
            } else {
                self.sendMessage()
            }
        }
    }

    func testBluetooth() {
        
        
        btManager.startScanning()
        waitForExpectationsWithTimeout(60) { error in
            if error != nil {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    

}
