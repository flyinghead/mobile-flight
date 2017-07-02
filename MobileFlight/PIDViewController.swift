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
import Firebase

class PIDViewController: StaticDataTableViewController {
    @IBOutlet weak var pidControllerField: UITextField!
    var pidControllerPicker: MyDownPicker!
    @IBOutlet weak var resetPIDValuesCell: UITableViewCell!
    @IBOutlet weak var pidProfileLabel: UILabel!
    @IBOutlet weak var pidProfileStepper: UIStepper!
    @IBOutlet weak var rateProfileLabel: UILabel!
    @IBOutlet weak var rateProfileStepper: UIStepper!
    
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
    @IBOutlet weak var varioP: NumberField!
    @IBOutlet weak var varioI: NumberField!
    @IBOutlet weak var varioD: NumberField!
    // MAG
    @IBOutlet weak var magP: NumberField!
    //GPS
    @IBOutlet weak var posP: NumberField!
    @IBOutlet weak var posI: NumberField!
    @IBOutlet weak var posD: NumberField!
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
    // GYRO FILTERS
    @IBOutlet weak var gyroLowpassFrequency: NumberField!
    @IBOutlet weak var gyroNotchFrequency: NumberField!
    @IBOutlet weak var gyroNotchCutoff: NumberField!
    @IBOutlet weak var gyroNotchFrequency2: NumberField!
    @IBOutlet weak var gyroNotchCutoff2: NumberField!
    // PID FILTERS
    @IBOutlet weak var dTermLowpassFrequency: NumberField!
    @IBOutlet weak var dTermNotchFrequency: NumberField!
    @IBOutlet weak var dTermNotchCutoff: NumberField!
    @IBOutlet weak var yawLowpassFrequency: NumberField!
    
    @IBOutlet weak var pidControllerCell: UITableViewCell!
    @IBOutlet var betaflightCells: [UITableViewCell]!
    @IBOutlet var allPidsCells: [UITableViewCell]!
    
    var settings: Settings?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideSectionsWithHiddenRows = true

        pidProfileStepper.minimumValue = 1
        pidProfileStepper.maximumValue = 3
        pidProfileStepper.value = 1
        pidProfileLabel.text = String(1)
        
        rateProfileStepper.minimumValue = 1
        rateProfileStepper.maximumValue = 3
        rateProfileStepper.value = 1
        rateProfileLabel.text = String(1)
        
