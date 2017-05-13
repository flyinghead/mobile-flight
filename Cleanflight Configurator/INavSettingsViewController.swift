//
//  INavSettingsViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 13/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import SVProgressHUD

class INavSettingsViewController: UITableViewController {
    @IBOutlet weak var userControlModeField: UITextField!
    @IBOutlet weak var maxNavSpeedField: NumberField!
    @IBOutlet weak var maxManualSpeedField: NumberField!
    @IBOutlet weak var maxNavClimbRateField: NumberField!
    @IBOutlet weak var maxManualClimbRateField: NumberField!
    @IBOutlet weak var maxBankAngleField: NumberField!
    @IBOutlet weak var useThrottleMidForAltHoldSwitch: UISwitch!
    @IBOutlet weak var hoverThrottleField: ThrottleField!

    var userControlModePicker: MyDownPicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        userControlModePicker = MyDownPicker(textField: userControlModeField, withData: [ "Attitude", "Cruise" ])
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let minSpeed = msToLocaleSpeed(0.1)
        let maxSpeed = msToLocaleSpeed(20)
        for field in [ maxNavSpeedField, maxManualSpeedField, maxNavClimbRateField, maxManualClimbRateField ] {
            field.minimumValue = minSpeed
            field.maximumValue = maxSpeed
        }
        
        fetchData()
    }

    private func fetchData() {
        msp.sendMessage(.MSP_NAV_POSHOLD, data: nil, retry: 2) { success in
            dispatch_async(dispatch_get_main_queue()) {
                if success {
                    let inavConfig = INavConfig.theINavConfig
                    self.userControlModePicker.selectedIndex = inavConfig.userControlMode.intValue
                    self.maxNavSpeedField.value = msToLocaleSpeed(inavConfig.maxSpeed)
                    self.maxManualSpeedField.value = msToLocaleSpeed(inavConfig.maxManualSpeed)
                    self.maxNavClimbRateField.value = msToLocaleSpeed(inavConfig.maxClimbRate)
                    self.maxManualClimbRateField.value = msToLocaleSpeed(inavConfig.maxManualClimbRate)
                    self.maxBankAngleField.value = Double(inavConfig.maxBankAngle)
                    self.useThrottleMidForAltHoldSwitch.on = inavConfig.useThrottleMidForAltHold
                    self.hoverThrottleField.value = Double(inavConfig.hoverThrottle)
                    SVProgressHUD.dismiss()
                } else {
                    SVProgressHUD.showErrorWithStatus("Communication error")
                }
            }
        }
    }

    @IBAction func saveAction(sender: AnyObject) {
        SVProgressHUD.showWithStatus("Saving settings", maskType: .Black)
        
        self.appDelegate.stopTimer()
        let inavConfig = INavConfig.theINavConfig
        inavConfig.userControlMode = INavUserControlMode(value: userControlModePicker.selectedIndex)
        inavConfig.maxSpeed = localeSpeedToMs(maxNavSpeedField.value)
        inavConfig.maxManualSpeed = localeSpeedToMs(maxManualSpeedField.value)
        inavConfig.maxClimbRate = localeSpeedToMs(maxNavClimbRateField.value)
        inavConfig.maxManualClimbRate = localeSpeedToMs(maxManualClimbRateField.value)
        inavConfig.maxBankAngle = Int(round(maxBankAngleField.value))
        inavConfig.useThrottleMidForAltHold = useThrottleMidForAltHoldSwitch.on
        inavConfig.hoverThrottle = Int(round(hoverThrottleField.value))
        
        msp.sendNavPosHold(inavConfig) { success in
            if (success) {
                self.writeToEepromAndReboot()
            } else {
                self.saveFailed()
            }
        }
    }
    
    private func saveFailed() {
        dispatch_async(dispatch_get_main_queue()) {
            SVProgressHUD.showErrorWithStatus("Save failed")
            self.appDelegate.startTimer()
        }
    }
    
    private func writeToEepromAndReboot() {
        self.msp.sendMessage(.MSP_EEPROM_WRITE, data: nil, retry: 2, callback: { success in
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    SVProgressHUD.setStatus("Rebooting")
                })
                self.msp.sendMessage(.MSP_SET_REBOOT, data: nil, retry: 2) { success in
                    if success {
                        // Wait 4 sec
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(4000) * NSEC_PER_MSEC)), dispatch_get_main_queue(), {
                            self.appDelegate.startTimer()
                            self.fetchData()
                        })
                    } else {
                        self.saveFailed()
                    }
                }
            } else {
                self.saveFailed()
            }
        })
    }

}
