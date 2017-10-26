//
//  MotorConfigViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 27/04/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class MotorConfigViewController: ConfigChildViewController {
    @IBOutlet weak var inavEnablePWMSwitch: UISwitch!
    
    @IBOutlet weak var escProtocolField: UITextField!
    @IBOutlet weak var UnsyncedMotorSwitch: UISwitch!
    @IBOutlet weak var motorPwmFreqField: NumberField!
    @IBOutlet weak var motorPwmFreqCell: ConditionalTableViewCell!
    @IBOutlet weak var servoPwmFreqField: NumberField!
    
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
    @IBOutlet var conditionalCells: [ConditionalTableViewCell]!
    
    var escProtocolPicker: MyDownPicker?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var escProtocols = [ "PWM", "OneShot125" ]
        let config = Configuration.theConfig
        if (config.isBetaflight && config.isApiVersionAtLeast("1.31")) || (!config.isINav && !config.isBetaflight && config.isApiVersionAtLeast("1.35")) {
            escProtocols.append(contentsOf: [ "OneShot42", "MultiShot", "Brushed", "DShot150",  "DShot300", "DShot600", "DShot1200" ])
        } else if config.isINav {
            escProtocols.append(contentsOf: [ "OneShot42", "MultiShot", "Brushed" ])
            UnsyncedMotorSwitch.isOn = true
            UnsyncedMotorSwitch.isEnabled = false
        }
        if config.isApiVersionAtLeast("1.36") && !config.isINav {
            escProtocols.append("ProShot1000")
        }
        escProtocolPicker = MyDownPicker(textField: escProtocolField, withData: escProtocols)
        escProtocolPicker!.addTarget(self, action: #selector(escProtocolChanged(_:)), for: .valueChanged)
        
        showCells(conditionalCells, show: true)
    }

    fileprivate func viewHideCells() {
        if escProtocolPicker?.selectedIndex >= 5 {      // DShot
            cells(analogCells, setHidden: true)
            cell(idleThrotleCell, setHidden: false)
        } else {
            var cellsToShow = Set(analogCells)
            if !UnsyncedMotorSwitch.isOn {
                cellsToShow.remove(motorPwmFreqCell)
                cell(motorPwmFreqCell, setHidden: true)
            }
            showCells(Array(cellsToShow), show: true)
            cell(idleThrotleCell, setHidden: true)
        }
        cell(disarmDelayCell, setHidden: !stopMotorSwitch.isOn)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
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
            if inavEnablePWMSwitch.isOn {
                settings.features.insert(.PwmOutputEnable)
            } else {
                settings.features.remove(.PwmOutputEnable)
            }
            settings.servoPwmRate = Int(servoPwmFreqField.value)
        }

        settings.motorPwmRate = Int(motorPwmFreqField.value)
        settings.digitalIdleOffsetPercent = idleThrotleField.value
        
        settings!.minCommand = Int(minimumCommandField.value)
        settings!.minThrottle = Int(minimumThrottleField.value)
        settings!.maxThrottle = Int(maximumThrottleFIeld.value)
        
        settings!.disarmKillSwitch = disarmMotorsSwitch.isOn
        
        configViewController?.refreshUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.31") || config.isINav {
            escProtocolPicker?.selectedIndex = settings!.motorPwmProtocol
        } else {
            escProtocolPicker?.selectedIndex = settings!.features.contains(.OneShot125) ? 1 : 0
        }
        if !config.isINav {
            UnsyncedMotorSwitch.isOn = settings!.useUnsyncedPwm
        } else {
            inavEnablePWMSwitch.isOn = settings.features.contains(.PwmOutputEnable)
            servoPwmFreqField.value = Double(settings.servoPwmRate)
        }
        motorPwmFreqField.value = Double(settings.motorPwmRate)
        idleThrotleField.value = settings!.digitalIdleOffsetPercent
        
        minimumCommandField.value = Double(settings!.minCommand)
        minimumThrottleField.value = Double(settings!.minThrottle)
        maximumThrottleFIeld.value = Double(settings!.maxThrottle)

        stopMotorSwitch.isOn = settings!.features.contains(BaseFlightFeature.MotorStop)
        disarmDelayStepper.value = Double(settings!.autoDisarmDelay)
        disarmDelayStep(disarmDelayStepper)
        
        disarmMotorsSwitch.isOn = settings!.disarmKillSwitch
        
        viewHideCells()
        
        reloadData(animated: false)
    }
    
    @IBAction func unsyncedMotorSwitchChanged(_ sender: Any) {
        settings!.useUnsyncedPwm = !settings!.useUnsyncedPwm
        viewHideCells()
        reloadData(animated: true)
    }

    @IBAction func disarmDelayStep(_ sender: Any) {
        settings!.autoDisarmDelay = Int(disarmDelayStepper.value)
        disarmDelayLabel.text = String(format: "Disarm motors after %d seconds", settings!.autoDisarmDelay)
    }

    @IBAction func escProtocolChanged(_ sender: Any) {
        viewHideCells()
        reloadData(animated: true)
    }

    @IBAction func motorStopSwitchChanged(_ sender: Any) {
        if (stopMotorSwitch.isOn) {
            settings!.features.insert(BaseFlightFeature.MotorStop)
        } else {
            settings!.features.remove(BaseFlightFeature.MotorStop)
        }
        viewHideCells()
        reloadData(animated: true)
    }

}
