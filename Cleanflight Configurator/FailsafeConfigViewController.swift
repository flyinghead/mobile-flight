//
//  FailsafeConfigViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 12/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class FailsafeConfigViewController: ConfigChildViewController {
    @IBOutlet weak var failsafeSwitch: UISwitch!
    @IBOutlet weak var throttleField: ThrottleField!
    
    @IBOutlet weak var pre112ThrottleCell: UITableViewCell!
    @IBOutlet var pre112Config: [UITableViewCell]!
    
    @IBOutlet var post112Cells: [UITableViewCell]!
    @IBOutlet var channelCells: [UITableViewCell]!
    @IBOutlet weak var dropCell: UITableViewCell!
    @IBOutlet weak var landCell: UITableViewCell!
    @IBOutlet var landCells: [UITableViewCell]!
    @IBOutlet var stage2ActiveCells: [UITableViewCell]!
    
    @IBOutlet weak var minimumPulseField: NumberField!
    @IBOutlet weak var maximumPulseField: NumberField!
    @IBOutlet weak var killSwitch: UISwitch!
    @IBOutlet weak var guardTimeField: NumberField!
    @IBOutlet weak var throttleLowDelayField: NumberField!
    @IBOutlet weak var motorsOffDelayField: NumberField!
    @IBOutlet var channelsSettings: [UISegmentedControl]!
    @IBOutlet var auxChannelsValueFields: [NumberField]!

    var post112 = false
    
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
        
        post112 = mspvehicle.config.isApiVersionAtLeast("1.16")    // 1.12
        if post112 {
            cells(pre112Config, setHidden: true)
            cells(Array(channelCells.suffix(channelCells.count - mspvehicle.receiver.activeChannels)), setHidden: true)
        } else {
            cells(post112Cells, setHidden: true)
            cells(channelCells, setHidden: true)
        }
    }
    
    @IBAction func failsafeSwitchChanged(sender: AnyObject) {
        if post112 {
            if failsafeSwitch.on {
                if dropCell.accessoryType == .Checkmark {
                    cells(Array(Set(stage2ActiveCells).subtract(Set(landCells))), setHidden: !failsafeSwitch.on)
                } else {
                    cells(stage2ActiveCells, setHidden: false)
                }
            } else {
                cells(stage2ActiveCells, setHidden: true)
            }
        } else {
            cell(pre112ThrottleCell, setHidden: !failsafeSwitch.on)
        }
        reloadDataAnimated(sender as? FailsafeConfigViewController != self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if failsafeSwitch.on {
            settings!.features.insert(.Failsafe)
        } else {
            settings!.features.remove(.Failsafe)
        }
        misc!.failsafeThrottle = Int(throttleField.value)
        settings.rxMinUsec = Int(minimumPulseField.value)
        settings.rxMaxUsec = Int(maximumPulseField.value)
        settings.failsafeKillSwitch = killSwitch.on
        settings.failsafeDelay = guardTimeField.value
        settings.failsafeThrottleLowDelay = throttleLowDelayField.value
        settings.failsafeProcedure = landCell.accessoryType == .Checkmark ? 0 : 1
        settings.failsafeOffDelay = motorsOffDelayField.value
        
        for var i = 0; i < settings.rxFailMode?.count; i++ {
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
        configViewController?.refreshUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        failsafeSwitch.on = settings!.features.contains(.Failsafe)
        throttleField.value = Double(misc!.failsafeThrottle)
        
        if post112 {
            minimumPulseField.value = Double(settings.rxMinUsec)
            maximumPulseField.value = Double(settings.rxMaxUsec)
            killSwitch.on = settings.failsafeKillSwitch
            guardTimeField.value = settings.failsafeDelay
            throttleLowDelayField.value = settings.failsafeThrottleLowDelay
            motorsOffDelayField.value = settings.failsafeOffDelay
            
            if settings.failsafeProcedure == 0 {    // Land
                landCell.accessoryType = .Checkmark
                dropCell.accessoryType = .None
                cells(landCells, setHidden: false)
            } else {                                // Drop
                landCell.accessoryType = .None
                dropCell.accessoryType = .Checkmark
                cells(landCells, setHidden: true)
            }
            for var i = 0; i < settings.rxFailMode?.count; i++ {
                channelsSettings[i].selectedSegmentIndex = settings.rxFailMode![i] % 2
                if i >= 4 {
                    auxChannelsValueFields[i - 4].value = Double(settings.rxFailValue![i])
                    if channelsSettings[i].selectedSegmentIndex != 0 {
                        auxChannelsValueFields[i - 4].enabled = false
                    }
                }
            }
        }
        failsafeSwitchChanged(self)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)!
        if selectedCell == dropCell {
            selectedCell.accessoryType = .Checkmark
            landCell.accessoryType = .None
            cells(landCells, setHidden: true)
        } else if selectedCell == landCell {
            selectedCell.accessoryType = .Checkmark
            dropCell.accessoryType = .None
            cells(landCells, setHidden: false)
        }
        selectedCell.selected = false
        reloadDataAnimated(true)
    }

    @IBAction func auxChannelSetHoldChanged(sender: AnyObject) {
        if let control = sender as? UISegmentedControl {
            var field: UITextField? = nil
            for view in control.superview!.subviews {
                if view is UITextField {
                    field = view as? UITextField
                    break
                }
            }
            field?.enabled = control.selectedSegmentIndex == 0
        }
    }
}

class AuxChannelSettingCell : UITableViewCell {
    
}
