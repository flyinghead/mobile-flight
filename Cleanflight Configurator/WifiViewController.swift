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
        let tcpComm = TCPComm(host: host, port: port)
        if !tcpComm.reachable {
            let alertController = UIAlertController(title: nil, message: "You don't seem to be connected to the right Wi-Fi network", preferredStyle: UIAlertControllerStyle.ActionSheet)
            alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Try Anyway", style: UIAlertActionStyle.Default, handler: { alertController in
                self.doConnectTcp(tcpComm)
            }))
            alertController.addAction(UIAlertAction(title: "Open Settings", style: UIAlertActionStyle.Default, handler: { alertController in
                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            }))
            alertController.popoverPresentationController?.sourceView = (sender as! UIView)
            presentViewController(alertController, animated: true, completion: nil)
        } else {
            doConnectTcp(tcpComm)
        }
    }
    
    private func doConnectTcp(tcpComm: TCPComm) {
        let timeOutTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "connectionTimedOut:", userInfo: tcpComm, repeats: false)
        
        let protocolFinder = ProtocolFinder()
        protocolFinder.callback = { protocolHandler in
            dispatch_async(dispatch_get_main_queue(), {
                timeOutTimer.invalidate()
                SVProgressHUD.setStatus(protocolHandler is MAVLink ? "MAVLink detected" : "MSP detected")

                if protocolHandler is MSPParser {
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    appDelegate.msp = protocolHandler as! MSPParser
                    self.initiateHandShake({ success in
                        if success {
                            (self.parentViewController as! MainConnectionViewController).presentNextViewController()
                        } else {
                            protocolHandler.closeCommChannel()
                            SVProgressHUD.showErrorWithStatus("Handshake failed")
                        }
                    })
                } else {
                    self.initiateMAVLinkHandShake({ success in
                        if success {
                            (self.parentViewController as! MainConnectionViewController).presentNextViewController()
                        } else {
                            protocolHandler.closeCommChannel()
                            SVProgressHUD.showErrorWithStatus("Handshake failed")
                        }
                    })
                }
            })
        }

        let msg = String(format: "Connecting to %@:%d...", tcpComm.host, tcpComm.port)
        SVProgressHUD.showWithStatus(msg, maskType: .Black)
        
        tcpComm.connect({ success in
            if success {
                SVProgressHUD.setStatus("Connected...")
                tcpComm.protocolHandler = protocolFinder
                protocolFinder.recognizeProtocol(tcpComm)
            } else {
                SVProgressHUD.showErrorWithStatus("Connection failed")
            }
        })
    }
    
    func connectionTimedOut(timer: NSTimer) {
        let tcpComm = timer.userInfo as! TCPComm
        SVProgressHUD.showErrorWithStatus(!tcpComm.connected ? "Connection timeout" : "No data received")
        tcpComm.close()
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
