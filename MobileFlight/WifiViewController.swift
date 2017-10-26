//
//  WifiViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 27/12/15.
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

class WifiViewController: UIViewController {
    @IBOutlet weak var ipAddressField: UITextField!
    @IBOutlet weak var ipPortField: UITextField!
    @IBOutlet weak var connectButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        connectButton.layer.borderColor = connectButton.tintColor.cgColor
    }

    @IBAction func connectAction(_ sender: Any) {
        let host = ipAddressField.text!
        if host.isEmpty {
            return
        }
        let port = Int(ipPortField.text!)
        let socketComm = AsyncSocketComm(msp: msp, host: host, port: port)
        if !socketComm.reachable {
            let alertController = UIAlertController(title: nil, message: "You don't seem to be connected to the right Wi-Fi network", preferredStyle: UIAlertControllerStyle.actionSheet)
            alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Try Anyway", style: UIAlertActionStyle.default, handler: { alertController in
                self.doConnectTcp(host, port: port)
            }))
            alertController.addAction(UIAlertAction(title: "Open Settings", style: UIAlertActionStyle.default, handler: { alertController in
                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            }))
            alertController.popoverPresentationController?.sourceView = (sender as! UIView)
            present(alertController, animated: true, completion: nil)
        } else {
            doConnectTcp(host, port: port)
        }
    }
    
    fileprivate func doConnectTcp(_ host: String, port: Int?) {
        let socketComm = AsyncSocketComm(msp: msp, host: host, port: port)
        
        let msg = String(format: "Connecting to %@:%d...", host, port ?? -1)
        SVProgressHUD.show(withStatus: msg, maskType: .black)
        
        let timeOutTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(WifiViewController.connectionTimedOut(_:)), userInfo: socketComm, repeats: false)

        socketComm.connect({ success in
            timeOutTimer.invalidate()
            if success {
                self.initiateHandShake({ success in
                    if success {
                        (self.parent as! MainConnectionViewController).presentNextViewController()
                    } else {
                        self.msp.closeCommChannel()
                        SVProgressHUD.showError(withStatus: "Handshake failed")
                    }
                })
            } else {
                SVProgressHUD.showError(withStatus: "Connection failed")
            }
        })
    }
    
    func connectionTimedOut(_ timer: Timer) {
        let socketComm = timer.userInfo as! AsyncSocketComm
        if !socketComm.connected {
            SVProgressHUD.showError(withStatus: "Connection timeout")
            socketComm.close()
        }
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(ipAddressField?.text, forKey: "IpAddress")
        coder.encode(ipPortField?.text, forKey: "IpPort")
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        ipAddressField?.text = coder.decodeObject(forKey: "IpAddress") as? String ?? "192.168.4.1"
        ipPortField?.text = coder.decodeObject(forKey: "IpPort") as? String ?? "23"
    }
}
