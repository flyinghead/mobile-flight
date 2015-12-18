//
//  PIDViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 15/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import DownPicker
import SVProgressHUD

class PIDViewController: UITableViewController {
    @IBOutlet weak var profileField: UITextField!
    @IBOutlet weak var pidControllerField: UITextField!
    var profilePicker: MyDownPicker?
    var pidControllerPicker: MyDownPicker?
    
    // BASIC
    @IBOutlet weak var rollP: NumberField!
    @IBOutlet weak var rollI: NumberField!
    @IBOutlet weak var rollD: NumberField!
    @IBOutlet weak var pitchP: NumberField!
    @IBOutlet weak var pitchI: NumberField!
    @IBOutlet weak var pitchD: NumberField!
    @IBOutlet weak var yawP: NumberField!
    @IBOutlet weak var yawI: NumberField!
    @IBOutlet weak var yawD: NumberField!
    // ALT
    @IBOutlet weak var altP: NumberField!
    @IBOutlet weak var altI: NumberField!
    @IBOutlet weak var altD: NumberField!
    @IBOutlet weak var varioP: NumberField!
    @IBOutlet weak var varioI: NumberField!
    @IBOutlet weak var varioD: NumberField!
    // MAG
    @IBOutlet weak var magP: NumberField!
    //GPS
    @IBOutlet weak var posP: NumberField!
    @IBOutlet weak var posI: NumberField!
    @IBOutlet weak var posRP: NumberField!
    @IBOutlet weak var posRI: NumberField!
    @IBOutlet weak var posRD: NumberField!
    @IBOutlet weak var navRP: NumberField!
    @IBOutlet weak var navRI: NumberField!
    @IBOutlet weak var navRD: NumberField!
    // ANGLE/HORIZON
    @IBOutlet weak var angleLevel: NumberField!
    @IBOutlet weak var horizonLevel: NumberField!
    @IBOutlet weak var horizonTransition: NumberField!
    // RC RATES
    @IBOutlet weak var rollRate: NumberField!
    @IBOutlet weak var pitchRate: NumberField!
    @IBOutlet weak var yawRate: NumberField!
    // TPA
    @IBOutlet weak var tpaRate: NumberField!
    @IBOutlet weak var tpaBreakpoint: ThrottleField!
    
    var settings: Settings?
    var profile: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        profilePicker = MyDownPicker(textField: profileField, withData: [ "1", "2", "3" ])
        
        let pidControllers: [String]
        if Configuration.theConfig.isApiVersionAtLeast("1.14") {
            pidControllers = [ "MultiWii (2.3)", "MultiWii (Rewrite)", "LuxFloat" ]
        } else {
            pidControllers = [ "MultiWii (Old)", "MultiWii (rewrite)", "LuxFloat", "MultiWii (2.3 - latest)", "MultiWii (2.3 - hybrid)", "Harakiri" ]
        }
        pidControllerPicker = MyDownPicker(textField: pidControllerField, withData: pidControllers)
        
