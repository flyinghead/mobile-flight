//
//  INavSettingsViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 13/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import SVProgressHUD

class INavSettingsViewController: StaticDataTableViewController {
    @IBOutlet weak var userControlModeField: UITextField!
    @IBOutlet weak var maxNavSpeedField: NumberField!
    @IBOutlet weak var maxManualSpeedField: NumberField!
    @IBOutlet weak var maxNavClimbRateField: NumberField!
    @IBOutlet weak var maxManualClimbRateField: NumberField!
    @IBOutlet weak var maxBankAngleField: NumberField!
    @IBOutlet weak var useThrottleMidForAltHoldSwitch: UISwitch!
    @IBOutlet weak var hoverThrottleField: ThrottleField!
    
    @IBOutlet var inav171Cells: [UITableViewCell]!
    
    @IBOutlet weak var rthAltModeField: UITextField!
    @IBOutlet weak var rthAltitude: NumberField!
    @IBOutlet weak var climbBeforeRthSwitch: UISwitch!
    @IBOutlet weak var rthClimbEmergencySwitch: UISwitch!
    @IBOutlet weak var rthTailFirstSwitch: UISwitch!
    @IBOutlet weak var landAfterRthSwitch: UISwitch!
    @IBOutlet weak var landDescendRate: NumberField!
    @IBOutlet weak var landSlowdownMinAlt: NumberField!
    @IBOutlet weak var landSlowdownMaxAlt: NumberField!
    @IBOutlet weak var minRthDistance: NumberField!
    @IBOutlet weak var rthAbortThreshold: NumberField!
    @IBOutlet weak var emergencyDescendRate: NumberField!
    
    @IBOutlet weak var fwCruiseThrottle: ThrottleField!
    @IBOutlet weak var fwMinThrottle: ThrottleField!
    @IBOutlet weak var fwMaxThrottle: ThrottleField!
    @IBOutlet weak var fwMaxBankAngle: NumberField!
    @IBOutlet weak var fwMaxClimbAngle: NumberField!
    @IBOutlet weak var fwMaxDiveAngle: NumberField!
    @IBOutlet weak var fwPitchToThrottle: NumberField!
    @IBOutlet weak var fwLoiterRadius: NumberField!
    
    var userControlModePicker: MyDownPicker!
    var rthAltModePicker: MyDownPicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hideSectionsWithHiddenRows = true
        userControlModePicker = MyDownPicker(textField: userControlModeField, withData: [ "Attitude", "Cruise" ])
        rthAltModePicker = MyDownPicker(textField: rthAltModeField, withData: [ "Keep Current", "Extra", "Fixed", "Max Reached", "At Least" ])

        cells(inav171Cells, setHidden: !Configuration.theConfig.isApiVersionAtLeast("1.26"))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let minSpeed = msToLocaleSpeed(0.1)
        let maxSpeed = msToLocaleSpeed(20)
        for field in [ maxNavSpeedField, maxManualSpeedField ] {
            field.minimumValue = minSpeed
            field.maximumValue = maxSpeed
        }
        let maxAlt = mToLocaleDistance(655.36)
        for field in [ rthAltitude, landSlowdownMinAlt, landSlowdownMaxAlt ] {
            field.maximumValue = maxAlt
        }
        let maxDist = mToLocaleDistance(655.36)
        for field in [ minRthDistance, rthAbortThreshold, fwLoiterRadius ] {
            field.maximumValue = maxDist
        }
        let maxVerticalSpeed = msToLocaleVerticalSpeed(655.36)
        for field in [ landDescendRate, emergencyDescendRate, maxNavClimbRateField, maxManualClimbRateField ] {
            field.maximumValue = maxVerticalSpeed
        }
        
