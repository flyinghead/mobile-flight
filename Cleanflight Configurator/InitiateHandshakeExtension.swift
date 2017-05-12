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
                        msp.sendMessage(.MSP_FC_VARIANT, data: nil, retry: 4) { success in
                            if success {
                                /*
                                 if Configuration.theConfig.fcIdentifier == "RCFL" {
                                 dispatch_async(dispatch_get_main_queue(), {
                                 callback(success: false)
                                 SVProgressHUD.showErrorWithStatus("This firmware violates GPL licensing requirements and is not supported", maskType: .None)
                                 })
                                 return
                                 }
                                 */
                                msp.sendMessage(.MSP_BOXNAMES, data: nil, retry: 4) { success in
                                    if success {
                                        let finishCallback: ((success: Bool) -> Void) = { success in
                                            self.finishHandshake(success, callback: callback)
                                        }
                                        if config.isApiVersionAtLeast("1.35") {
                                            msp.sendMessage(.MSP_BATTERY_CONFIG, data: nil, retry: 2, callback: finishCallback)
                                        }
                                        else {
                                            msp.sendMessage(.MSP_VOLTAGE_METER_CONFIG, data: nil, retry: 2, callback: finishCallback)
                                        }
                                    } else {
                                        self.finishHandshake(false, callback: callback)
                                    }
                                }
                            } else {
                                self.finishHandshake(false, callback: callback)
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
                callback(success: true)
            } else {
                callback(success: false)
            }
        })
    }

}
