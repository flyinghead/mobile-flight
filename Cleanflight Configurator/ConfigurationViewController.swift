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

class ConfigurationViewController: StaticDataTableViewController, UITextFieldDelegate {
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
    @IBOutlet weak var loopTimeField: NumberField!
    @IBOutlet weak var cyclesPerSecLabel: UILabel!
    @IBOutlet weak var transponderSwitch: UISwitch!
    
    @IBOutlet var betaflightFeatures: [UITableViewCell]!
    @IBOutlet var nonBetaflightFeatures: [UITableViewCell]!
    @IBOutlet weak var gyroUpdateFreqField: UITextField!
    @IBOutlet weak var pidLoopFreqField: UITextField!
    @IBOutlet weak var enableAccelerometer: UISwitch!
    @IBOutlet weak var enableBarometer: UISwitch!
    @IBOutlet weak var enableMagnetometer: UISwitch!
    @IBOutlet weak var escProtocolField: UITextField!
    @IBOutlet weak var motorPWMFreqLabel: UILabel!
    @IBOutlet weak var airModeSwitch: UISwitch!
    @IBOutlet weak var osdSwitch: UISwitch!
    
    var gyroUpdateFredPicker: MyDownPicker?
    var pidLoopFreqPicker: MyDownPicker?
    var escProtocolPicker: MyDownPicker?
    
    var mixerTypePicker: MyDownPicker?
    
