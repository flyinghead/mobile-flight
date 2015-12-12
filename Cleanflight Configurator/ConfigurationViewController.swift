//
//  ConfigurationViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 07/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import DownPicker

protocol ConfigChildViewController {
    func setReference(viewController: ConfigurationViewController, newSettings: Settings, newMisc: Misc)
}

class ConfigurationViewController: UITableViewController, FlightDataListener, UITextFieldDelegate {
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var mixerTypeTextField: UITextField!
    @IBOutlet weak var mixerTypeView: UIImageView!
    @IBOutlet weak var motorStopField: UILabel!
    @IBOutlet weak var oneShotEscSwitch: UISwitch!
    @IBOutlet weak var disarmMotorsSwitch: UISwitch!
    @IBOutlet weak var minimumCommandField: UITextField!
    @IBOutlet weak var minimumThrottleField: UITextField!
    @IBOutlet weak var midThrottleField: UITextField!
    @IBOutlet weak var maximumThrottleFIeld: UITextField!
    @IBOutlet weak var boardRollField: UITextField!
    @IBOutlet weak var boardPitchField: UITextField!
    @IBOutlet weak var boardYawField: UITextField!
    @IBOutlet weak var gpsField: UILabel!

    var mixerTypePicker: DownPicker?
    var waitIndicator: UIAlertView?
    
    var newSettings: Settings?
    var newMisc: Misc?
    
    
    override func viewDidLoad() {
        mixerTypePicker = DownPicker(textField: mixerTypeTextField, withData: MultiTypes.label)
        
        msp.addDataListener(self)
        
        minimumCommandField.delegate = self
        minimumThrottleField.delegate = self
        midThrottleField.delegate = self
        maximumThrottleFIeld.delegate = self
        
        boardRollField.delegate = self
        boardPitchField.delegate = self
        boardYawField.delegate = self
        
        // FIXME When should we refresh?
        waitIndicator = showWaitIndicator()
        msp.sendMessage(.MSP_MISC, data: nil, retry: true)
        msp.sendMessage(.MSP_BF_CONFIG, data: nil, retry: true)
        msp.sendMessage(.MSP_ARMING_CONFIG, data: nil, retry: true)
    }
    
    func showWaitIndicator() -> UIAlertView {
        let progressAlert = UIAlertView()
        progressAlert.title = "Fetching Configuration"
        progressAlert.message = "Please Wait...."
//        progressAlert.addButtonWithTitle("Cancel")
        progressAlert.show()
        
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.center = CGPointMake(progressAlert.bounds.size.width / 2, progressAlert.bounds.size.height - 45)
        progressAlert.addSubview(activityView)
        activityView.hidesWhenStopped = true
        activityView.startAnimating()
        return progressAlert
    }

    func refreshData() {
        mixerTypePicker?.selectedIndex = (newSettings!.mixerConfiguration ?? 1) - 1
        mixerTypeChanged(self)
        
        motorStopField.text = (newSettings!.features?.contains(BaseFlightFeature.MotorStop) ?? false) ? "On" : "Off"
        oneShotEscSwitch.on = newSettings!.features?.contains(BaseFlightFeature.OneShot125) ?? false
        disarmMotorsSwitch.on = newSettings!.disarmKillSwitch
        
        minimumCommandField.text = String(format: "%d", newMisc!.minCommand ?? 0)
        minimumThrottleField.text = String(format: "%d", newMisc!.minThrottle ?? 0)
        midThrottleField.text = String(format: "%d", newMisc!.midRC ?? 0)
        maximumThrottleFIeld.text = String(format: "%d", newMisc!.maxThrottle ?? 0)
        
        boardPitchField.text = String(format: "%d", newSettings!.boardAlignPitch ?? 0)
        boardRollField.text = String(format: "%d", newSettings!.boardAlignRoll ?? 0)
        boardYawField.text = String(format: "%d", newSettings!.boardAlignYaw ?? 0)
        
        gpsField.text = (newSettings!.features?.contains(BaseFlightFeature.GPS) ?? false) ? "On" : "Off"
    }
    
