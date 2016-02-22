//
//  InitiateMAVLinkHandshakeExtension.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 21/02/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation
import SVProgressHUD

extension UIViewController {
    func initiateMAVLinkHandShake(mavlink: MAVLink, callback: (success: Bool) -> Void) {
        //let msp = self.msp
        
        dispatch_async(dispatch_get_main_queue(), {
            SVProgressHUD.setStatus("Fetching information...")
            
            resetAircraftModel()
            mavlink.requestMAVLinkRates()
            callback(success: true)
            SVProgressHUD.dismiss()
        })
    }
    
    
}