//
//  BluetoothViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 28/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
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

import UIKit
import SVProgressHUD

class BluetoothViewController: UITableViewController, BluetoothDelegate {

    var btPeripherals = [BluetoothPeripheral]()
    let btManager = BluetoothManager()
    var selectedPeripheral: BluetoothPeripheral?
    var refreshBluetoothButton: UIButton?

    var timeOutTimer: Timer?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        btManager.delegate = self
        refreshBluetooth()
    }

    func refreshBluetooth() {
        NSLog("Starting bluetooth scanning")
        btPeripherals.removeAll()
        tableView.reloadData()
        btManager.startScanning()
        refreshBluetoothButton?.isEnabled = false
    }
    
    fileprivate func cancelBtConnection(_ btComm: BluetoothComm) {
        btManager.delegate = self
        btComm.close()
        if selectedPeripheral != nil {
            selectedPeripheral = nil
            DispatchQueue.main.async(execute: {
                SVProgressHUD.showError(withStatus: "Handshake failed", maskType: .none)
            })
        }
    }
    
    func connectionTimedOut(_ timer: Timer) {
        if selectedPeripheral != nil {
            btManager.disconnect(selectedPeripheral!)
            DispatchQueue.main.async(execute: {
                SVProgressHUD.showError(withStatus: "Device is not responding", maskType: .none)
            })
        }
    }

    // MARK: BluetoothDelegate
    func foundPeripheral(_ peripheral: BluetoothPeripheral) {
        DispatchQueue.main.async(execute: {
            for p in self.btPeripherals {
                if peripheral.uuid == p.uuid {
                    // Already there
                    return
                }
            }
            self.btPeripherals.append(peripheral)
            self.tableView.reloadData()
        })
    }
    
    func stoppedScanning() {
        DispatchQueue.main.async(execute: {
            self.refreshBluetoothButton?.isEnabled = true
        })
    }
    
    func connectedPeripheral(_ peripheral: BluetoothPeripheral) {
        timeOutTimer?.invalidate()
        timeOutTimer = nil
        
        NSLog("Connected to %@", peripheral.name)
        
        let msp = self.msp
        let btComm = BluetoothComm(withBluetoothManager: btManager, andPeripheral: peripheral, andMSP: msp)
        btManager.delegate = btComm
        
        initiateHandShake({ success in
            if success {
                self.selectedPeripheral = nil
                DispatchQueue.main.async(execute: {
                    (self.parent as! MainConnectionViewController).presentNextViewController()
                })
            } else {
                self.cancelBtConnection(btComm)
            }
        })
    }
    
    func failedToConnectToPeripheral(_ peripheral: BluetoothPeripheral, error: Error?) {
        timeOutTimer?.invalidate()
        timeOutTimer = nil
        
        DispatchQueue.main.async(execute: {
            if error != nil {
                SVProgressHUD.showError(withStatus: String(format: "Connection to %@ failed: %@", peripheral.name, error!.localizedDescription), maskType: .none)
            } else {
                SVProgressHUD.showError(withStatus: String(format: "Connection to %@ failed", peripheral.name), maskType: .none)
            }
        })
    }
    
    func disconnectedPeripheral(_ peripheral: BluetoothPeripheral) {
        btManager.delegate = self
        if selectedPeripheral != nil {
            // Retry
            btManager.connect(selectedPeripheral!)
        }
    }
    
    func receivedData(_ peripheral: BluetoothPeripheral, data: [UInt8]) {
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? btPeripherals.count : 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Bluetooth Devices"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BluetoothCell", for: indexPath)
        
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = btPeripherals[indexPath.row].name
            cell.detailTextLabel?.text = btPeripherals[indexPath.row].uuid
        default:
            break
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case  0:
            selectedPeripheral = btPeripherals[indexPath.row]
            let msg = String(format: "Connecting to %@...", selectedPeripheral!.name)
            SVProgressHUD.show(withStatus: msg, maskType: .black)
            timeOutTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(BluetoothViewController.connectionTimedOut(_:)), userInfo: nil, repeats: false)
            btManager.connect(selectedPeripheral!)
            tableView.deselectRow(at: indexPath, animated: false)
            
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 44.0
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            let screenRect = UIScreen.main.applicationFrame;
            let view = UIView(frame: CGRect(x: 0, y: 0, width: screenRect.size.width, height: 44.0))
            view.autoresizesSubviews = true
            view.autoresizingMask = .flexibleWidth
            view.isUserInteractionEnabled = true
            
            view.contentMode = .scaleToFill
            
            if refreshBluetoothButton == nil {
                refreshBluetoothButton = UIButton(type: .system)
                refreshBluetoothButton!.addTarget(self, action: #selector(BluetoothViewController.refreshBluetooth), for: .touchDown)
                refreshBluetoothButton!.setTitle("Refresh", for: UIControlState())
                refreshBluetoothButton!.setTitle("Refreshing...", for: .disabled)
                refreshBluetoothButton!.frame = CGRect(x: 0.0, y: 0.0, width: screenRect.size.width, height: 44.0)
            }
            view.addSubview(refreshBluetoothButton!)
            
            return view
        } else {
            return nil
        }
    }
}
