//
//  BaseConnectionViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 28/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import SVProgressHUD
import Firebase

extension UIViewController {

    func initiateHandShake(_ callback: @escaping (_ success: Bool) -> Void) {
        let msp = self.msp
        
        DispatchQueue.main.async {
            SVProgressHUD.setStatus("Fetching information...")
            
            resetAircraftModel()

            let config = Configuration.theConfig
            msp.sendMessage(.msp_API_VERSION, data: nil, retry: 4) { success in
                if success {
                    if !config.isApiVersionAtLeast("1.16") {
                        NSLog("Handshake: API version %@", config.apiVersion ?? "")
                        DispatchQueue.main.async {
                            callback(false)
                            SVProgressHUD.showError(withStatus: "This firmware version is not supported. Please upgrade", maskType: .none)
                            Analytics.logEvent("firmware_not_supported", parameters: ["apiVersion" : config.apiVersion!])
                        }
                    } else {
                        var msgs = [ MSP_code.msp_FC_VARIANT, .msp_BOXNAMES ]
                        chainMspCalls(msp, calls: msgs) { success in
                            if !success {
                                self.finishHandshake(false, callback: callback)
                            } else {
                                msgs = [ ]
                                if config.isApiVersionAtLeast("1.35") && !config.isINav {       // iNav 1.7.3 bumped api version to 2.0!
                                    msgs.append(.msp_BATTERY_CONFIG)
                                }
                                else {
                                    msgs.append(.msp_VOLTAGE_METER_CONFIG)
                                    msgs.append(.msp_CURRENT_METER_CONFIG)
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
        
    fileprivate func finishHandshake(_ success: Bool, callback: @escaping (_ success: Bool) -> Void) {
        DispatchQueue.main.async(execute: {
            if success {
                SVProgressHUD.dismiss()
                let config = Configuration.theConfig
                NSLog("Connected to FC %@ API version %@", config.fcIdentifier!, config.apiVersion!)
                Analytics.logEvent("finish_handshake", parameters: ["apiVersion" : config.apiVersion!, "fcIdentifier" : config.fcIdentifier!, "connectionType" : self.msp.isWifi ? "wifi" : "bt"])
                callback(true)
            } else {
                Analytics.logEvent("handshake_failed", parameters: nil)
                callback(false)
            }
        })
    }

}
