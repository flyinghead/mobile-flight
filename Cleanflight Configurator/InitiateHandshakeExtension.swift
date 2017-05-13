//
//  BaseConnectionViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 28/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import SVProgressHUD

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
                        dispatch_async(dispatch_get_main_queue()) {
                            callback(success: false)
                            SVProgressHUD.showErrorWithStatus("This firmware version is not supported. Please upgrade", maskType: .None)
                        }
                    } else {
                        var msgs = [ MSP_code.MSP_FC_VARIANT, .MSP_BOXNAMES ]
                        if config.isApiVersionAtLeast("1.35") {
                            msgs.append(.MSP_BATTERY_CONFIG)
                        }
                        else {
                            msgs.append(.MSP_VOLTAGE_METER_CONFIG)
                            msgs.append(.MSP_CURRENT_METER_CONFIG)
                        }
                        chainMspCalls(msp, calls: msgs) { success in
                            self.finishHandshake(success, callback: callback)
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
                callback(success: true)
            } else {
                callback(success: false)
            }
        })
    }

}