        pidControllerPicker = MyDownPicker(textField: pidControllerField, withData:  [ "MultiWii (2.3)", "MultiWii (Rewrite)", "LuxFloat" ])
        
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.31") || config.isINav {
            cell(pidControllerCell, setHidden: true)
        } else {
            cells(betaflightCells, setHidden: true)
        }
        cells(allPidsCells, setHidden: true)
        reloadDataAnimated(false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchData()
    }

    private func fetchData() {
        var calls:[MSP_code] = [.MSP_RC_TUNING, .MSP_PIDNAMES, .MSP_PID_CONTROLLER, .MSP_PID]

        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.31") || config.isINav {
            calls.append(.MSP_FILTER_CONFIG)
        }
        
        chainMspCalls(msp, calls: calls) { success in
            dispatch_async(dispatch_get_main_queue()) {
                if success {
                    let settings = Settings.theSettings
                    self.settings = settings
                    let config = Configuration.theConfig
                    
                    self.pidControllerPicker.selectedIndex = settings.pidController
                    self.pidProfileStepper.value = Double(config.profile + 1)
                    self.pidProfileLabel.text = String(config.profile + 1)
                    self.rateProfileStepper.value = Double(config.rateProfile + 1)
                    self.rateProfileLabel.text = String(config.rateProfile + 1)
                    
                    self.rollRate.value = settings.rollSuperRate
                    self.pitchRate.value = settings.pitchSuperRate
                    self.yawRate.value = settings.yawSuperRate
                    
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
                    pid = settings.getPID(.Vel)!
                    self.varioP.value = pid[0]
                    self.varioI.value = pid[1]
                    self.varioD.value = pid[2]
                    pid = settings.getPID(.Mag)!
                    self.magP.value = pid[0]
                    pid = settings.getPID(.Pos)!
                    self.posP.value = pid[0]
                    self.posI.value = pid[1]
                    self.posD.value = pid[2]
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
                    
                    self.gyroLowpassFrequency.value = Double(settings.gyroLowpassFrequency)
                    self.gyroNotchFrequency.value = Double(settings.gyroNotchFrequency)
                    self.gyroNotchCutoff.value = Double(settings.gyroNotchCutoff)
                    self.gyroNotchFrequency2.value = Double(settings.gyroNotchFrequency2)
                    self.gyroNotchCutoff2.value = Double(settings.gyroNotchCutoff2)
                    self.dTermLowpassFrequency.value = Double(settings.dTermLowpassFrequency)
                    self.dTermNotchFrequency.value = Double(settings.dTermNotchFrequency)
                    self.dTermNotchCutoff.value = Double(settings.dTermNotchCutoff)
                    self.yawLowpassFrequency.value = Double(settings.yawLowpassFrequency)
                    
                    SVProgressHUD.dismiss()
                } else {
                    SVProgressHUD.showErrorWithStatus("Communication error")
                }
            }
        }
     }

    @IBAction func saveAction(sender: AnyObject) {
        if pidControllerPicker.selectedIndex >= 0 {
            settings!.pidController = pidControllerPicker.selectedIndex
        }
        settings?.rollSuperRate = rollRate.value
        settings?.pitchSuperRate = pitchRate.value
        settings?.yawSuperRate = yawRate.value
        settings?.tpaRate = tpaRate.value
        settings?.tpaBreakpoint = Int(tpaBreakpoint.value)

        var pids = [[Double]]()
        pids.append([ rollP.value, rollI.value, rollD.value ])
        pids.append([ pitchP.value, pitchI.value, pitchD.value ])
        pids.append([ yawP.value, yawI.value, yawD.value ])
        pids.append([ altP.value, 0.0, 0.0 ])
        pids.append([ posP.value, posI.value, posD.value ])
        pids.append([ posRP.value, posRI.value, posRD.value ])
        pids.append([ navRP.value, navRI.value, navRD.value ])
        pids.append([ angleLevel.value, horizonLevel.value, horizonTransition.value ])
        pids.append([ magP.value, 0.0, 0.0 ])
        pids.append([ varioP.value, varioI.value, varioD.value ])
        settings?.pidValues = pids

        settings?.gyroLowpassFrequency = Int(round(gyroLowpassFrequency.value))
        settings?.gyroNotchFrequency = Int(round(gyroNotchFrequency.value))
        settings?.gyroNotchCutoff = Int(round(gyroNotchCutoff.value))
        settings?.gyroNotchFrequency2 = Int(round(gyroNotchFrequency2.value))
        settings?.gyroNotchCutoff2 = Int(round(gyroNotchCutoff2.value))
        settings?.dTermLowpassFrequency = Int(round(dTermLowpassFrequency.value))
        settings?.dTermNotchFrequency = Int(round(dTermNotchFrequency.value))
        settings?.dTermNotchCutoff = Int(round(dTermNotchCutoff.value))
        settings?.yawLowpassFrequency = Int(round(yawLowpassFrequency.value))
        
        Analytics.logEvent("pid_saved", parameters: nil)
        
        var commands: [SendCommand] = [
            { callback in
                self.msp.sendSetRcTuning(self.settings!, callback: callback)
            },
            { callback in
                self.msp.sendPid(self.settings!, callback: callback)
            },
            { callback in
                self.msp.sendPidController(self.settings!.pidController, callback: callback)
            },
        ]
        
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.31") || config.isINav {
            commands.append({ callback in
                self.msp.sendFilterConfig(self.settings!, callback: callback)
            })
        }
        commands.append({ callback in
            self.msp.sendMessage(.MSP_EEPROM_WRITE, data: nil, retry: 2, callback: callback)
        })
        chainMspSend(commands) { success in
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    SVProgressHUD.showSuccessWithStatus("Settings saved")
                    self.fetchData()
                })
            } else {
                self.saveFailedAlert()
            }
        }
    }
    
    func saveFailedAlert() {
        dispatch_async(dispatch_get_main_queue(), {
            Analytics.logEvent("pid_saved_failed", parameters: nil)
            SVProgressHUD.showErrorWithStatus("Save failed")
        })
    }
    
    @IBAction func resetPIDParams(sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: "This will reset the parameters of all PID controllers in the current profile to their default values. Are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { alertController in
            Analytics.logEvent("pid_reset", parameters: nil)
            self.msp.sendMessage(.MSP_SET_RESET_CURR_PID, data: nil, retry: 3, callback: { success in
                self.fetchData()
            })
        }))
        alertController.popoverPresentationController?.sourceView = (sender as! UIView)
        presentViewController(alertController, animated: true, completion: nil)
    }
    @IBAction func pidProfileChanged(sender: AnyObject) {
        SVProgressHUD.showWithStatus("Changing PID Profile")
        Analytics.logEvent("pid_profile_changed", parameters: nil)
        msp.sendSelectProfile(Int(pidProfileStepper.value) - 1, callback: { success in
            dispatch_async(dispatch_get_main_queue(), {
                if success {
                    self.fetchData()
                } else {
                    SVProgressHUD.showErrorWithStatus("Profile change failed")
                }
            })
        })
    }
    @IBAction func rateProfileChanged(sender: AnyObject) {
        SVProgressHUD.showWithStatus("Changing Rate Profile")
        Analytics.logEvent("rate_profile_changed", parameters: nil)
        msp.sendSelectRateProfile(Int(rateProfileStepper.value) - 1, callback: { success in
            dispatch_async(dispatch_get_main_queue(), {
                if success {
                    self.fetchData()
                } else {
                    SVProgressHUD.showErrorWithStatus("Rate profile change failed")
                }
            })
        })
    }
    @IBAction func showAllPidsChanged(sender: AnyObject) {
        if let uiswitch = sender as? UISwitch {
            cells(allPidsCells, setHidden: !uiswitch.on)
            reloadDataAnimated(true)
        }
    }
}
