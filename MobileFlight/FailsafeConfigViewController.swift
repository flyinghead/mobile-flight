//
//  FailsafeConfigViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 12/12/15.
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

class FailsafeConfigViewController: ConfigChildViewController {
    @IBOutlet weak var failsafeSwitch: UISwitch!
    @IBOutlet weak var throttleField: ThrottleField!
    
    @IBOutlet var channelCells: [UITableViewCell]!
    @IBOutlet weak var dropCell: UITableViewCell!
    @IBOutlet weak var landCell: UITableViewCell!
    @IBOutlet var landCells: [UITableViewCell]!
    @IBOutlet var stage2ActiveCells: [UITableViewCell]!
    @IBOutlet weak var rthCell: UITableViewCell!
    
    @IBOutlet weak var minimumPulseField: NumberField!
    @IBOutlet weak var maximumPulseField: NumberField!
    @IBOutlet weak var killSwitch: UISwitch!
    @IBOutlet weak var killSwitchCell: UITableViewCell!
    @IBOutlet weak var guardTimeField: NumberField!
    @IBOutlet weak var throttleLowDelayField: NumberField!
    @IBOutlet weak var motorsOffDelayField: NumberField!
    @IBOutlet var channelsSettings: [UISegmentedControl]!
    @IBOutlet var auxChannelsValueFields: [NumberField]!

    class func isFailsafeEnabled(_ settings: Settings) -> Bool {
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.36") || (config.isINav && config.isApiVersionAtLeast("1.24")) {
            return true
        } else {
            return settings.features.contains(.Failsafe)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        throttleField.delegate = self
        minimumPulseField.delegate = self
        maximumPulseField.delegate = self
        guardTimeField.delegate = self
        throttleLowDelayField.delegate = self
        motorsOffDelayField.delegate = self
        
        for field in auxChannelsValueFields {
            field.delegate = self
        }
        
        let config = Configuration.theConfig
        if config.isINav {
            cells(channelCells, setHidden: true)
            if config.isApiVersionAtLeast("1.25") {
                cell(killSwitchCell, setHidden: true)
                stage2ActiveCells.remove(at: stage2ActiveCells.index(of: killSwitchCell)!)
            }
        } else {
            cells(Array(channelCells.suffix(channelCells.count - Receiver.theReceiver.activeChannels)), setHidden: true)
            cell(rthCell, setHidden: true)
            stage2ActiveCells.remove(at: stage2ActiveCells.index(of: rthCell)!)
        }
        if config.isApiVersionAtLeast("1.36") || (config.isINav && config.isApiVersionAtLeast("1.24")) {
            failsafeSwitch.isOn = true
            failsafeSwitch.isEnabled = false
        }
    }
    
    @IBAction func failsafeSwitchChanged(_ sender: Any) {
        if failsafeSwitch.isOn {
            if landCell.accessoryType != .checkmark {
                cells(Array(Set(stage2ActiveCells).subtracting(Set(landCells))), setHidden: false)
            } else {
                cells(stage2ActiveCells, setHidden: false)
            }
        } else {
            cells(stage2ActiveCells, setHidden: true)
        }
        reloadData(animated: sender as? FailsafeConfigViewController != self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if failsafeSwitch.isEnabled {
            if failsafeSwitch.isOn {
                settings!.features.insert(.Failsafe)
            } else {
                settings!.features.remove(.Failsafe)
            }
        }
        settings.failsafeThrottle = Int(throttleField.value)
        settings.rxMinUsec = Int(minimumPulseField.value)
        settings.rxMaxUsec = Int(maximumPulseField.value)
        settings.failsafeKillSwitch = killSwitch.isOn
        settings.failsafeDelay = guardTimeField.value
        settings.failsafeThrottleLowDelay = throttleLowDelayField.value
        if landCell.accessoryType == .checkmark {
            settings.failsafeProcedure =  0
        } else if dropCell.accessoryType == .checkmark {
            settings.failsafeProcedure = 1
        } else if rthCell.accessoryType == .checkmark{
            settings.failsafeProcedure = 2
        }
        settings.failsafeOffDelay = motorsOffDelayField.value
        
        if settings.rxFailMode != nil {
            for i in 0 ..< settings.rxFailMode!.count {
                if channelsSettings[i].selectedSegmentIndex == 0 {
                    if i >= 4 {
                        settings.rxFailMode![i] = 2     // Set
                    } else {
                        settings.rxFailMode![i] = 0     // Auto
                    }
                } else {
                    settings.rxFailMode![i] = 1     // Hold
                }
                if i >= 4 {
                    settings.rxFailValue![i] = Int(auxChannelsValueFields[i - 4].value)
                }
            }
        }
        configViewController?.refreshUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if failsafeSwitch.isEnabled {
            failsafeSwitch.isOn = settings!.features.contains(.Failsafe)
        }
        throttleField.value = Double(settings!.failsafeThrottle)
        
        minimumPulseField.value = Double(settings.rxMinUsec)
        maximumPulseField.value = Double(settings.rxMaxUsec)
        killSwitch.isOn = settings.failsafeKillSwitch
        guardTimeField.value = settings.failsafeDelay
        throttleLowDelayField.value = settings.failsafeThrottleLowDelay
        motorsOffDelayField.value = settings.failsafeOffDelay
        
        switch settings.failsafeProcedure {
        case 0:                             // Land
            landCell.accessoryType = .checkmark
            dropCell.accessoryType = .none
            rthCell.accessoryType = .none
            cells(landCells, setHidden: false)
        case 1:                             // Drop
            landCell.accessoryType = .none
            dropCell.accessoryType = .checkmark
            cells(landCells, setHidden: true)
            rthCell.accessoryType = .none
        default:                            // RTH
            landCell.accessoryType = .none
            dropCell.accessoryType = .none
            cells(landCells, setHidden: true)
            rthCell.accessoryType = .checkmark
        }
        if settings.rxFailMode != nil {
            for i in 0 ..< settings.rxFailMode!.count {
                channelsSettings[i].selectedSegmentIndex = settings.rxFailMode![i] % 2
                if i >= 4 {
                    auxChannelsValueFields[i - 4].value = Double(settings.rxFailValue![i])
                    if channelsSettings[i].selectedSegmentIndex != 0 {
                        auxChannelsValueFields[i - 4].isEnabled = false
                    }
                }
            }
        }
        failsafeSwitchChanged(self)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath)!
        if selectedCell == dropCell {
            selectedCell.accessoryType = .checkmark
            landCell.accessoryType = .none
            rthCell.accessoryType = .none
            cells(landCells, setHidden: true)
        } else if selectedCell == landCell {
            selectedCell.accessoryType = .checkmark
            dropCell.accessoryType = .none
            rthCell.accessoryType = .none
            cells(landCells, setHidden: false)
        } else if selectedCell == rthCell {
            selectedCell.accessoryType = .checkmark
            dropCell.accessoryType = .none
            landCell.accessoryType = .none
            cells(landCells, setHidden: true)
        }
        selectedCell.isSelected = false
        reloadData(animated: true)
    }

    @IBAction func auxChannelSetHoldChanged(_ sender: Any) {
        if let control = sender as? UISegmentedControl {
            var field: UITextField? = nil
            for view in control.superview!.subviews {
                if view is UITextField {
                    field = view as? UITextField
                    break
                }
            }
            field?.isEnabled = control.selectedSegmentIndex == 0
        }
    }
}

class AuxChannelSettingCell : UITableViewCell {
    
}
