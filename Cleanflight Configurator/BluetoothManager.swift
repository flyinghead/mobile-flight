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
    // HM-10,11... series
    let HM10ServiceUUID = "FFE0"
    let HM10CharacteristicUUID = "FFE1"
    // Red Bear Lab BLEMini
    let RBLServiceUUID = "713D0000-503E-4C75-BA94-3148F18D941E"
    let RBLCharTxUUID = "713D0002-503E-4C75-BA94-3148F18D941E"
    let RBLCharRxUUID = "713D0003-503E-4C75-BA94-3148F18D941E"
    
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
            
            let serviceUUIDs = [CBUUID(string: HM10ServiceUUID), CBUUID(string: RBLServiceUUID)]
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
        
        let serviceUUIDs = [CBUUID(string: HM10ServiceUUID), CBUUID(string: RBLServiceUUID)]
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
            let characteristicUUIDs = [CBUUID(string: HM10CharacteristicUUID), CBUUID(string: RBLCharTxUUID), CBUUID(string: RBLCharRxUUID)]
            peripheral.discoverCharacteristics(characteristicUUIDs, forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if error == nil {
            NSLog("Discovered characteristics for service %@", service.UUID.UUIDString)
            var characteristic: CBCharacteristic!
            if service.UUID.UUIDString == RBLServiceUUID {
                for char in service.characteristics! {
                    if char.UUID.UUIDString == RBLCharTxUUID {
                        characteristic = char
                    }
                }
            } else {
                characteristic = service.characteristics![0]
            }
            peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            delegate?.connectedPeripheral(BluetoothPeripheral(peripheral))
        } else {
            NSLog("Error discovering characteristics for service %@: %@", service.UUID.UUIDString, error!)
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
        } else {
            NSLog("Error updating value for characteristic: %@", error!)
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
        delegate?.failedToConnectToPeripheral(peripheral, error: NSError(domain: "com.flyinghead", code: 1, userInfo: [NSLocalizedDescriptionKey : "Device cannot be found"]))
    }
    
    func disconnect(peripheral: BluetoothPeripheral) {
        for p in peripherals {
            if (peripheral.uuid == p.identifier.UUIDString && (p.state == .Connected || p.state == .Connecting)) {
                manager.cancelPeripheralConnection(p)
                return
            }
        }
        delegate?.disconnectedPeripheral(peripheral)
    }
    
    func writeData(peripheral: BluetoothPeripheral, data: [UInt8]) {
        if (peripheral.uuid != activePeripheral?.identifier.UUIDString) {
            return
        }
        if (activePeripheral!.services == nil || activePeripheral!.services?.count == 0 || activePeripheral?.services![0].characteristics == nil || activePeripheral?.services![0].characteristics?.count == 0) {
            return
        }
        let service = activePeripheral!.services![0]
        var characteristic: CBCharacteristic!
        if service.UUID.UUIDString == RBLServiceUUID {
            for char in service.characteristics! {
                if char.UUID.UUIDString == RBLCharRxUUID {
                    characteristic = char
                    break
                }
            }
        } else {
            characteristic = activePeripheral!.services![0].characteristics![0]
        }
        if characteristic == nil {
            return
        }
        
        let nsdata = NSData(bytes: data, length: data.count)
        for (var i = 0; i < nsdata.length; i += 20) {
            let datarange = nsdata.subdataWithRange(NSRange(location: i, length: min(nsdata.length - i, 20)))
            activePeripheral!.writeValue(datarange, forCharacteristic: characteristic, type: .WithoutResponse)
        }
    }
}