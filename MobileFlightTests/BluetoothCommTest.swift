//
//  BluetoothCommTest.swift
//  MobileFlight
//
//  Created by Raphael Jean-Leconte on 01/08/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
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
