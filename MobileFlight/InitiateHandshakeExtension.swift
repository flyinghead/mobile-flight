//
//  BaseConnectionViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 28/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import SVProgressHUD
import Firebase

extension UIViewController {

    func initiateHandShake(callback: (success: Bool) -> Void) {
        let msp = self.msp
        
        dispatch_async(dispatch_get_main_queue()) {
            SVProgressHUD.setStatus("Fetching information...")
            
            resetAircraftModel()

            let config = Configuration.theConfig
            msp.sendMessage(.MSP_API_VERSION, data: nil, retry: 4) { success in
                if success {
                    if !config.isApiVersionAtLeast("1.16") {
                        NSLog("Handshake: API version %@", config.apiVersion ?? "")
                        dispatch_async(dispatch_get_main_queue()) {
                            callback(success: false)
                            SVProgressHUD.showErrorWithStatus("This firmware version is not supported. Please upgrade", maskType: .None)
                            Analytics.logEvent("firmware_not_supported", parameters: ["apiVersion" : config.apiVersion!])
                        }
                    } else {
                        var msgs = [ MSP_code.MSP_FC_VARIANT, .MSP_BOXNAMES ]
                        chainMspCalls(msp, calls: msgs) { success in
                            if !success {
                                self.finishHandshake(false, callback: callback)
                            } else {
                                msgs = [ ]
                                if config.isApiVersionAtLeast("1.35") && !config.isINav {       // iNav 1.7.3 bumped api version to 2.0!
                                    msgs.append(.MSP_BATTERY_CONFIG)
                                }
                                else {
                                    msgs.append(.MSP_VOLTAGE_METER_CONFIG)
                                    msgs.append(.MSP_CURRENT_METER_CONFIG)
                                }
                                chainMspCalls(msp, calls: msgs, ignoreFailure: true) { success in
                                    self.finishHandshake(true, callback: callback)
                                }
                            }
                        }
                    }
                } else {
                    self.finishHandshake(false, callback: callback)
                }
            }
        }
    }
        
    private func finishHandshake(success: Bool, callback: (success: Bool) -> Void) {
        dispatch_async(dispatch_get_main_queue(), {
            if success {
                SVProgressHUD.dismiss()
                let config = Configuration.theConfig
                NSLog("Connected to FC %@ API version %@", config.fcIdentifier!, config.apiVersion!)
                Analytics.logEvent("finish_handshake", parameters: ["apiVersion" : config.apiVersion!, "fcIdentifier" : config.fcIdentifier!, "connectionType" : self.msp.isWifi ? "wifi" : "bt"])
                callback(success: true)
            } else {
                Analytics.logEvent("handshake_failed", parameters: nil)
                callback(success: false)
            }
        })
    }

}
