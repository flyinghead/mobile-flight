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
    @IBOutlet var iNavFeatures: [UITableViewCell]!
    @IBOutlet weak var enable32kHzSwitch: UISwitch!
    @IBOutlet weak var gyroUpdateFreqField: UITextField!
    @IBOutlet weak var pidLoopFreqField: UITextField!
    @IBOutlet weak var enableAccelerometer: UISwitch!
    @IBOutlet weak var enableBarometer: UISwitch!
    @IBOutlet weak var enableMagnetometer: UISwitch!
    @IBOutlet weak var enablePitotSwitch: UISwitch!
    @IBOutlet weak var airModeSwitch: UISwitch!
    @IBOutlet weak var osdSwitch: UISwitch!
    @IBOutlet weak var vtxSwitch: UISwitch!
    @IBOutlet weak var escSensor: UISwitch!
    @IBOutlet weak var pitotTubeCell: UITableViewCell!
    
    var gyroUpdateFreqPicker: MyDownPicker?
    var pidLoopFreqPicker: MyDownPicker?
    
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

        if isBetaflight {
            cells(nonBetaflightFeatures, setHidden: true)
            cells(Array(Set(iNavFeatures).subtract(Set(betaflightFeatures))), setHidden: true)
        } else if isINav {
            cells(nonBetaflightFeatures, setHidden: true)
            cells(Array(Set(betaflightFeatures).subtract(Set(iNavFeatures))), setHidden: true)
        } else {
            cells(Array(Set(betaflightFeatures).union(Set(iNavFeatures))), setHidden: true)
        }

        gyroUpdateFreqPicker = MyDownPicker(textField: gyroUpdateFreqField, withData: [ "8 KHz", "4 KHz", "2.67 KHz", "2 KHz", "1.6 KHz", "1.33 KHz", "1.14 KHz", "1 KHz" ])
        gyroUpdateFreqPicker!.setPlaceholder("")
        gyroUpdateFreqPicker!.addTarget(self, action: #selector(ConfigurationViewController.enable32kHzChanged(_:)), forControlEvents: .ValueChanged)
        pidLoopFreqPicker = MyDownPicker(textField: pidLoopFreqField, withData: [ "2 KHz", "1 KHz", "0.67 KHz", "0.5 KHz", "0.4 KHz", "0.33 KHz", "0.29 KHz", "0.25 KHz" ])
        pidLoopFreqPicker!.setPlaceholder("")

        if !Configuration.theConfig.isINav {
            cell(pitotTubeCell, setHidden: true)
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
        var mspCalls: [MSP_code] = [.MSP_MIXER_CONFIG, .MSP_FEATURE, .MSP_RX_CONFIG, .MSP_BOARD_ALIGNMENT, .MSP_CURRENT_METER_CONFIG, .MSP_ARMING_CONFIG, .MSP_CF_SERIAL_CONFIG, .MSP_VOLTAGE_METER_CONFIG]
        
        if Configuration.theConfig.isApiVersionAtLeast("1.35") {    // CF 2.0
            mspCalls.appendContentsOf([.MSP_MOTOR_CONFIG, /* .MSP_GPS_CONFIG, */ .MSP_COMPASS_CONFIG])      // FIXME CF 2.0 not compiled with GPS
        } else {
            mspCalls.append(.MSP_MISC)
            mspCalls.append(.MSP_LOOP_TIME)
        }
        
        chainMspCalls(msp, calls: mspCalls) { success in
            if success {
                self.fetchFailsafeConfig()
            } else {
                self.fetchInformationFailed()
            }
        }
    }
        
    func fetchFailsafeConfig() {
        var mspCalls: [MSP_code] = [.MSP_FAILSAFE_CONFIG]
        if !Configuration.theConfig.isINav {
            mspCalls.append(.MSP_RXFAIL_CONFIG)
        }
        chainMspCalls(msp, calls: mspCalls) { success in
            if success {
                self.fetchBetaflightConfig()
            } else {
                self.fetchInformationFailed()
            }
        }
    }
    
    private func fetchBetaflightConfig() {
        if !isBetaflight && !Configuration.theConfig.isINav {
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
            enable32kHzSwitch.on = newSettings!.gyroUses32KHz
            enable32kHzChanged(enable32kHzSwitch)
            gyroUpdateFreqPicker?.selectedIndex = newSettings!.gyroSyncDenom - 1
            enable32kHzChanged(enable32kHzSwitch)
            pidLoopFreqPicker?.selectedIndex = newSettings!.pidProcessDenom - 1

            enableAccelerometer.on = !newSettings!.accelerometerDisabled
            enableBarometer.on = !newSettings!.barometerDisabled
            enableMagnetometer.on = !newSettings!.magnetometerDisabled
            airModeSwitch.on = newSettings!.features.contains(BaseFlightFeature.AirMode)
            if isINav {
                osdSwitch.on = newSettings!.features.contains(BaseFlightFeature.OSD_INav)
            } else {
                osdSwitch.on = newSettings!.features.contains(BaseFlightFeature.OSD)
            }

            vtxSwitch.on = newSettings!.features.contains(BaseFlightFeature.VTX)
            escSensor.on = newSettings!.features.contains(BaseFlightFeature.ESCSensor)
        }
        
        gpsField.text = (newSettings!.features.contains(BaseFlightFeature.GPS) ?? false) ? "On" : "Off"
        vbatField.text = (newSettings!.features.contains(BaseFlightFeature.VBat) ?? false) ? "On" : "Off"
        currentMeterField.text = (newSettings!.features.contains(BaseFlightFeature.CurrentMeter) ?? false) ? "On" : "Off"
        failsafeField.text = (newSettings!.features.contains(BaseFlightFeature.Failsafe) ?? false) ? "On" : "Off"
        receiverTypeField.text = ReceiverConfigViewController.receiverConfigLabel(newSettings!)
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
        
        // Betaflight, INav, CF 2
        newSettings!.accelerometerDisabled = !enableAccelerometer.on
        newSettings!.barometerDisabled = !enableBarometer.on
        newSettings!.magnetometerDisabled = !enableMagnetometer.on
        saveFeatureSwitchValue(airModeSwitch, feature: .AirMode)
        saveFeatureSwitchValue(vtxSwitch, feature: .VTX)
        saveFeatureSwitchValue(escSensor, feature: .ESCSensor)
        if isBetaflight || isINav {
            newSettings!.gyroSyncDenom = gyroUpdateFreqPicker!.selectedIndex + 1
            newSettings!.pidProcessDenom = pidLoopFreqPicker!.selectedIndex + 1
        }
        if isBetaflight {
            newSettings!.gyroUses32KHz = enable32kHzSwitch.on
            saveFeatureSwitchValue(osdSwitch, feature: .OSD)
        } else if isINav {
            // FIXME newSettings!.pitotDisabled = !enablePitotSwitch.on
            saveFeatureSwitchValue(osdSwitch, feature: .OSD_INav)
        }
        
        SVProgressHUD.showWithStatus("Saving settings", maskType: .Black)
        enableUserInteraction(false)

        appDelegate.stopTimer()
        msp.sendSerialConfig(self.newSettings!) { success in
            if success {
                self.msp.sendMixerConfiguration(self.newSettings!.mixerConfiguration) { success in
                    if success {
                        self.msp.sendSetFeature(self.newSettings!.features) { success in
                            if success {
                                self.msp.sendBoardAlignment(self.newSettings!) { success in
                                    if success {
                                        self.msp.sendCurrentMeterConfig(self.newSettings!) { success in
                                            if success {
                                                self.msp.sendSetArmingConfig(self.newSettings!) { success in
                                                    if success {
                                                        // FIXME removed in CF2 / BF 3.1.8
                                                        self.msp.sendLoopTime(self.newSettings!) { success in
                                                            if success {
                                                                self.msp.sendVoltageMeterConfig(self.newSettings!) { success in
                                                                    if success {
                                                                        self.saveMiscOrEquivalent()
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

    private func saveMiscOrEquivalent() {
        if Configuration.theConfig.isApiVersionAtLeast("1.35") {
            msp.sendMotorConfig(self.newSettings!) { success in
                if success {
//                    self.msp.sendGpsConfig(self.newSettings!) { success in    // FIXME CF 2.0 not compiled with GPS
//                        if success {
                            self.msp.sendRssiConfig(self.newSettings!.rssiChannel) { success in
                                if success {
                                    self.msp.sendCompassConfig(self.newSettings!.magDeclination) { success in
                                        if success {
                                            self.msp.sendBatteryConfig(self.newSettings!) { success in
                                                if success {
                                                    self.msp.sendVoltageMeterConfig(self.newSettings!) { success in
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
//                        } else {
//                            self.saveConfigFailed()
//                        }
//                    }
                } else {
                    self.saveConfigFailed()
                }
            }
        } else {
            msp.sendSetMisc(self.newMisc!, settings: self.newSettings!) { success in
                if success {
                    self.saveNewFailsafeSettings()
                } else {
                    self.saveConfigFailed()
                }
            }
        }
    }
    
    private func saveNewFailsafeSettings() {
        self.msp.sendRxConfig(self.newSettings!, callback: { success in
            if success {
                self.msp.sendFailsafeConfig(self.newSettings!, callback: { success in
                    if success {
                        self.saveINavFeatures()
                    } else {
                        self.saveConfigFailed()
                    }
                })
            } else {
                self.saveConfigFailed()
            }
        })
    }

    private func saveINavFeatures() {
        if isINav {
            saveBetaflightFeatures()
        } else {
            self.msp.sendRxFailConfig(self.newSettings!) { success in
                if success {
                    self.saveBetaflightFeatures()
                } else {
                    self.saveConfigFailed()
                }
            }
        }
    }
    
    private func saveBetaflightFeatures() {
        if isBetaflight || Configuration.theConfig.isINav {
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
    
    @IBAction func enable32kHzChanged(sender: AnyObject) {
        newSettings!.gyroUses32KHz = enable32kHzSwitch.on
        let maxFreq = isINav ? 1.0 : newSettings!.gyroUses32KHz ? 32.0 : 8.0
        var gyroFreqs = [String]()
        let currentFreq = maxFreq / Double(gyroUpdateFreqPicker!.selectedIndex + 1)
        let gyroIndex = gyroUpdateFreqPicker!.selectedIndex
        for i in 1..<33 {
            gyroFreqs.append(String(format: "%.2f kHz", maxFreq / Double(i)))
        }
        let pidIndex = pidLoopFreqPicker!.selectedIndex
        var pidFreqs = [String]()
        for i in 1..<17 {
            pidFreqs.append(String(format: "%.2f kHz", currentFreq / Double(i)))
        }
        gyroUpdateFreqPicker!.setData(gyroFreqs)
        pidLoopFreqPicker!.setData(pidFreqs)
        gyroUpdateFreqPicker!.selectedIndex = gyroIndex
        pidLoopFreqPicker!.selectedIndex = pidIndex
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        (segue.destinationViewController as! ConfigChildViewController).setReference(self, newSettings: newSettings!, newMisc: newMisc!)
        childVisible = true
    }
    
    private var isBetaflight: Bool {
        return Configuration.theConfig.isBetaflight
    }
    
    private var isINav: Bool {
        return Configuration.theConfig.isINav
    }
}