        cancelAction(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        msp.sendMessage(.MSP_STATUS, data: nil, retry: 2, callback: { success in
            if success {
                self.msp.sendMessage(.MSP_RC_TUNING, data: nil, retry: 2, callback: { success in
                    if success {
                        self.msp.sendMessage(.MSP_PIDNAMES, data: nil, retry: 2, callback: { success in
                            if success {
                                self.msp.sendMessage(.MSP_PID_CONTROLLER, data: nil, retry: 2, callback: { success in
                                    if success {
                                        self.msp.sendMessage(.MSP_PID, data: nil, retry: 2, callback: { success in
                                            if success {
                                                dispatch_async(dispatch_get_main_queue(), {
                                                    let settings = Settings.theSettings
                                                    self.settings = settings
                                                    self.profile = Configuration.theConfig.profile ?? 0
                                                    
                                                    self.pidControllerPicker?.selectedIndex = settings.pidController
                                                    self.profilePicker?.selectedIndex = self.profile!
                                                    
                                                    self.rollRate.value = settings.rollRate
                                                    self.pitchRate.value = settings.pitchRate
                                                    self.yawRate.value = settings.yawRate
                                                    
                                                    self.tpaRate.value = settings.tpaRate
                                                    self.tpaBreakpoint.value = Double(settings.tpaBreakpoint)
                                                    
                                                    var pid = settings.getPID(.Pitch)!
                                                    self.pitchP.value = pid[0]
                                                    self.pitchI.value = pid[1]
                                                    self.pitchD.value = pid[2]
                                                    pid = settings.getPID(.Roll)!
                                                    self.rollP.value = pid[0]
                                                    self.rollI.value = pid[1]
                                                    self.rollD.value = pid[2]
                                                    pid = settings.getPID(.Yaw)!
                                                    self.yawP.value = pid[0]
                                                    self.yawI.value = pid[1]
                                                    self.yawD.value = pid[2]
                                                    pid = settings.getPID(.Alt)!
                                                    self.altP.value = pid[0]
                                                    self.altI.value = pid[1]
                                                    self.altD.value = pid[2]
                                                    pid = settings.getPID(.Vel)!
                                                    self.varioP.value = pid[0]
                                                    self.varioI.value = pid[1]
                                                    self.varioD.value = pid[2]
                                                    pid = settings.getPID(.Mag)!
                                                    self.magP.value = pid[0]
                                                    pid = settings.getPID(.Pos)!
                                                    self.posP.value = pid[0]
                                                    self.posI.value = pid[1]
                                                    pid = settings.getPID(.PosR)!
                                                    self.posRP.value = pid[0]
                                                    self.posRI.value = pid[1]
                                                    self.posRD.value = pid[2]
                                                    pid = settings.getPID(.NavR)!
                                                    self.navRP.value = pid[0]
                                                    self.navRI.value = pid[1]
                                                    self.navRD.value = pid[2]
                                                    pid = settings.getPID(.Level)!
                                                    self.angleLevel.value = pid[0]
                                                    self.horizonLevel.value = pid[1]
                                                    self.horizonTransition.value = pid[2]

                                                })
                                            }
                                        })
                                    }
                                })
                            }
                        })
                    }
                })
            }
        })
    }

    @IBAction func saveAction(sender: AnyObject) {
        if pidControllerPicker!.selectedIndex >= 0 {
            settings!.pidController = pidControllerPicker!.selectedIndex
        }
        profile = profilePicker!.selectedIndex
        
        settings?.rollRate = rollRate.value
        settings?.pitchRate = pitchRate.value
        settings?.yawRate = yawRate.value
        settings?.tpaRate = tpaRate.value
        settings?.tpaBreakpoint = Int(tpaBreakpoint.value)

        var pids = [[Double]]()
        pids.append([ rollP.value, rollI.value, rollD.value ])
        pids.append([ pitchP.value, pitchI.value, pitchD.value ])
        pids.append([ yawP.value, yawI.value, yawD.value ])
        pids.append([ altP.value, altI.value, altD.value ])
        pids.append([ posP.value, posI.value, 0.0 ])
        pids.append([ posRP.value, posRI.value, posRD.value ])
        pids.append([ navRP.value, navRI.value, navRD.value ])
        pids.append([ angleLevel.value, horizonLevel.value, horizonTransition.value ])
        pids.append([ magP.value, 0.0, 0.0 ])
        pids.append([ varioP.value, varioI.value, varioD.value ])
        settings?.pidValues = pids

        msp.sendSetRcTuning(settings!, callback: { success in
            if success {
                self.msp.sendPidController(self.settings!.pidController, callback: { success in
                    if success {
                        self.msp.sendPid(self.settings!, callback: { success in
                            if success {
                                self.msp.sendMessage(.MSP_EEPROM_WRITE, data: nil, retry: 2, callback: { success in
                                    if success {
                                        dispatch_async(dispatch_get_main_queue(), {
                                            SVProgressHUD.showSuccessWithStatus("Settings saved")
                                            self.cancelAction(self)
                                        })
                                    } else {
                                        self.saveFailedAlert()
                                    }
                                })
                            } else {
                                self.saveFailedAlert()
                            }
                        })
                    } else {
                        self.saveFailedAlert()
                    }
                })
            } else {
                self.saveFailedAlert()
            }
        })
    }
    
    func saveFailedAlert() {
        dispatch_async(dispatch_get_main_queue(), {
            SVProgressHUD.showErrorWithStatus("Save failed")
        })
    }
    
    @IBAction func profileChanged(sender: AnyObject) {
        msp.sendSelectProfile(profilePicker!.selectedIndex, callback: { success in
            dispatch_async(dispatch_get_main_queue(), {
                if success {
                    self.cancelAction(sender)
                } else {
                    SVProgressHUD.showErrorWithStatus("Profile switch failed")
                }
            })
        })
    }
}