        fetchData()
    }

    private func fetchData() {
        var calls : [MSP_code] = [ .MSP_NAV_POSHOLD ]
        
        if Configuration.theConfig.isApiVersionAtLeast("1.26") {    // INAV 1.7.1
            calls.append(.MSP_RTH_AND_LAND_CONFIG)
            calls.append(.MSP_FW_CONFIG)
        }
        chainMspCalls(msp, calls: calls) { success in
            dispatch_async(dispatch_get_main_queue()) {
                if success {
                    let inavConfig = INavConfig.theINavConfig
                    self.userControlModePicker.selectedIndex = inavConfig.userControlMode.intValue
                    self.maxNavSpeedField.value = msToLocaleSpeed(inavConfig.maxSpeed)
                    self.maxManualSpeedField.value = msToLocaleSpeed(inavConfig.maxManualSpeed)
                    self.maxNavClimbRateField.value = msToLocaleVerticalSpeed(inavConfig.maxClimbRate)
                    self.maxManualClimbRateField.value = msToLocaleVerticalSpeed(inavConfig.maxManualClimbRate)
                    self.maxBankAngleField.value = Double(inavConfig.maxBankAngle)
                    self.useThrottleMidForAltHoldSwitch.on = inavConfig.useThrottleMidForAltHold
                    self.hoverThrottleField.value = Double(inavConfig.hoverThrottle)
                    
                    self.rthAltModePicker.selectedIndex = inavConfig.rthAltControlMode
                    self.rthAltitude.value = mToLocaleDistance(inavConfig.rthAltitude)
                    self.climbBeforeRthSwitch.on = inavConfig.rthClimbFirst
                    self.rthClimbEmergencySwitch.on = inavConfig.rthClimbIgnoreEmergency
                    self.rthTailFirstSwitch.on = inavConfig.rthTailFirst
                    self.landAfterRthSwitch.on = inavConfig.rthAllowLanding
                    self.landDescendRate.value = msToLocaleVerticalSpeed(inavConfig.landDescendRate)
                    self.landSlowdownMinAlt.value = mToLocaleDistance(inavConfig.landSlowdownMinAlt)
                    self.landSlowdownMaxAlt.value = mToLocaleDistance(inavConfig.landSlowdownMaxAlt)
                    self.minRthDistance.value = mToLocaleDistance(inavConfig.minRthDistance)
                    self.rthAbortThreshold.value = mToLocaleDistance(inavConfig.rthAbortThreshold)
                    self.emergencyDescendRate.value = msToLocaleVerticalSpeed(inavConfig.emergencyDescendRate)
                    
                    self.fwCruiseThrottle.value = Double(inavConfig.fwCruiseThrottle)
                    self.fwMinThrottle.value = Double(inavConfig.fwMinThrottle)
                    self.fwMaxThrottle.value = Double(inavConfig.fwMaxThrottle)
                    self.fwMaxBankAngle.value = Double(inavConfig.fwMaxBankAngle)
                    self.fwMaxClimbAngle.value = Double(inavConfig.fwMaxClimbAngle)
                    self.fwMaxDiveAngle.value = Double(inavConfig.fwMaxDiveAngle)
                    self.fwPitchToThrottle.value = Double(inavConfig.fwPitchToThrottle)
                    self.fwLoiterRadius.value = mToLocaleDistance(inavConfig.fwLoiterRadius)
                    
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
        inavConfig.maxClimbRate = localeVerticalSpeedToMs(maxNavClimbRateField.value)
        inavConfig.maxManualClimbRate = localeVerticalSpeedToMs(maxManualClimbRateField.value)
        inavConfig.maxBankAngle = Int(round(maxBankAngleField.value))
        inavConfig.useThrottleMidForAltHold = useThrottleMidForAltHoldSwitch.on
        inavConfig.hoverThrottle = Int(round(hoverThrottleField.value))
        
        
        inavConfig.rthAltControlMode = self.rthAltModePicker.selectedIndex
        inavConfig.rthAltitude = localeDistanceToM(self.rthAltitude.value)
        inavConfig.rthClimbFirst = self.climbBeforeRthSwitch.on
        inavConfig.rthClimbIgnoreEmergency = self.rthClimbEmergencySwitch.on
        inavConfig.rthTailFirst = self.rthTailFirstSwitch.on
        inavConfig.rthAllowLanding = self.landAfterRthSwitch.on
        inavConfig.landDescendRate = localeVerticalSpeedToMs(self.landDescendRate.value)
        inavConfig.landSlowdownMinAlt = localeDistanceToM(self.landSlowdownMinAlt.value)
        inavConfig.landSlowdownMaxAlt = localeDistanceToM(self.landSlowdownMaxAlt.value)
        inavConfig.minRthDistance = localeDistanceToM(self.minRthDistance.value)
        inavConfig.rthAbortThreshold = localeDistanceToM(self.rthAbortThreshold.value)
        inavConfig.emergencyDescendRate = localeVerticalSpeedToMs(self.emergencyDescendRate.value)
        
        inavConfig.fwCruiseThrottle = Int(self.fwCruiseThrottle.value)
        inavConfig.fwMinThrottle = Int(self.fwMinThrottle.value)
        inavConfig.fwMaxThrottle = Int(self.fwMaxThrottle.value)
        inavConfig.fwMaxBankAngle = Int(self.fwMaxBankAngle.value)
        inavConfig.fwMaxClimbAngle = Int(self.fwMaxClimbAngle.value)
        inavConfig.fwMaxDiveAngle = Int(self.fwMaxDiveAngle.value)
        inavConfig.fwPitchToThrottle = Int(self.fwPitchToThrottle.value)
        inavConfig.fwLoiterRadius = localeDistanceToM(self.fwLoiterRadius.value)
        
        var commands: [SendCommand] = [
            { callback in
                self.msp.sendNavPosHold(inavConfig, callback: callback)
            },
        ]
        if Configuration.theConfig.isApiVersionAtLeast("1.26") {    // INAV 1.7.1
            commands.append({ callback in
                self.msp.sendRthAndLandConfig(inavConfig, callback: callback)
            })
            commands.append({ callback in
                self.msp.sendFwConfig(inavConfig, callback: callback)
            })
        }
        commands.append({ callback in
            self.msp.sendMessage(.MSP_EEPROM_WRITE, data: nil, retry: 2, callback: { success in
                if success {
                    dispatch_async(dispatch_get_main_queue(), {
                        SVProgressHUD.setStatus("Rebooting")
                    })
                }
                callback(success)
            })
        })
        commands.append({ callback in
            self.msp.sendMessage(.MSP_SET_REBOOT, data: nil, retry: 2, callback: callback)
        })
        chainMspSend(commands) { success in
            if success {
                // Wait 4 sec
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(4000) * NSEC_PER_MSEC)), dispatch_get_main_queue(), {
                    self.appDelegate.startTimer()
                    self.fetchData()
                })
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    SVProgressHUD.showErrorWithStatus("Save failed")
                    self.appDelegate.startTimer()
                }
            }
        }
    }
}
