//
//  ConfigurationViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 07/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import DownPicker
import SVProgressHUD

class ConfigurationViewController: UITableViewController, FlightDataListener, UITextFieldDelegate {
    @IBOutlet weak var mixerTypeTextField: UITextField!
    @IBOutlet weak var mixerTypeView: UIImageView!
    @IBOutlet weak var motorStopField: UILabel!
    @IBOutlet weak var oneShotEscSwitch: UISwitch!
    @IBOutlet weak var disarmMotorsSwitch: UISwitch!
    @IBOutlet weak var minimumCommandField: ThrottleField!
    @IBOutlet weak var minimumThrottleField: ThrottleField!
    @IBOutlet weak var midThrottleField: ThrottleField!
    @IBOutlet weak var maximumThrottleFIeld: ThrottleField!
    @IBOutlet weak var boardRollField: NumberField!
    @IBOutlet weak var boardPitchField: NumberField!
    @IBOutlet weak var boardYawField: NumberField!
    @IBOutlet weak var gpsField: UILabel!
    @IBOutlet weak var receiverTypeField: UILabel!
    @IBOutlet weak var vbatField: UILabel!
    @IBOutlet weak var currentMeterField: UILabel!
    @IBOutlet weak var failsafeField: UILabel!
    @IBOutlet weak var rssiSwitch: UISwitch!
    @IBOutlet weak var inFlightCalSwitch: UISwitch!
    @IBOutlet weak var servoGimbalSwitch: UISwitch!
    @IBOutlet weak var softSerialSwitch: UISwitch!
    @IBOutlet weak var sonarSwitch: UISwitch!
    @IBOutlet weak var telemetrySwitch: UISwitch!
    @IBOutlet weak var threeDModeSwitch: UISwitch!
    @IBOutlet weak var ledStripSwitch: UISwitch!
    @IBOutlet weak var displaySwitch: UISwitch!
    @IBOutlet weak var blackboxSwitch: UISwitch!
    @IBOutlet weak var channelForwardingSwitch: UISwitch!

    var mixerTypePicker: MyDownPicker?
    
