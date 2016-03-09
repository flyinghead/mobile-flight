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
            msp.sendMessage(.MSP_IDENT, data: nil, retry: 4, callback: { success in
                if success {
                    msp.sendMessage(.MSP_API_VERSION, data: nil, retry: 4, callback: { success in
                        if success {
                            if !Configuration.theConfig.isApiVersionAtLeast("1.7") {
                                dispatch_async(dispatch_get_main_queue(), {
                                    callback(success: false)
                                    SVProgressHUD.showErrorWithStatus("This version of the API is not supported", maskType: .None)
                                })
                            } else {
                                msp.sendMessage(.MSP_UID, data: nil, retry: 4, callback: { success in
                                    if success {
                                        msp.sendMessage(.MSP_BOXNAMES, data: nil, retry: 4, callback: { success in
                                            if success {
                                                msp.sendMessage(.MSP_BF_CONFIG, data: nil, retry: 4, callback: { success in
                                                    if success {
                                                        self.msp.sendMessage(.MSP_MISC, data: nil, retry: 4, callback: { success in
                                                            if success {
                                                                dispatch_async(dispatch_get_main_queue(), {
                                                                    SVProgressHUD.dismiss()
                                                                    callback(success: true)
                                                                })
                                                            } else {
                                                                callback(success: false)
                                                            }
                                                        })
                                                    } else {
                                                        callback(success: false)
                                                    }
                                                })
                                            } else {
                                                callback(success: false)
                                            }
                                        })
                                    } else {
                                        callback(success: false)
                                    }
                                })
                            }
                        } else {
                            callback(success: false)
                        }
                    })
                } else {
                    callback(success: false)
                }
            })
        })
    }

}
