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

    //var restoredIpAddress = "192.168.4.1"
    //var restoredIpPort = "23"

    override func viewDidLoad() {
        super.viewDidLoad()

        connectButton.layer.borderColor = connectButton.tintColor.CGColor
        //ipAddressField.text = restoredIpAddress
        //ipPortField.text = restoredIpPort
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        let tcpComm = TCPComm(msp: msp, host: host, port: port)
        
        let msg = String(format: "Connecting to %@:%d...", host, port ?? -1)
        SVProgressHUD.showWithStatus(msg, maskType: .Black)
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(5) * NSEC_PER_SEC)), dispatch_get_main_queue() , {
            if !tcpComm.connected && !tcpComm.networkLost {
                SVProgressHUD.showErrorWithStatus("Connection time out")
                tcpComm.close()
            }
        })
        tcpComm.connect({ success in
            if success {
                self.initiateHandShake({ success in
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
