//
//  WifiViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 27/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import SVProgressHUD

class WifiViewController: UIViewController {
    @IBOutlet weak var ipAddressField: UITextField!
    @IBOutlet weak var ipPortField: UITextField!
    @IBOutlet weak var connectButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        connectButton.layer.borderColor = connectButton.tintColor.CGColor
    }

    @IBAction func connectAction(sender: AnyObject) {
        let host = ipAddressField.text!
        if host.isEmpty {
            return
        }
        let port = Int(ipPortField.text!)
        let tcpComm = TCPComm(msp: msp, host: host, port: port)
        if !tcpComm.reachable {
            let alertController = UIAlertController(title: nil, message: "You don't seem to be connected to the right Wi-Fi network", preferredStyle: UIAlertControllerStyle.ActionSheet)
            alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Try Anyway", style: UIAlertActionStyle.Default, handler: { alertController in
                self.doConnectTcp(host, port: port)
            }))
            alertController.addAction(UIAlertAction(title: "Open Settings", style: UIAlertActionStyle.Default, handler: { alertController in
                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            }))
            alertController.popoverPresentationController?.sourceView = (sender as! UIView)
            presentViewController(alertController, animated: true, completion: nil)
        } else {
            doConnectTcp(host, port: port)
        }
    }
    
    private func doConnectTcp(host: String, port: Int?) {
        let mavlink = MAVLink()
        let tcpComm = TCPComm(msp: mavlink, host: host, port: port)
        
        let msg = String(format: "Connecting to %@:%d...", host, port ?? -1)
        SVProgressHUD.showWithStatus(msg, maskType: .Black)
        
        let timeOutTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "connectionTimedOut:", userInfo: tcpComm, repeats: false)

        tcpComm.connect({ success in
            timeOutTimer.invalidate()
            if success {
                self.initiateMAVLinkHandShake(mavlink, callback: { success in
                    if success {
                        (self.parentViewController as! MainConnectionViewController).presentNextViewController()
                    } else {
                        tcpComm.close()
                        SVProgressHUD.showErrorWithStatus("Handshake failed")
                    }
                })
            } else {
                SVProgressHUD.showErrorWithStatus("Connection failed")
            }
        })
    }
    
    func connectionTimedOut(timer: NSTimer) {
        let tcpComm = timer.userInfo as! TCPComm
        if !tcpComm.connected {
            SVProgressHUD.showErrorWithStatus("Connection timeout")
            tcpComm.close()
        }
    }

    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        coder.encodeObject(ipAddressField?.text, forKey: "IpAddress")
        coder.encodeObject(ipPortField?.text, forKey: "IpPort")
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        super.decodeRestorableStateWithCoder(coder)
        ipAddressField?.text = coder.decodeObjectForKey("IpAddress") as? String ?? "192.168.4.1"
        ipPortField?.text = coder.decodeObjectForKey("IpPort") as? String ?? "23"
    }
}