    var newSettings: Settings?
    var newMisc: Misc?
    
    
    override func viewDidLoad() {
        mixerTypePicker = MyDownPicker(textField: mixerTypeTextField, withData: MultiTypes.label)
        mixerTypePicker!.addTarget(self, action: #selector(ConfigurationViewController.mixerTypeChanged(_:)), forControlEvents: .ValueChanged)
        mixerTypePicker!.setPlaceholder("")
        
        fetchInformation()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        msp.addDataListener(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        msp.removeDataListener(self)
    }
    
    private func enableUserInteraction(enable: Bool) {
        self.tableView.userInteractionEnabled = enable
        self.navigationItem.leftBarButtonItem!.enabled = enable
        self.navigationItem.rightBarButtonItem!.enabled = enable
    }
    
    func fetchInformation() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.stopTimer()
        
        enableUserInteraction(false)
        
        if SVProgressHUD.isVisible() {
            SVProgressHUD.setStatus("Fetching information")
        }
        msp.sendMessage(.MSP_MISC, data: nil, retry: 2, callback: {success in
            if success {
                self.msp.sendMessage(.MSP_BF_CONFIG, data: nil, retry: 2, callback: { success in
                    if success {
                        self.msp.sendMessage(.MSP_ARMING_CONFIG, data: nil, retry: 2, callback: { success in
                            if success {
                                self.msp.sendMessage(.MSP_CF_SERIAL_CONFIG, data: nil, retry: 2, callback: { success in
                                    if success {
                                        if self.mspvehicle.config.isApiVersionAtLeast("1.16") {    // 1.12
                                            self.msp.sendMessage(.MSP_RX_CONFIG, data: nil, retry: 2, callback: { success in
                                                if success {
                                                    self.msp.sendMessage(.MSP_FAILSAFE_CONFIG, data: nil, retry: 2, callback: { success in
                                                        if success {
                                                            self.msp.sendMessage(.MSP_RXFAIL_CONFIG, data: nil, retry: 2, callback: { success in
                                                                if success {
                                                                    self.msp.sendMessage(.MSP_RC, data: nil, retry: 2, callback: { success in
                                                                        if success {
                                                                            dispatch_async(dispatch_get_main_queue(), {
                                                                                appDelegate.startTimer()
                                                                                self.enableUserInteraction(true)
                                                                                SVProgressHUD.dismiss()
                                                                            })
                                                                        } else {
                                                                            self.fetchInformationFailed()
                                                                        }
                                                                    })
                                                                } else {
                                                                    self.fetchInformationFailed()
                                                                }
                                                            })
                                                        } else {
                                                            self.fetchInformationFailed()
                                                        }
                                                    })
                                                } else {
                                                    self.fetchInformationFailed()
                                                }
                                            })
                                        } else {
                                            dispatch_async(dispatch_get_main_queue(), {
                                                appDelegate.startTimer()
                                                self.enableUserInteraction(true)
                                                SVProgressHUD.dismiss()
                                            })
                                        }
                                    } else {
                                        self.fetchInformationFailed()
                                    }
                                })
                            } else {
                                self.fetchInformationFailed()
                            }
                        })
                    } else {
                        self.fetchInformationFailed()
                    }
                })
            } else {
                self.fetchInformationFailed()
            }
        })
    }
    
    func fetchInformationFailed() {
        dispatch_async(dispatch_get_main_queue(), {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.startTimer()
            self.enableUserInteraction(true)
            self.showError("Communication error")
        })
    }
    
    func showError(message: String) {
        SVProgressHUD.showErrorWithStatus(message)
    }

    func refreshUI() {
        refreshUI(false)
    }
    
    func refreshUI(fullRefresh: Bool) {
        if fullRefresh {
            mixerTypePicker?.selectedIndex = (newSettings!.mixerConfiguration ?? 1) - 1
            mixerTypeChanged(self)
            
            oneShotEscSwitch.on = newSettings!.features.contains(BaseFlightFeature.OneShot125) ?? false
            disarmMotorsSwitch.on = newSettings!.disarmKillSwitch
            
            minimumCommandField.value = Double(newMisc!.minCommand ?? 0)
            minimumThrottleField.value = Double(newMisc!.minThrottle ?? 0)
            midThrottleField.value = Double(newMisc!.midRC ?? 0)
            maximumThrottleFIeld.value = Double(newMisc!.maxThrottle ?? 0)
            
            boardPitchField.value = Double(newSettings!.boardAlignPitch ?? 0)
            boardRollField.value = Double(newSettings!.boardAlignRoll ?? 0)
            boardYawField.value = Double(newSettings!.boardAlignYaw ?? 0)
            rssiSwitch.on = newSettings!.features.contains(BaseFlightFeature.RssiAdc)
            inFlightCalSwitch.on = newSettings!.features.contains(BaseFlightFeature.InflightCal)
            servoGimbalSwitch.on = newSettings!.features.contains(BaseFlightFeature.ServoTilt)
            softSerialSwitch.on = newSettings!.features.contains(BaseFlightFeature.SoftSerial)
            sonarSwitch.on = newSettings!.features.contains(BaseFlightFeature.Sonar)
            telemetrySwitch.on = newSettings!.features.contains(BaseFlightFeature.Telemetry)
            threeDModeSwitch.on = newSettings!.features.contains(BaseFlightFeature.ThreeD)
            ledStripSwitch.on = newSettings!.features.contains(BaseFlightFeature.LedStrip)
            displaySwitch.on = newSettings!.features.contains(BaseFlightFeature.Display)
            blackboxSwitch.on = newSettings!.features.contains(BaseFlightFeature.Blackbox)
            channelForwardingSwitch.on = newSettings!.features.contains(BaseFlightFeature.ChannelForwarding)
        }
        motorStopField.text = (newSettings!.features.contains(BaseFlightFeature.MotorStop) ?? false) ? "On" : "Off"
        
        gpsField.text = (newSettings!.features.contains(BaseFlightFeature.GPS) ?? false) ? "On" : "Off"
        vbatField.text = (newSettings!.features.contains(BaseFlightFeature.VBat) ?? false) ? "On" : "Off"
        currentMeterField.text = (newSettings!.features.contains(BaseFlightFeature.CurrentMeter) ?? false) ? "On" : "Off"
        failsafeField.text = (newSettings!.features.contains(BaseFlightFeature.Failsafe) ?? false) ? "On" : "Off"
        receiverTypeField.text = ReceiverConfigViewController.receiverConfigLabel(newSettings!)
    }
    
    @IBAction func saveAction(sender: AnyObject) {
        if mixerTypePicker!.selectedIndex >= 0 {
            newSettings!.mixerConfiguration = mixerTypePicker!.selectedIndex + 1
        }
        if oneShotEscSwitch.on {
            newSettings!.features.insert(BaseFlightFeature.OneShot125)
        } else {
            newSettings!.features.remove(BaseFlightFeature.OneShot125)
        }
        newSettings!.disarmKillSwitch = disarmMotorsSwitch.on
        
        newMisc!.minCommand = Int(minimumCommandField.value)
        newMisc!.minThrottle = Int(minimumThrottleField.value)
        newMisc!.midRC = Int(midThrottleField.value)
        newMisc!.maxThrottle = Int(maximumThrottleFIeld.value)

        newSettings!.boardAlignPitch = Int(boardPitchField.value)
        newSettings!.boardAlignRoll = Int(boardRollField.value)
        newSettings!.boardAlignYaw = Int(boardYawField.value)
        
        saveFeatureSwitchValue(rssiSwitch, feature: .RssiAdc)
        saveFeatureSwitchValue(inFlightCalSwitch, feature: .InflightCal)
        saveFeatureSwitchValue(servoGimbalSwitch, feature: .ServoTilt)
        saveFeatureSwitchValue(softSerialSwitch, feature: .SoftSerial)
        saveFeatureSwitchValue(sonarSwitch, feature: .Sonar)
        saveFeatureSwitchValue(telemetrySwitch, feature: .Telemetry)
        saveFeatureSwitchValue(threeDModeSwitch, feature: .ThreeD)
        saveFeatureSwitchValue(ledStripSwitch, feature: .LedStrip)
        saveFeatureSwitchValue(displaySwitch, feature: .Display)
        saveFeatureSwitchValue(blackboxSwitch, feature: .Blackbox)
        saveFeatureSwitchValue(channelForwardingSwitch, feature: .ChannelForwarding)
        
        SVProgressHUD.showWithStatus("Saving settings", maskType: .Black)
        enableUserInteraction(false)

        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.stopTimer()
        msp.sendSerialConfig(self.newSettings!, callback: { success in
            if success {
                self.msp.sendSetMisc(self.newMisc!, callback: { success in
                    if success {
                        self.msp.sendSetBfConfig(self.newSettings!, callback: { success in
                            if success {
                                self.msp.sendSetArmingConfig(self.newSettings!, callback: { success in
                                    if success {
                                        self.saveNewFailsafeSettings()
                                    } else {
                                        self.saveConfigFailed()
                                    }
                                })
                            } else {
                                self.saveConfigFailed()
                            }
                        })
                    } else {
                        self.saveConfigFailed()
                    }
                })
            } else {
                self.saveConfigFailed()
            }
        })
    }
    
    private func saveNewFailsafeSettings() {
        if mspvehicle.config.isApiVersionAtLeast("1.16") {
            self.msp.sendRxConfig(self.newSettings!, midRc: self.newMisc!.midRC, callback: { success in
                if success {
                    self.msp.sendFailsafeConfig(self.newSettings!, failsafeThrottle: self.newMisc!.failsafeThrottle, callback: { success in
                        if success {
                            self.msp.sendRxFailConfig(self.newSettings!, callback: { success in
                                if success {
                                    self.writeToEepromAndReboot()
                                } else {
                                    self.saveConfigFailed()
                                }
                            })
                        } else {
                            self.saveConfigFailed()
                        }
                    })
                } else {
                    self.saveConfigFailed()
                }
            })
        } else {
            self.writeToEepromAndReboot()
        }
    }
    
    private func writeToEepromAndReboot() {
        self.msp.sendMessage(.MSP_EEPROM_WRITE, data: nil, retry: 2, callback: { success in
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    SVProgressHUD.setStatus("Rebooting")
                })
                self.msp.sendMessage(.MSP_SET_REBOOT, data: nil, retry: 2, callback: { success in
                    if success {
                        // Wait 3 sec
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(3000) * NSEC_PER_MSEC)), dispatch_get_main_queue(), {
                            // Refetch information from FC
                            self.fetchInformation()
                        })
                    } else {
                        self.saveConfigFailed()
                    }
                })
            } else {
                self.saveConfigFailed()
            }
        })
    }
    
    func saveConfigFailed() {
        dispatch_async(dispatch_get_main_queue(), {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.startTimer()
            self.showError("Save failed")
            self.enableUserInteraction(true)
        })
    }
    
    func saveFeatureSwitchValue(uiSwitch: UISwitch, feature: BaseFlightFeature) {
        if uiSwitch.on {
            newSettings!.features.insert(feature)
        } else {
            newSettings!.features.remove(feature)
        }
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        newSettings = Settings(copyOf: mspvehicle.settings)
        newMisc = Misc(copyOf: mspvehicle.misc)
        
        fetchInformation()
    }
    
    func mixerTypeChanged(sender: AnyObject) {
        mixerTypeView.image = MultiTypes.getImage(mixerTypePicker!.selectedIndex + 1)
    }
    
    func receivedSettingsData() {
        newSettings = Settings(copyOf: mspvehicle.settings)
        newMisc = Misc(copyOf: mspvehicle.misc)
        refreshUI(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        (segue.destinationViewController as! ConfigChildViewController).setReference(self, newSettings: newSettings!, newMisc: newMisc!)
    }
}
