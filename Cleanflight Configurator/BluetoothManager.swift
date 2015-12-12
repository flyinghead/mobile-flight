//
//  BluetoothScanner.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 09/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - BluetoothDelegate
protocol BluetoothDelegate : class {
    func foundPeripheral(peripheral: BluetoothPeripheral)
    func stoppedScanning()
    func connectedPeripheral(peripheral: BluetoothPeripheral)
    func failedToConnectToPeripheral(peripheral: BluetoothPeripheral, error: NSError?)
    func disconnectedPeripheral(peripheral: BluetoothPeripheral)
    func receivedData(peripheral: BluetoothPeripheral, data: [UInt8])
}

struct BluetoothPeripheral {
    let name: String
    let uuid: String
    
    init(_ peripheral: CBPeripheral) {
        self.name = peripheral.name!
        self.uuid = peripheral.identifier.UUIDString
    }
}

class BluetoothManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    let ServiceUUID = 0xFFE0
    let CharacteristicUUID = 0xFFE1
    
    let btQueue: dispatch_queue_t
    let manager: CBCentralManager
    var peripherals = [CBPeripheral]()
    var activePeripheral: CBPeripheral?
    
    var scanningRequested = false
    var scanningDuration = 5.0
    
    var delegate: BluetoothDelegate?
    
    override init() {
        btQueue = dispatch_queue_create("cleanflightBluetoothQueue", DISPATCH_QUEUE_CONCURRENT)
        manager = CBCentralManager(delegate: nil, queue: btQueue, options: [CBCentralManagerOptionShowPowerAlertKey : NSNumber(integer: 1)])
        super.init()
        manager.delegate = self
    }
    
    func startScanning(duration: Double  = 5.0) {
        scanningRequested = true
        scanningDuration = duration
        if (manager.state != CBCentralManagerState.PoweredOn) {
            NSLog("CoreBluetooth powered off")
            return
        }
        startScanningIfNeeded()
    }
    private func startScanningIfNeeded() {
        if (scanningRequested) {
            scanningRequested = false
            NSTimer.scheduledTimerWithTimeInterval(scanningDuration, target:self, selector:"scanTimer", userInfo: nil, repeats: false)
            
            let serviceUUID = String(format: "%04x", ServiceUUID)
            let serviceUUIDs = [CBUUID(string: serviceUUID)]
            manager.scanForPeripheralsWithServices(serviceUUIDs, options: nil)
        }
    }
    
    func scanTimer() {
        manager.stopScan()
        delegate?.stoppedScanning()
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        NSLog("centralManagerDidUpdateState: %d", central.state.rawValue)
        if (central.state == CBCentralManagerState.PoweredOn) {
            startScanningIfNeeded()
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        NSLog("Found device")
        if (peripheral.name == nil) {
            NSLog("Device has nil name, ignored")
            return
        }
        for (i, p) in peripherals.enumerate() {
            if p.identifier.UUIDString == peripheral.identifier.UUIDString {
                NSLog("Existing device replaced: " + p.identifier.UUIDString)
                peripherals[i] = peripheral
                delegate?.foundPeripheral(BluetoothPeripheral(peripheral))
                
                return
            }
        }
        NSLog("New device %@ (%@)", peripheral.name!, peripheral.identifier.UUIDString)
        peripherals.append(peripheral)
        delegate?.foundPeripheral(BluetoothPeripheral(peripheral))
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        activePeripheral = peripheral
        activePeripheral?.delegate = self
        
        let serviceUUID = String(format: "%04x", ServiceUUID)
        let serviceUUIDs = [CBUUID(string: serviceUUID)]
        activePeripheral?.discoverServices(serviceUUIDs)
        
        NSLog("Connected to device %@", peripheral.name!)
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        NSLog("Disconnected from device %@", peripheral.name!)
        if (peripheral === activePeripheral) {
            activePeripheral = nil
            delegate?.disconnectedPeripheral(BluetoothPeripheral(peripheral))
        }
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        NSLog("Connection to device %@ failed: %@", peripheral.name!, error!)
        delegate?.failedToConnectToPeripheral(BluetoothPeripheral(peripheral), error: error)
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if (error != nil) {
            NSLog("Discover services for device %@ failed: %@", peripheral.name!, error!)
            activePeripheral = nil
            manager.cancelPeripheralConnection(peripheral)
            delegate?.failedToConnectToPeripheral(BluetoothPeripheral(peripheral), error: error)
        } else {
            NSLog("Discover services for device %@ succeeded: %d services", peripheral.name!, peripheral.services!.count)
            let service = peripheral.services![0]
            NSLog("Discovering characteristics for service %@", service.UUID.UUIDString)
            let characteristicUUID = String(format: "%04x", CharacteristicUUID)
            let characteristicUUIDs = [CBUUID(string: characteristicUUID)]
            peripheral.discoverCharacteristics(characteristicUUIDs, forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if error == nil {
            NSLog("Discovered characteristics for service %@", service.UUID.UUIDString)
            notifyReceivedData(peripheral, enabled: true)
            delegate?.connectedPeripheral(BluetoothPeripheral(peripheral))
        } else {
            NSLog("Error discovering characteristics for service %@: ", service.UUID.UUIDString, error!)
            activePeripheral = nil
            manager.cancelPeripheralConnection(peripheral)
            delegate?.failedToConnectToPeripheral(BluetoothPeripheral(peripheral), error: error)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error == nil {
            //NSLog("Received %@", characteristic.value!)
            let nsdata = characteristic.value!
            var data = [UInt8](count: nsdata.length, repeatedValue: 0)
            nsdata.getBytes(&data, length:nsdata.length)

            delegate?.receivedData(BluetoothPeripheral(peripheral), data: data)
        }
    }
    // MARK:
    
    func connect(peripheral: BluetoothPeripheral) {
        for p in peripherals {
            if (peripheral.uuid == p.identifier.UUIDString && p.state != .Connected && p.state != .Connecting) {
                manager.connectPeripheral(p, options: nil)
                return
            }
        }
    }
    
    func disconnect(peripheral: BluetoothPeripheral) {
        if (peripheral.uuid == activePeripheral?.identifier.UUIDString && (activePeripheral!.state == .Connected || activePeripheral!.state == .Connecting)) {
            manager.cancelPeripheralConnection(activePeripheral!)
        }
    }
    
    func writeData(peripheral: BluetoothPeripheral, data: [UInt8]) {
        if (peripheral.uuid != activePeripheral?.identifier.UUIDString) {
            return
        }
        if (activePeripheral!.services == nil || activePeripheral!.services?.count == 0 || activePeripheral?.services![0].characteristics == nil || activePeripheral?.services![0].characteristics?.count == 0) {
            return
        }
        let nsdata = NSData(bytes: data, length: data.count)
        let characteristic = activePeripheral!.services![0].characteristics![0]
        for (var i = 0; i < nsdata.length; i += 20) {
            let datarange = nsdata.subdataWithRange(NSRange(location: i, length: min(nsdata.length - i, 20)))
            if characteristic.properties.contains(.WriteWithoutResponse) {
                activePeripheral!.writeValue(datarange, forCharacteristic: characteristic, type: .WithoutResponse)
            } else {
                activePeripheral!.writeValue(datarange, forCharacteristic: characteristic, type: .WithResponse)
            }
        }
    }
    
    func notifyReceivedData(peripheral: CBPeripheral, enabled: Bool) {
        let characteristic = peripheral.services![0].characteristics![0]
        peripheral.setNotifyValue(enabled, forCharacteristic: characteristic)
    }
}