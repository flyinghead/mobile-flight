//
//  MotorPWMViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 05/10/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class MotorPWMViewController: ConfigChildViewController {
    @IBOutlet weak var UnsyncedMotorSwitch: UISwitch!
    @IBOutlet weak var motorPwmFreqField: NumberField!
    @IBOutlet weak var motorPwmFreqCell: UITableViewCell!

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        settings.motorPwmRate = Int(motorPwmFreqField.value)
        configViewController?.refreshUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        cell(motorPwmFreqCell, setHidden: !settings!.useUnsyncedPwm)
        motorPwmFreqField.value = Double(settings!.motorPwmRate)
        reloadDataAnimated(false)
    }

    @IBAction func unsyncedMotorSwitchChanged(sender: AnyObject) {
        settings!.useUnsyncedPwm = !settings!.useUnsyncedPwm
        cell(motorPwmFreqCell, setHidden: !settings!.useUnsyncedPwm)
        reloadDataAnimated(true)
    }

    class func motorPWMLabel(settings: Settings) -> String {
        if !settings.useUnsyncedPwm {
            return "Same as PID"
        } else {
            return String(format: "%d", settings.motorPwmRate)
        }
    }
}