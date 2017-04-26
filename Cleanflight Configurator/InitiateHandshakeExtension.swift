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
        
        dispatch_async(dispatch_get_main_queue(), {
            SVProgressHUD.setStatus("Fetching information...")
            
            resetAircraftModel()
            msp.sendMessage(.MSP_API_VERSION, data: nil, retry: 4, callback: { success in
                if success {
                    if !Configuration.theConfig.isApiVersionAtLeast("1.16") {
                        dispatch_async(dispatch_get_main_queue(), {
                            callback(success: false)
                            SVProgressHUD.showErrorWithStatus("This firmware version is not supported. Please upgrade", maskType: .None)
                        })
                    } else {
                        msp.sendMessage(.MSP_FC_VARIANT, data: nil, retry: 4, callback: { success in
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
                                msp.sendMessage(.MSP_BOXNAMES, data: nil, retry: 4, callback: { success in
                                    dispatch_async(dispatch_get_main_queue(), {
                                        if success {
                                            SVProgressHUD.dismiss()
                                            callback(success: true)
                                        } else {
                                            callback(success: false)
                                        }
                                    })
                                })
                            } else {
                                dispatch_async(dispatch_get_main_queue(), {
                                    callback(success: false)
                                })
                            }
                        })
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        callback(success: false)
                    })
                }
            })
        })
    }

}
