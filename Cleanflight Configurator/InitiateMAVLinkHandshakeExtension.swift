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
    func initiateMAVLinkHandShake(callback: (success: Bool) -> Void) {
        dispatch_async(dispatch_get_main_queue(), {
            callback(success: true)
            SVProgressHUD.dismiss()
        })
    }
    
    
}