    var newSettings: Settings?
    var newMisc: Misc?
    var childVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mixerTypePicker = MyDownPicker(textField: mixerTypeTextField, withData: MultiTypes.label)
        mixerTypePicker!.addTarget(self, action: #selector(ConfigurationViewController.mixerTypeChanged(_:)), forControlEvents: .ValueChanged)
        mixerTypePicker!.setPlaceholder("")
        
        loopTimeField.changeCallback = { value in
            if value == 0 {
                self.cyclesPerSecLabel.text = ""
            } else {
                self.cyclesPerSecLabel.text = String(format:"%.0f", 1 / value * 1000 * 1000)
            }
        }
        hideSectionsWithHiddenRows = true

        cells(betaflightFeatures, setHidden: !isBetaflight)
        cells(nonBetaflightFeatures, setHidden: isBetaflight)

        if isBetaflight {
            escProtocolPicker = MyDownPicker(textField: escProtocolField, withData: [ "PWM", "OneShot125", "OneShot42", "MultiShot", "Brushed" ])
            escProtocolPicker?.setPlaceholder("")
            gyroUpdateFredPicker = MyDownPicker(textField: gyroUpdateFreqField, withData: [ "8 KHz", "4 KHz", "2.67 KHz", "2 KHz", "1.6 KHz", "1.33 KHz", "1.14 KHz", "1 KHz" ])
            gyroUpdateFredPicker!.setPlaceholder("")
            pidLoopFreqPicker = MyDownPicker(textField: pidLoopFreqField, withData: [ "2 KHz", "1 KHz", "0.67 KHz", "0.5 KHz", "0.4 KHz", "0.33 KHz", "0.29 KHz", "0.25 KHz" ])
            pidLoopFreqPicker!.setPlaceholder("")
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if !childVisible {
            fetchInformation()
        } else {
            childVisible = false
        }
    }

    private func enableUserInteraction(enable: Bool) {
        self.tableView.userInteractionEnabled = enable
        self.navigationItem.rightBarButtonItem!.enabled = enable
    }
    
    func fetchInformation() {
        appDelegate.stopTimer()
        
        enableUserInteraction(false)
        
        if SVProgressHUD.isVisible() {
            SVProgressHUD.setStatus("Fetching information")
        }
        // FIXME Get rid of MSP_MISC
        chainMspCalls(msp, calls: [.MSP_MISC, .MSP_MIXER_CONFIG, .MSP_FEATURE, .MSP_RX_CONFIG, .MSP_BOARD_ALIGNMENT, .MSP_CURRENT_METER_CONFIG, .MSP_ARMING_CONFIG, .MSP_CF_SERIAL_CONFIG, .MSP_LOOP_TIME]) { success in
            if success {
                self.fetchFailsafeConfig()
            } else {
                self.fetchInformationFailed()
            }
        }
    }
        
    func fetchFailsafeConfig() {
        if Configuration.theConfig.isApiVersionAtLeast("1.16") {    // 1.12
            chainMspCalls(msp, calls: [.MSP_FAILSAFE_CONFIG, .MSP_RXFAIL_CONFIG]) { success in
                if success {
                    self.fetchBetaflightConfig()
                } else {
                    self.fetchInformationFailed()
                }
            }
        } else {
            // SUCCESS
            self.fetchBetaflightConfig()
        }
    }
    
    private func fetchBetaflightConfig() {
        if !isBetaflight {
            fetchInformationSucceeded()
        } else {
            chainMspCalls(msp, calls: [.MSP_PID_ADVANCED_CONFIG, .MSP_SENSOR_CONFIG]) { success in
                if success {
                    // SUCCESS
                    self.fetchInformationSucceeded()
                } else {
                    self.fetchInformationFailed()
                }
            }
        }
    }
    
    private func fetchInformationFailed() {
        dispatch_async(dispatch_get_main_queue(), {
            self.appDelegate.startTimer()
            self.tableView.userInteractionEnabled = true
            self.showError("Communication error")
            
            // To avoid crashing when displaying child views
            self.newSettings = Settings(copyOf: Settings.theSettings)
            self.newMisc = Misc(copyOf: Misc.theMisc)
        })
    }
    
    private func fetchInformationSucceeded() {
        dispatch_async(dispatch_get_main_queue(), {
            self.appDelegate.startTimer()
            self.enableUserInteraction(true)
            SVProgressHUD.dismiss()
            
            self.newSettings = Settings(copyOf: Settings.theSettings)
            self.newMisc = Misc(copyOf: Misc.theMisc)
            self.refreshUI(true)
        })
    }
    
    private func showError(message: String) {
        SVProgressHUD.showErrorWithStatus(message)
    }

    func refreshUI() {
        refreshUI(false)
    }
    
    private func refreshUI(fullRefresh: Bool) {
        if fullRefresh {
            mixerTypePicker?.selectedIndex = (newSettings!.mixerConfiguration ?? 1) - 1
            mixerTypeChanged(self)
            
            if !isBetaflight {
                oneShotEscSwitch.on = newSettings!.features.contains(BaseFlightFeature.OneShot125) ?? false
            }
            disarmMotorsSwitch.on = newSettings!.disarmKillSwitch
            
            minimumCommandField.value = Double(newMisc!.minCommand ?? 0)
            minimumThrottleField.value = Double(newMisc!.minThrottle ?? 0)
            midThrottleField.value = Double(newSettings!.midRC ?? 0)
            maximumThrottleFIeld.value = Double(newMisc!.maxThrottle ?? 0)
            
            setBoardAlignmentFieldValue(boardPitchField, value: Double(newSettings!.boardAlignPitch ?? 0))
            setBoardAlignmentFieldValue(boardRollField, value: Double(newSettings!.boardAlignRoll ?? 0))
            setBoardAlignmentFieldValue(boardYawField, value: Double(newSettings!.boardAlignYaw ?? 0))

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
            transponderSwitch.on = newSettings!.features.contains(BaseFlightFeature.Transponder)
            
            loopTimeField.value = Double(newSettings!.loopTime)
            
            // Betaflight
            escProtocolPicker?.selectedIndex = newSettings!.motorPwmProtocol
            gyroUpdateFredPicker?.selectedIndex = newSettings!.gyroSyncDenom - 1
            pidLoopFreqPicker?.selectedIndex = newSettings!.pidProcessDenom - 1
            enableAccelerometer.on = !newSettings!.accelerometerDisabled
            enableBarometer.on = !newSettings!.barometerDisabled
            enableMagnetometer.on = !newSettings!.magnetometerDisabled
            airModeSwitch.on = newSettings!.features.contains(BaseFlightFeature.AirMode)
            osdSwitch.on = newSettings!.features.contains(BaseFlightFeature.OSD)
        }
        motorStopField.text = (newSettings!.features.contains(BaseFlightFeature.MotorStop) ?? false) ? "On" : "Off"
        
        gpsField.text = (newSettings!.features.contains(BaseFlightFeature.GPS) ?? false) ? "On" : "Off"
        vbatField.text = (newSettings!.features.contains(BaseFlightFeature.VBat) ?? false) ? "On" : "Off"
        currentMeterField.text = (newSettings!.features.contains(BaseFlightFeature.CurrentMeter) ?? false) ? "On" : "Off"
        failsafeField.text = (newSettings!.features.contains(BaseFlightFeature.Failsafe) ?? false) ? "On" : "Off"
        receiverTypeField.text = ReceiverConfigViewController.receiverConfigLabel(newSettings!)
        motorPWMFreqLabel.text = MotorPWMViewController.motorPWMLabel(newSettings!)
    }
    
    // iNav uses decidegrees instead of degrees for board alignment values. To avoid saving truncated values saving the config, we remove
    // the min or max limits to not enforce them. Hacky but should work.
    private func setBoardAlignmentFieldValue(field: NumberField, value: Double) {
        if value < field.minimumValue {
            field.minimumValue = value
        }
        if value > field.maximumValue {
            field.maximumValue = value
        }
        field.value = value
    }
    
    @IBAction func saveAction(sender: AnyObject) {
        if mixerTypePicker!.selectedIndex >= 0 {
            newSettings!.mixerConfiguration = mixerTypePicker!.selectedIndex + 1
        }
        if !isBetaflight {
            saveFeatureSwitchValue(oneShotEscSwitch, feature: .OneShot125)
        }
        newSettings!.disarmKillSwitch = disarmMotorsSwitch.on
        
        newMisc!.minCommand = Int(minimumCommandField.value)
        newMisc!.minThrottle = Int(minimumThrottleField.value)
        newSettings!.midRC = Int(midThrottleField.value)
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
        saveFeatureSwitchValue(transponderSwitch, feature: .Transponder)
        
        newSettings!.loopTime = Int(loopTimeField.value)
        
        // Betaflight
        if isBetaflight {
            newSettings!.motorPwmProtocol = escProtocolPicker!.selectedIndex
            newSettings!.gyroSyncDenom = gyroUpdateFredPicker!.selectedIndex + 1
            newSettings!.pidProcessDenom = pidLoopFreqPicker!.selectedIndex + 1
            newSettings!.accelerometerDisabled = !enableAccelerometer.on
            newSettings!.barometerDisabled = !enableBarometer.on
            newSettings!.magnetometerDisabled = !enableMagnetometer.on
            saveFeatureSwitchValue(airModeSwitch, feature: .AirMode)
            saveFeatureSwitchValue(osdSwitch, feature: .OSD)
        }
        
        SVProgressHUD.showWithStatus("Saving settings", maskType: .Black)
        enableUserInteraction(false)

        appDelegate.stopTimer()
        msp.sendSerialConfig(self.newSettings!) { success in
            if success {
                // FIXME Get rid of MSP_MISC
                self.msp.sendSetMisc(self.newMisc!, settings: self.newSettings!) { success in
                    if success {
                        self.msp.sendMixerConfiguration(self.newSettings!.mixerConfiguration) { success in
                            if success {
                                self.msp.sendSetFeature(self.newSettings!.features) { success in
                                    if success {
                                        self.msp.sendRxConfig(self.newSettings!) { success in
                                            if success {
                                                self.msp.sendBoardAlignment(self.newSettings!) { success in
                                                    if success {
                                                        self.msp.sendCurrentMeterConfig(self.newSettings!) { success in
                                                            if success {
                                                                self.msp.sendSetArmingConfig(self.newSettings!) { success in
                                                                    if success {
                                                                        self.msp.sendLoopTime(self.newSettings!) { success in
                                                                            if success {
                                                                                self.saveNewFailsafeSettings()
                                                                            } else {
                                                                                self.saveConfigFailed()
                                                                            }
                                                                        }
                                                                    } else {
                                                                        self.saveConfigFailed()
                                                                    }
                                                                }
                                                            } else {
                                                                self.saveConfigFailed()
                                                            }
                                                        }
                                                    } else {
                                                        self.saveConfigFailed()
                                                    }
                                                }
                                            } else {
                                                self.saveConfigFailed()
                                            }
                                        }
                                    } else {
                                        self.saveConfigFailed()
                                    }
                                }
                            } else {
                                self.saveConfigFailed()
                            }
                        }
                    } else {
                        self.saveConfigFailed()
                    }
                }
            } else {
                self.saveConfigFailed()
            }
        }
    }
    
    private func saveNewFailsafeSettings() {
        if Configuration.theConfig.isApiVersionAtLeast("1.16") {
            self.msp.sendRxConfig(self.newSettings!, callback: { success in
                if success {
                    self.msp.sendFailsafeConfig(self.newSettings!, callback: { success in
                        if success {
                            self.msp.sendRxFailConfig(self.newSettings!, callback: { success in
                                if success {
                                    self.saveBetaflightFeatures()
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
            self.saveBetaflightFeatures()
        }
    }
    
    private func saveBetaflightFeatures() {
        if isBetaflight {
            self.msp.sendPidAdvancedConfig(self.newSettings!, callback: { success in
                if success {
                    self.msp.sendSensorConfig(self.newSettings!, callback: { success in
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
    
    private func saveConfigFailed() {
        dispatch_async(dispatch_get_main_queue(), {
            self.appDelegate.startTimer()
            self.showError("Save failed")
            self.enableUserInteraction(true)
        })
    }
    
    private func saveFeatureSwitchValue(uiSwitch: UISwitch, feature: BaseFlightFeature) {
        if uiSwitch.on {
            newSettings!.features.insert(feature)
        } else {
            newSettings!.features.remove(feature)
        }
    }
    
    @objc
    private func mixerTypeChanged(sender: AnyObject) {
        mixerTypeView.image = MultiTypes.getImage(mixerTypePicker!.selectedIndex + 1)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        (segue.destinationViewController as! ConfigChildViewController).setReference(self, newSettings: newSettings!, newMisc: newMisc!)
        childVisible = true
    }
    
    private var isBetaflight: Bool {
        return Configuration.theConfig.isBetaflight
    }
}
