//
//  MotorConfigViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 27/04/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MotorConfigViewController: ConfigChildViewController {
    @IBOutlet weak var inavEnablePwmCell: UITableViewCell!
    @IBOutlet weak var inavEnablePWMSwitch: UISwitch!
    
    @IBOutlet weak var escProtocolField: UITextField!
    @IBOutlet weak var UnsyncedMotorSwitch: UISwitch!
    @IBOutlet weak var motorPwmFreqField: NumberField!
    @IBOutlet weak var motorPwmFreqCell: UITableViewCell!
    
    @IBOutlet weak var minimumCommandField: ThrottleField!
    @IBOutlet weak var minimumThrottleField: ThrottleField!
    @IBOutlet weak var maximumThrottleFIeld: ThrottleField!
    @IBOutlet weak var idleThrotleField: NumberField!
    @IBOutlet weak var idleThrotleCell: UITableViewCell!

    @IBOutlet weak var stopMotorSwitch: UISwitch!
    @IBOutlet weak var disarmDelayLabel: UILabel!
    @IBOutlet weak var disarmDelayStepper: UIStepper!
    @IBOutlet weak var disarmDelayCell: UITableViewCell!
    @IBOutlet weak var disarmMotorsSwitch: UISwitch!
    
    @IBOutlet var analogCells: [UITableViewCell]!
    
    var escProtocolPicker: MyDownPicker?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var escProtocols = [ "PWM", "OneShot125" ]
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.31") {
            escProtocols.appendContentsOf([ "OneShot42", "MultiShot", "Brushed", "DShot150",  "DShot300", "DShot600" ])
        } else if config.isINav {
            escProtocols.appendContentsOf([ "OneShot42", "MultiShot", "Brushed" ])
            UnsyncedMotorSwitch.on = true
            UnsyncedMotorSwitch.enabled = false
        }
        if !config.isINav {
            cell(inavEnablePwmCell, setHidden: true)
        }
        escProtocolPicker = MyDownPicker(textField: escProtocolField, withData: escProtocols)
        escProtocolPicker!.addTarget(self, action: #selector(escProtocolChanged(_:)), forControlEvents: .ValueChanged)
    }

    private func viewHideCells() {
        if escProtocolPicker?.selectedIndex >= 5 {      // DShot
            cells(analogCells, setHidden: true)
            cell(idleThrotleCell, setHidden: false)
        } else {
            var cellsToShow = Set(analogCells)
            if !UnsyncedMotorSwitch.on {
                cellsToShow.remove(motorPwmFreqCell)
                cell(motorPwmFreqCell, setHidden: true)
            }
            cells(Array(cellsToShow), setHidden: false)
            cell(idleThrotleCell, setHidden: true)
        }
        cell(disarmDelayCell, setHidden: !stopMotorSwitch.on)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.31") || config.isINav {
            settings!.motorPwmProtocol = escProtocolPicker!.selectedIndex
        } else {
            if escProtocolPicker?.selectedIndex == 0 {
                settings!.features.remove(.OneShot125)
            } else {
                settings!.features.insert(.OneShot125)
            }
        }
        if config.isINav {
            if inavEnablePWMSwitch.on {
                settings.features.insert(.PwmOutputEnable)
            } else {
                settings.features.remove(.PwmOutputEnable)
            }
        }

        settings.motorPwmRate = Int(motorPwmFreqField.value)
        settings.digitalIdleOffsetPercent = idleThrotleField.value
        
        settings!.minCommand = Int(minimumCommandField.value)
        settings!.minThrottle = Int(minimumThrottleField.value)
        settings!.maxThrottle = Int(maximumThrottleFIeld.value)
        
        settings!.disarmKillSwitch = disarmMotorsSwitch.on
        
        configViewController?.refreshUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.31") || config.isINav {
            escProtocolPicker?.selectedIndex = settings!.motorPwmProtocol
        } else {
            escProtocolPicker?.selectedIndex = settings!.features.contains(.OneShot125) ? 1 : 0
        }
        if !config.isINav {
            UnsyncedMotorSwitch.on = settings!.useUnsyncedPwm
        } else {
            inavEnablePWMSwitch.on = settings.features.contains(.PwmOutputEnable)
        }
        motorPwmFreqField.value = Double(settings!.motorPwmRate)
        idleThrotleField.value = settings!.digitalIdleOffsetPercent
        
        minimumCommandField.value = Double(settings!.minCommand ?? 0)
        minimumThrottleField.value = Double(settings!.minThrottle ?? 0)
        maximumThrottleFIeld.value = Double(settings!.maxThrottle ?? 0)

        stopMotorSwitch.on = settings!.features.contains(BaseFlightFeature.MotorStop) ?? false
        disarmDelayStepper.value = Double(settings!.autoDisarmDelay ?? 5)
        disarmDelayStep(disarmDelayStepper)
        
        disarmMotorsSwitch.on = settings!.disarmKillSwitch
        
        viewHideCells()
        
        reloadDataAnimated(false)
    }
    
    @IBAction func unsyncedMotorSwitchChanged(sender: AnyObject) {
        settings!.useUnsyncedPwm = !settings!.useUnsyncedPwm
        viewHideCells()
        reloadDataAnimated(true)
    }

    @IBAction func disarmDelayStep(sender: AnyObject) {
        settings!.autoDisarmDelay = Int(disarmDelayStepper.value)
        disarmDelayLabel.text = String(format: "Disarm motors after %d seconds", settings!.autoDisarmDelay ?? 5)
    }

    @IBAction func escProtocolChanged(sender: AnyObject) {
        viewHideCells()
        reloadDataAnimated(true)
    }

    @IBAction func motorStopSwitchChanged(sender: AnyObject) {
        if (stopMotorSwitch.on) {
            settings!.features.insert(BaseFlightFeature.MotorStop)
        } else {
            settings!.features.remove(BaseFlightFeature.MotorStop)
        }
        viewHideCells()
        reloadDataAnimated(true)
    }

}
