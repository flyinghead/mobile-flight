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
    static let HM10ServiceUUID = "FFE0"
    static let HM10CharacteristicUUID = "FFE1"
    // Red Bear Lab BLEMini
    static let RBLServiceUUID = "713D0000-503E-4C75-BA94-3148F18D941E"
    static let RBLCharTxUUID = "713D0002-503E-4C75-BA94-3148F18D941E"
    static let RBLCharRxUUID = "713D0003-503E-4C75-BA94-3148F18D941E"
    // Amp'ed RF BT43H (TBS Crossfire TX). This is a commonly used service so some unexpected devices may be discovered
    static let BT43ServiceUUID = "180F"         // Battery Service
    static let BT43CharacteristicUUID = "2A19"  // Battery Level
    
    let serviceUUIDs = [CBUUID(string: HM10ServiceUUID), CBUUID(string: RBLServiceUUID), CBUUID(string: BT43ServiceUUID)]
    let characteristicUUIDs = [CBUUID(string: HM10CharacteristicUUID), CBUUID(string: RBLCharTxUUID), CBUUID(string: RBLCharRxUUID), CBUUID(string: BT43CharacteristicUUID)]
    
    let btQueue: dispatch_queue_t
    let manager: CBCentralManager
    var peripherals = [CBPeripheral]()
    var activePeripheral: CBPeripheral?
    
    var scanningRequested = false
    var scanningDuration = 5.0
    
    var delegate: BluetoothDelegate?
    
    override init() {
        btQueue = dispatch_queue_create("cleanflightBluetoothQueue", DISPATCH_QUEUE_SERIAL)
        manager = CBCentralManager(delegate: nil, queue: btQueue, options: [CBCentralManagerOptionShowPowerAlertKey : NSNumber(integer: 1)])
        super.init()
        manager.delegate = self
    }
    
    func startScanning(duration: Double  = 5.0) {
        scanningRequested = true
        scanningDuration = duration
        if (manager.centralManagerState != CBCentralManagerState.PoweredOn) {
            NSLog("CoreBluetooth powered off")
            return
        }
        startScanningIfNeeded()
    }
    
    private func startScanningIfNeeded() {
        if (scanningRequested) {
            scanningRequested = false
            NSTimer.scheduledTimerWithTimeInterval(scanningDuration, target:self, selector:"scanTimer", userInfo: nil, repeats: false)
            
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
        if (central.centralManagerState == CBCentralManagerState.PoweredOn) {
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
            for service in peripheral.services! {
                peripheral.discoverCharacteristics(characteristicUUIDs, forService: service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if error == nil {
            NSLog("Discovered characteristics for service %@", service.UUID.UUIDString)
            var characteristic: CBCharacteristic!
            if service.UUID.UUIDString == BluetoothManager.RBLServiceUUID {
                for char in service.characteristics! {
                    if char.UUID.UUIDString == BluetoothManager.RBLCharTxUUID {
                        characteristic = char
                    }
                }
            } else {
                guard let characteristics = service.characteristics where !characteristics.isEmpty else {
                    return
                }
                characteristic = characteristics[0]
            }
            peripheral.setNotifyValue(true, forCharacteristic: characteristic)
        } else {
            NSLog("Error discovering characteristics for service %@: %@", service.UUID.UUIDString, error!)
            activePeripheral = nil
            manager.cancelPeripheralConnection(peripheral)
            delegate?.failedToConnectToPeripheral(BluetoothPeripheral(peripheral), error: error)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error == nil {
            delegate?.connectedPeripheral(BluetoothPeripheral(peripheral))
        } else {
            NSLog("didUpdateNotificationStateForCharacteristic %@: %@", characteristic.UUID.UUIDString, error!)
            activePeripheral = nil
            manager.cancelPeripheralConnection(peripheral)
            delegate?.failedToConnectToPeripheral(BluetoothPeripheral(peripheral), error: error)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error == nil {
            //NSLog("didUpdateValueForCharacteristic %@", characteristic.value!)
            let nsdata = characteristic.value!
            var data = [UInt8](count: nsdata.length, repeatedValue: 0)
            nsdata.getBytes(&data, length:nsdata.length)

            //NSLog("Read %@", beautifyData(data))
            delegate?.receivedData(BluetoothPeripheral(peripheral), data: data)
        } else {
            NSLog("Error updating value for characteristic: %@", error!)
        }
    }

    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            NSLog("Error writing value for characteristic: %@", error!)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        //NSLog("BT RSSI=%@", RSSI)       // -104 -> -26 ?
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.msp.setRssi(RSSI.doubleValue)
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
        guard let services = activePeripheral!.services where !services.isEmpty else {
            return
        }
        let service = services[0]
        if service.characteristics == nil || service.characteristics!.isEmpty {
            return
        }
        var characteristic: CBCharacteristic!
        if service.UUID.UUIDString == BluetoothManager.RBLServiceUUID {
            for char in service.characteristics! {
                if char.UUID.UUIDString == BluetoothManager.RBLCharRxUUID {
                    characteristic = char
                    break
                }
            }
        } else {
            characteristic = service.characteristics![0]
        }
        if characteristic == nil {
            return
        }
        
        //NSLog("Writing %@", beautifyData(data))
        let nsdata = NSData(bytes: data, length: data.count)
        for (var i = 0; i < nsdata.length; i += 20) {
            let datarange = nsdata.subdataWithRange(NSRange(location: i, length: min(nsdata.length - i, 20)))
            if characteristic.properties.contains(.WriteWithoutResponse) {
                activePeripheral!.writeValue(datarange, forCharacteristic: characteristic, type: .WithoutResponse)
            } else {
                activePeripheral!.writeValue(datarange, forCharacteristic: characteristic, type: .WithResponse)
            }
        }
    }
    
    private func beautifyData(data: [UInt8]) -> String {
        var string = ""
        for var c in data {
            if c >= 32 && c < 128 {
                string += NSString(bytes: &c, length: 1, encoding: NSASCIIStringEncoding)! as String
            } else {
                string += String(format: "'%d'", c)
            }
            string += " "
        }
        return string
    }
    
    func readRssi(peripheral: BluetoothPeripheral) {
        for p in peripherals {
            if peripheral.uuid == p.identifier.UUIDString {
                p.readRSSI()
                return
            }
        }
    }
}

extension CBCentralManager {
    internal var centralManagerState: CBCentralManagerState  {
        get {
            return CBCentralManagerState(rawValue: state.rawValue) ?? .Unknown
        }
    }
}