    func validateThrottleField(field: UITextField, label: String) -> Bool {
        if (field.text == nil) {
            UIAlertView(title: label, message: "Value missing", delegate: nil, cancelButtonTitle: "OK").show()
            return false
        }
        let value = Int(field.text!)
        if (value < 0 || value > 2500) {
            UIAlertView(title: label, message: "Invalid value", delegate: nil, cancelButtonTitle: "OK").show()
            return false
        }
        return true
    }
    
    func validateAngleField(field: UITextField, label: String) -> Bool {
        if (field.text == nil) {
            UIAlertView(title: label, message: "Value missing", delegate: nil, cancelButtonTitle: "OK").show()
            return false
        }
        let value = Int(field.text!)
        if (value < -360 || value > 360) {
            UIAlertView(title: label, message: "Invalid value", delegate: nil, cancelButtonTitle: "OK").show()
            return false
        }
        return true
    }
    
    @IBAction func saveAction(sender: AnyObject) {
        newSettings!.mixerConfiguration = mixerTypePicker!.selectedIndex + 1
        if oneShotEscSwitch.on {
            newSettings!.features!.insert(BaseFlightFeature.OneShot125)
        } else {
            newSettings!.features!.remove(BaseFlightFeature.OneShot125)
        }
        newSettings!.disarmKillSwitch = disarmMotorsSwitch.on
        
        if !validateThrottleField(minimumCommandField, label: "Minimum Command") {
            return
        }
        newMisc!.minCommand = Int(minimumCommandField.text!)!
        if !validateThrottleField(minimumThrottleField, label: "Minimum Throttle") {
            return
        }
        newMisc!.minThrottle = Int(minimumThrottleField.text!)!
        if !validateThrottleField(midThrottleField, label: "Middle Throttle") {
            return
        }
        newMisc!.midRC = Int(midThrottleField.text!)!
        if !validateThrottleField(maximumThrottleFIeld, label: "Maximum Throttle") {
            return
        }
        newMisc!.maxThrottle = Int(maximumThrottleFIeld.text!)!

        if !validateAngleField(boardPitchField, label: "Board Pitch Alignment") {
            return
        }
        newSettings!.boardAlignPitch = Int(boardPitchField.text!)!
        if !validateAngleField(boardRollField, label: "Board Roll Alignment") {
            return
        }
        newSettings!.boardAlignRoll = Int(boardRollField.text!)!
        if !validateAngleField(boardYawField, label: "Board Yaw Alignment") {
            return
        }
        newSettings!.boardAlignYaw = Int(boardYawField.text!)!
        
        msp.sendSetMisc(newMisc!)
        msp.sendSetBfConfig(newSettings!)
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        newSettings = Settings(copyOf: Settings.theSettings)
        newMisc = Misc(copyOf: Misc.theMisc)
        
        refreshData()
    }
    
    @IBAction func mixerTypeChanged(sender: AnyObject) {
        mixerTypeView.image = MultiTypes.getImage(mixerTypePicker!.selectedIndex + 1)
        enableSaveAndCancel()
    }
    private func enableSaveAndCancel() {
        saveButton.enabled = true
        cancelButton.enabled = true
    }
    
    func receivedSettingsData() {
        newSettings = Settings(copyOf: Settings.theSettings)
        newMisc = Misc(copyOf: Misc.theMisc)
        refreshData()
        if (waitIndicator != nil && newSettings!.features != nil && newSettings!.autoDisarmDelay != nil) {
            waitIndicator!.dismissWithClickedButtonIndex(0, animated: true)
            waitIndicator = nil;
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        (segue.destinationViewController as! ConfigChildViewController).setReference(self, newSettings: newSettings!, newMisc: newMisc!)
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool { // return NO to not change text
        let number: [Character] = [ "0", "1", "2", "3" ,"4", "5", "6", "7", "8", "9" ]
        let negativeNumber: [Character] = [ "0", "1", "2", "3" ,"4", "5", "6", "7", "8", "9", "-" ]
        var allowed: [Character]?
        if textField === boardRollField || textField === boardPitchField || textField == boardYawField {
            allowed = negativeNumber
        } else {
            allowed = number
        }
        for c in string.characters {
            if !allowed!.contains(c) {
                return false
            }
        }
        return true
    }
}
