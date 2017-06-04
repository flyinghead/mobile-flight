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
import Firebase

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
    @IBOutlet weak var enableSonarSwitch: UISwitch!
    @IBOutlet weak var airModeSwitch: UISwitch!
    @IBOutlet weak var osdSwitch: UISwitch!
    @IBOutlet weak var vtxSwitch: UISwitch!
    @IBOutlet weak var escSensor: UISwitch!
    @IBOutlet weak var craftNameField: UITextField!
    
    var gyroUpdateFreqPicker: MyDownPicker?
    var pidLoopFreqPicker: MyDownPicker?
    
    var mixerTypePicker: MyDownPicker?
    
    var newSettings: Settings?
    var newMisc: Misc?
    var childVisible = false
    var supportsGPS = true
    var supportsMagnetometer = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mixerTypePicker = MyDownPicker(textField: mixerTypeTextField, withData: MultiTypes.label)
        mixerTypePicker!.addTarget(self, action: #selector(ConfigurationViewController.mixerTypeChanged(_:)), forControlEvents: .ValueChanged)
        
        loopTimeField.changeCallback = { value in
            if value == 0 {
                self.cyclesPerSecLabel.text = ""
            } else {
                self.cyclesPerSecLabel.text = String(format:"%.0f Hz", 1 / value * 1000 * 1000)
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

        gyroUpdateFreqPicker = MyDownPicker(textField: gyroUpdateFreqField, withData: [ "8 kHz", "4 kHz", "2.67 kHz", "2 kHz", "1.6 kHz", "1.33 kHz", "1.14 kHz", "1 kHz" ])
        gyroUpdateFreqPicker!.addTarget(self, action: #selector(ConfigurationViewController.enable32kHzChanged(_:)), forControlEvents: .ValueChanged)
        pidLoopFreqPicker = MyDownPicker(textField: pidLoopFreqField, withData: [ "2 kHz", "1 kHz", "0.67 kHz", "0.5 kHz", "0.4 kHz", "0.33 kHz", "0.29 kHz", "0.25 kHz" ])

        if Configuration.theConfig.isINav {
            boardRollField.increment = 0.1
            boardRollField.decimalDigits = 1
            boardPitchField.increment = 0.1
            boardPitchField.decimalDigits = 1
            boardYawField.increment = 0.1
            boardYawField.decimalDigits = 1
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
        
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.35") {    // CF 2.0 / BF 3.2
            mspCalls.append(.MSP_MOTOR_CONFIG)
            mspCalls.append(.MSP_BATTERY_CONFIG)
        } else {
            mspCalls.append(.MSP_MISC)
            mspCalls.append(.MSP_LOOP_TIME)
        }
        if config.isApiVersionAtLeast("1.31") {    // BF 3.1
            mspCalls.append(.MSP_NAME)
        }
        
        chainMspCalls(msp, calls: mspCalls) { success in
            if success {
                if config.isApiVersionAtLeast("1.35") {    // CF 2.0
                    self.msp.sendMessage(.MSP_GPS_CONFIG, data: nil, retry: 2) { success in
                        self.supportsGPS = success
                        self.msp.sendMessage(.MSP_COMPASS_CONFIG, data: nil, retry: 2) { success in
                            self.supportsMagnetometer = success
                            self.fetchFailsafeConfig()
                        }
                    }
                } else {
                    self.fetchFailsafeConfig()
                }
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
        if !isBetaflight && !isINav {
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
            
            boardPitchField.value = Double(isINav ? newSettings!.boardAlignPitch / 10 : newSettings!.boardAlignPitch)
            boardRollField.value = Double(isINav ? newSettings!.boardAlignRoll / 10 : newSettings!.boardAlignRoll)
            boardYawField.value = Double(isINav ? newSettings!.boardAlignYaw / 10 : newSettings!.boardAlignYaw)

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
                enablePitotSwitch.on = !newSettings!.pitotDisabled
                enableSonarSwitch.on = !newSettings!.sonarDisabled
            } else {
                osdSwitch.on = newSettings!.features.contains(BaseFlightFeature.OSD)
            }

            vtxSwitch.on = newSettings!.features.contains(BaseFlightFeature.VTX)
            escSensor.on = newSettings!.features.contains(BaseFlightFeature.ESCSensor)
            craftNameField.text = newSettings!.craftName
        }
        
        gpsField.text = (newSettings!.features.contains(BaseFlightFeature.GPS) ?? false) ? "On" : "Off"
        vbatField.text = (newSettings!.features.contains(BaseFlightFeature.VBat) ?? false) ? "On" : "Off"
        currentMeterField.text = (newSettings!.features.contains(BaseFlightFeature.CurrentMeter) ?? false) ? "On" : "Off"
        failsafeField.text = (newSettings!.features.contains(BaseFlightFeature.Failsafe) ?? false) ? "On" : "Off"
        receiverTypeField.text = ReceiverConfigViewController.receiverConfigLabel(newSettings!)
    }
    
    @IBAction func saveAction(sender: AnyObject) {
        Analytics.logEvent("config_saved", parameters: nil)
        
        if mixerTypePicker!.selectedIndex >= 0 {
            newSettings!.mixerConfiguration = mixerTypePicker!.selectedIndex + 1
        }

        newSettings!.boardAlignPitch = Int(round(isINav ? boardPitchField.value * 10 : boardPitchField.value))
        newSettings!.boardAlignRoll = Int(round(isINav ? boardRollField.value * 10 : boardRollField.value))
        newSettings!.boardAlignYaw = Int(round(isINav ? boardYawField.value * 10 : boardYawField.value))
        
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
            newSettings!.pitotDisabled = !enablePitotSwitch.on
            newSettings!.sonarDisabled = !enableSonarSwitch.on
            saveFeatureSwitchValue(osdSwitch, feature: .OSD_INav)
        }
        var craftName = craftNameField.text!
        if craftName.characters.count > 16 {
            let index = craftName.startIndex.advancedBy(16)
            craftName = craftName.substringToIndex(index)
            craftNameField.text = craftName
        }
        newSettings!.craftName = craftName
        
        SVProgressHUD.showWithStatus("Saving settings", maskType: .Black)
        enableUserInteraction(false)

        appDelegate.stopTimer()
        
        var commands: [SendCommand] = [
            { callback in
                self.msp.sendSerialConfig(self.newSettings!, callback: callback)
            },
            { callback in
                self.msp.sendMixerConfiguration(self.newSettings!.mixerConfiguration) { success in
                    // betaflight 3.1.7 and earlier do not implement this msp call if compiled for quad only (micro scisky)
                    if self.isBetaflight || success {
                        callback(true)
                    } else {
                        callback(false)
                    }
                }
            },
            { callback in
                self.msp.sendSetFeature(self.newSettings!.features, callback: callback)
            },
            { callback in
                self.msp.sendBoardAlignment(self.newSettings!, callback: callback)
            },
            { callback in
                self.msp.sendCurrentMeterConfig(self.newSettings!, callback: callback)
            },
            { callback in
                self.msp.sendSetArmingConfig(self.newSettings!, callback: callback)
            },
            { callback in
                self.msp.sendVoltageMeterConfig(self.newSettings!, callback: callback)
            }
        ]
        if Configuration.theConfig.isApiVersionAtLeast("1.31") {    // BF 3.1
            commands.append({ callback in
                self.msp.sendCraftName(self.newSettings!.craftName, callback: callback)
            })
        }
        chainMspSend(commands) { success in
            if success {
                self.saveMiscOrEquivalent()
            } else {
                self.saveConfigFailed()
            }
        }
    }

    private func saveMiscOrEquivalent() {
        var commands: [SendCommand]
        if Configuration.theConfig.isApiVersionAtLeast("1.35") {
            commands = [
                { callback in
                    self.msp.sendMotorConfig(self.newSettings!, callback: callback)
                },
                { callback in
                    self.msp.sendRssiConfig(self.newSettings!.rssiChannel, callback: callback)
                },
                { callback in
                    self.msp.sendBatteryConfig(self.newSettings!, callback: callback)
                },
                { callback in
                    self.msp.sendVoltageMeterConfig(self.newSettings!, callback: callback)
                },
            ]
            if supportsGPS {
                commands.append({ callback in
                    self.msp.sendGpsConfig(self.newSettings!, callback: callback)
                })
            }
            if supportsMagnetometer {
                commands.append({ callback in
                    self.msp.sendCompassConfig(self.newSettings!.magDeclination, callback: callback)
                })
            }
        } else {
            commands = [
                { callback in
                    self.msp.sendSetMisc(self.newSettings!, callback: callback)
                },
                { callback in
                    self.msp.sendLoopTime(self.newSettings!, callback: callback)
                },
            ]
        }
        chainMspSend(commands) { success in
            if success {
                self.saveNewFailsafeSettings()
            } else {
                self.saveConfigFailed()
            }
        }
    }
    
    private func saveNewFailsafeSettings() {
        let commands: [SendCommand] = [
            { callback in
                self.msp.sendRxConfig(self.newSettings!, callback: callback)
            },
            { callback in
                self.msp.sendFailsafeConfig(self.newSettings!, callback: callback)
            },
        ]
        chainMspSend(commands) { success in
            if success {
                self.saveINavFeatures()
            } else {
                self.saveConfigFailed()
            }
        }
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
        if isBetaflight || isINav {
            let commands: [SendCommand] = [
                { callback in
                    self.msp.sendPidAdvancedConfig(self.newSettings!, callback: callback)
                },
                { callback in
                    self.msp.sendSensorConfig(self.newSettings!, callback: callback)
                },
            ]
            chainMspSend(commands) { success in
                if success {
                    self.writeToEepromAndReboot()
                } else {
                    self.saveConfigFailed()
                }
            }
        } else {
            self.writeToEepromAndReboot()
        }
    }
    
    private func writeToEepromAndReboot() {
        let commands: [SendCommand] = [
            { callback in
                self.msp.sendMessage(.MSP_EEPROM_WRITE, data: nil, retry: 2, callback: callback)
            },
            { callback in
                dispatch_async(dispatch_get_main_queue(), {
                    SVProgressHUD.setStatus("Rebooting")
                })
                self.msp.sendMessage(.MSP_SET_REBOOT, data: nil, retry: 2, callback: callback)
            },
        ]
        chainMspSend(commands) { success in
            if success {
                // Wait 4 sec
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(4000) * NSEC_PER_MSEC)), dispatch_get_main_queue(), {
                    // Refetch information from FC
                    self.fetchInformation()
                })
            } else {
                self.saveConfigFailed()
            }
        }
    }
    
    private func saveConfigFailed() {
        dispatch_async(dispatch_get_main_queue(), {
            Analytics.logEvent("config_saved_failed", parameters: nil)
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
