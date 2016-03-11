//
//  ServoConfigViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 01/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import DownPicker
import SVProgressHUD

class ServoConfigViewController: UITableViewController {
    @IBOutlet weak var minimumRangeField: NumberField!
    @IBOutlet weak var middleRangeField: NumberField!
    @IBOutlet weak var maximumRangeField: NumberField!
    @IBOutlet weak var minimumAngleField: NumberField!
    @IBOutlet weak var maximumAngleField: NumberField!
    @IBOutlet weak var rateField: NumberField!
    @IBOutlet weak var rcChannelField: UITextField!

    var rcChannelPicker: DownPicker!
    var servoIdx: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // FIXME Get MSP_RC to get number of RC channels
        var channels = ["(None)"]
        for var i = 0 ; i < 12 ; i++ {
            channels.append(ReceiverViewController.channelLabel(i))
        }
        rcChannelPicker = DownPicker(textField: rcChannelField, withData: channels)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = String(format: "Servo %d", servoIdx + 1)
        
        refreshAction(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        saveIfNeeded()
    }

    func saveIfNeeded() {
        let settings = mspvehicle.settings
        if settings.servoConfigs == nil || settings.servoConfigs!.count <= servoIdx {
            return
        }
        let servoConfig = settings.servoConfigs![servoIdx]
        
        let newServoConfig = ServoConfig(
            minimumRC: Int(round(minimumRangeField.value)),
            middleRC: Int(round(middleRangeField.value)),
            maximumRC: Int(round(maximumRangeField.value)),
            rate: Int(round(rateField.value)),
            minimumAngle: Int(round(minimumAngleField.value)),
            maximumAngle: Int(round(maximumAngleField.value)),
            rcChannel: (rcChannelPicker.selectedIndex < 1 ? nil : (rcChannelPicker.selectedIndex - 1)),
            reversedSources: servoConfig.reversedSources
        )
        
        var somethingChanged = servoConfig.minimumRC != newServoConfig.minimumRC
        somethingChanged = somethingChanged || servoConfig.middleRC != newServoConfig.middleRC
        somethingChanged = somethingChanged || servoConfig.maximumRC != newServoConfig.maximumRC
        somethingChanged = somethingChanged || servoConfig.minimumAngle != newServoConfig.minimumAngle
        somethingChanged = somethingChanged || servoConfig.maximumAngle != newServoConfig.maximumAngle
        somethingChanged = somethingChanged || servoConfig.rate != newServoConfig.rate
        somethingChanged = somethingChanged || servoConfig.rcChannel != newServoConfig.rcChannel
        
        if somethingChanged {
            msp.setServoConfig(servoIdx, servoConfig: newServoConfig, callback: { success in
                if success {
                    self.msp.sendMessage(.MSP_EEPROM_WRITE, data: nil, retry: 2, callback: { success in
                        if !success {
                            self.showError()
                        } else {
                            self.showSuccess()
                        }
                    })
                } else {
                    self.showError()
                }
            })
        }
    }
    
    func showError() {
        dispatch_async(dispatch_get_main_queue(), {
            SVProgressHUD.showErrorWithStatus("Save failed")
        })
    }
    func showSuccess() {
        dispatch_async(dispatch_get_main_queue(), {
            SVProgressHUD.showSuccessWithStatus("Settings saved")
        })
    }

    @IBAction func refreshAction(sender: AnyObject) {
        let settings = mspvehicle.settings
        
        if settings.servoConfigs != nil && settings.servoConfigs!.count > servoIdx {
            let servoConfig = settings.servoConfigs![servoIdx]
            
            minimumRangeField.value = Double(servoConfig.minimumRC)
            middleRangeField.value = Double(servoConfig.middleRC)
            maximumRangeField.value = Double(servoConfig.maximumRC)
            minimumAngleField.value = Double(servoConfig.minimumAngle)
            maximumAngleField.value = Double(servoConfig.maximumAngle)
            rateField.value = Double(servoConfig.rate)
            rcChannelPicker.selectedIndex = servoConfig.rcChannel == nil ? -1 : servoConfig.rcChannel! + 1
        }
        tableView.reloadData()
    }
}
