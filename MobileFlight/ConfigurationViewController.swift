//
//  ConfigurationViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 07/12/15.
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
import DownPicker
import SVProgressHUD
import Firebase

class ConfigurationViewController: StaticDataTableViewController, UITextFieldDelegate {
    @IBOutlet weak var mixerTypeTextField: UITextField!
    @IBOutlet weak var mixerTypeView: UIImageView!
    @IBOutlet weak var motorsReversedSwitch: UISwitch!
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
    
    @IBOutlet var conditionalCells: [ConditionalTableViewCell]!
    @IBOutlet weak var enable32kHzSwitch: UISwitch!
    @IBOutlet weak var gyroUpdateFreqField: UITextField!
    @IBOutlet weak var pidLoopFreqField: UITextField!
    @IBOutlet weak var syncPidLoopWithGyro: UISwitch!
    @IBOutlet weak var enableAccelerometer: UISwitch!
    @IBOutlet weak var enableBarometer: UISwitch!
    @IBOutlet weak var enableMagnetometer: UISwitch!
    @IBOutlet weak var enablePitotSwitch: UISwitch!
    @IBOutlet weak var enableSonarSwitch: UISwitch!
    @IBOutlet weak var airModeSwitch: UISwitch!
    @IBOutlet weak var osdSwitch: UISwitch!
    @IBOutlet weak var vtxSwitch: UISwitch!
    @IBOutlet weak var escSensor: UISwitch!
    @IBOutlet weak var antiGravitySwitch: UISwitch!
    @IBOutlet weak var dynamicFilterSwitch: UISwitch!
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
        mixerTypePicker!.addTarget(self, action: #selector(ConfigurationViewController.mixerTypeChanged(_:)), for: .valueChanged)
        
        loopTimeField.changeCallback = { value in
            if value == 0 {
                self.cyclesPerSecLabel.text = ""
            } else {
                self.cyclesPerSecLabel.text = String(format:"%.0f Hz", 1 / value * 1000 * 1000)
            }
        }
        hideSectionsWithHiddenRows = true

        for condCell in conditionalCells {
            cell(condCell, setHidden: !condCell.visible)
        }

        gyroUpdateFreqPicker = MyDownPicker(textField: gyroUpdateFreqField, withData: [ "8 kHz", "4 kHz", "2.67 kHz", "2 kHz", "1.6 kHz", "1.33 kHz", "1.14 kHz", "1 kHz" ])
        gyroUpdateFreqPicker!.addTarget(self, action: #selector(ConfigurationViewController.enable32kHzChanged(_:)), for: .valueChanged)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !childVisible {
            fetchInformation()
        } else {
            childVisible = false
        }
    }

    fileprivate func enableUserInteraction(_ enable: Bool) {
        self.tableView.isUserInteractionEnabled = enable
        self.navigationItem.rightBarButtonItem!.isEnabled = enable
    }
    
    func fetchInformation() {
        appDelegate.stopTimer()
        
        enableUserInteraction(false)
        
        if SVProgressHUD.isVisible() {
            SVProgressHUD.setStatus("Fetching information")
        }
        var mspCalls: [MSP_code] = [.msp_MIXER_CONFIG, .msp_FEATURE, .msp_RX_CONFIG, .msp_BOARD_ALIGNMENT, .msp_CURRENT_METER_CONFIG, .msp_ARMING_CONFIG, .msp_CF_SERIAL_CONFIG, .msp_VOLTAGE_METER_CONFIG]
        
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.35") && !config.isINav {    // CF 2.0 / BF 3.2
            mspCalls.append(.msp_MOTOR_CONFIG)
            mspCalls.append(.msp_BATTERY_CONFIG)
            if config.isApiVersionAtLeast("1.36") {    // CF 2.1 / BF 3.2
                mspCalls.append(.msp_BEEPER_CONFIG)
            }
        } else {
            mspCalls.append(.msp_MISC)
            mspCalls.append(.msp_LOOP_TIME)
        }
        if isBetaflightOrCleanflight2 {    // BF 3.1 / CF 2
            mspCalls.append(.msp_NAME)
        }
        
        chainMspCalls(msp, calls: mspCalls) { success in
            if success {
                if config.isApiVersionAtLeast("1.35") && !config.isINav {    // CF 2.0
                    self.msp.sendMessage(.msp_GPS_CONFIG, data: nil, retry: 2) { success in
                        self.supportsGPS = success
                        self.msp.sendMessage(.msp_COMPASS_CONFIG, data: nil, retry: 2) { success in
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
        var mspCalls: [MSP_code] = [.msp_FAILSAFE_CONFIG]
        if !Configuration.theConfig.isINav {
            mspCalls.append(.msp_RXFAIL_CONFIG)
        }
        chainMspCalls(msp, calls: mspCalls) { success in
            if success {
                self.fetchBetaflightConfig()
            } else {
                self.fetchInformationFailed()
            }
        }
    }
    
    fileprivate func fetchBetaflightConfig() {
        if !isBetaflightOrCleanflight2 && !isINav {
            fetchInformationSucceeded()
        } else {
            chainMspCalls(msp, calls: [.msp_ADVANCED_CONFIG, .msp_SENSOR_CONFIG]) { success in
                if success {
                    // SUCCESS
                    self.fetchInformationSucceeded()
                } else {
                    self.fetchInformationFailed()
                }
            }
        }
    }
    
    fileprivate func fetchInformationFailed() {
        DispatchQueue.main.async(execute: {
            self.appDelegate.startTimer()
            self.tableView.isUserInteractionEnabled = true
            self.showError("Communication error")
            
            // To avoid crashing when displaying child views
            self.newSettings = Settings(copyOf: Settings.theSettings)
            self.newMisc = Misc(copyOf: Misc.theMisc)
        })
    }
    
    fileprivate func fetchInformationSucceeded() {
        DispatchQueue.main.async(execute: {
            self.appDelegate.startTimer()
            self.enableUserInteraction(true)
            SVProgressHUD.dismiss()
            
            self.newSettings = Settings(copyOf: Settings.theSettings)
            self.newMisc = Misc(copyOf: Misc.theMisc)
            self.refreshUI(true)
        })
    }
    
    fileprivate func showError(_ message: String) {
        SVProgressHUD.showError(withStatus: message)
    }

    func refreshUI() {
        refreshUI(false)
    }
    
    fileprivate func refreshUI(_ fullRefresh: Bool) {
        if fullRefresh {
            mixerTypePicker?.selectedIndex = newSettings!.mixerConfiguration - 1
            mixerTypeChanged(self)
            motorsReversedSwitch.isOn = newSettings!.yawMotorsReversed
            
            boardPitchField.value = Double(isINav ? newSettings!.boardAlignPitch / 10 : newSettings!.boardAlignPitch)
            boardRollField.value = Double(isINav ? newSettings!.boardAlignRoll / 10 : newSettings!.boardAlignRoll)
            boardYawField.value = Double(isINav ? newSettings!.boardAlignYaw / 10 : newSettings!.boardAlignYaw)

            rssiSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.RssiAdc)
            inFlightCalSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.InflightCal)
            servoGimbalSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.ServoTilt)
            softSerialSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.SoftSerial)
            sonarSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.Sonar)
            telemetrySwitch.isOn = newSettings!.features.contains(BaseFlightFeature.Telemetry)
            threeDModeSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.ThreeD)
            ledStripSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.LedStrip)
            displaySwitch.isOn = newSettings!.features.contains(BaseFlightFeature.Display)
            blackboxSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.Blackbox)
            channelForwardingSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.ChannelForwarding)
            transponderSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.Transponder)
            
            loopTimeField.value = Double(newSettings!.loopTime)
            
            // Betaflight
            enable32kHzSwitch.isOn = newSettings!.gyroUses32KHz
            enable32kHzChanged(enable32kHzSwitch)
            gyroUpdateFreqPicker?.selectedIndex = newSettings!.gyroSyncDenom - 1
            enable32kHzChanged(enable32kHzSwitch)
            pidLoopFreqPicker?.selectedIndex = newSettings!.pidProcessDenom - 1

            enableAccelerometer.isOn = !newSettings!.accelerometerDisabled
            enableBarometer.isOn = !newSettings!.barometerDisabled
            enableMagnetometer.isOn = !newSettings!.magnetometerDisabled
            airModeSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.AirMode)
            if isINav {
                osdSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.OSD_INav)
                enablePitotSwitch.isOn = !newSettings!.pitotDisabled
                enableSonarSwitch.isOn = !newSettings!.sonarDisabled
                syncPidLoopWithGyro.isOn = newSettings!.syncLoopWithGyro
            } else if Configuration.theConfig.apiVersion == "1.25" {
                osdSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.OSD_CF1_14_2)
            } else {
                osdSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.OSD)
            }

            vtxSwitch.isOn = newSettings!.features.contains(BaseFlightFeature.VTX)
            escSensor.isOn = newSettings!.features.contains(BaseFlightFeature.ESCSensor)
            antiGravitySwitch.isOn = newSettings!.features.contains(.AntiGravity)
            dynamicFilterSwitch.isOn = newSettings!.features.contains(.DynamicFilter)
            craftNameField.text = newSettings!.craftName
        }
        
        gpsField.text = newSettings!.features.contains(BaseFlightFeature.GPS) ? "On" : "Off"
        vbatField.text = VBatConfigViewController.isVBatMonitoringEnabled(newSettings!) ? "On" : "Off"
        currentMeterField.text = CurrentConfigViewController.isCurrentMonitoringEnabled(newSettings!) ? "On" : "Off"
        failsafeField.text = FailsafeConfigViewController.isFailsafeEnabled(newSettings!) ? "On" : "Off"
        receiverTypeField.text = ReceiverConfigViewController.receiverConfigLabel(newSettings!)
    }
    
    @IBAction func saveAction(_ sender: Any) {
        Analytics.logEvent("config_saved", parameters: nil)
        
        if mixerTypePicker!.selectedIndex >= 0 {
            newSettings!.mixerConfiguration = mixerTypePicker!.selectedIndex + 1
        }
        newSettings!.yawMotorsReversed = motorsReversedSwitch.isOn

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
        newSettings!.accelerometerDisabled = !enableAccelerometer.isOn
        newSettings!.barometerDisabled = !enableBarometer.isOn
        newSettings!.magnetometerDisabled = !enableMagnetometer.isOn
        saveFeatureSwitchValue(airModeSwitch, feature: .AirMode)
        saveFeatureSwitchValue(vtxSwitch, feature: .VTX)
        saveFeatureSwitchValue(escSensor, feature: .ESCSensor)
        saveFeatureSwitchValue(antiGravitySwitch, feature: .AntiGravity)
        saveFeatureSwitchValue(dynamicFilterSwitch, feature: .DynamicFilter)
        if isBetaflightOrCleanflight2 {
            newSettings!.gyroSyncDenom = gyroUpdateFreqPicker!.selectedIndex + 1
            newSettings!.pidProcessDenom = pidLoopFreqPicker!.selectedIndex + 1
        }
        let config = Configuration.theConfig
        
        if isBetaflightOrCleanflight2 {
            newSettings!.gyroUses32KHz = enable32kHzSwitch.isOn
            if config.apiVersion == "1.25" {
                saveFeatureSwitchValue(osdSwitch, feature: .OSD_CF1_14_2)
            } else {
                saveFeatureSwitchValue(osdSwitch, feature: .OSD)
            }
        } else if isINav {
            newSettings!.pitotDisabled = !enablePitotSwitch.isOn
            newSettings!.sonarDisabled = !enableSonarSwitch.isOn
            saveFeatureSwitchValue(osdSwitch, feature: .OSD_INav)
            newSettings!.syncLoopWithGyro = syncPidLoopWithGyro.isOn
        }
        var craftName = craftNameField.text!
        if craftName.characters.count > 16 {
            let index = craftName.characters.index(craftName.startIndex, offsetBy: 16)
            craftName = craftName.substring(to: index)
            craftNameField.text = craftName
        }
        newSettings!.craftName = craftName
        
        SVProgressHUD.show(withStatus: "Saving settings", maskType: .black)
        enableUserInteraction(false)

        appDelegate.stopTimer()
        
        var commands: [SendCommand] = [
            { callback in
                self.msp.sendSerialConfig(self.newSettings!, callback: callback)
            },
            { callback in
                self.msp.sendMixerConfiguration(self.newSettings!) { success in
                    // betaflight 3.1.7 and earlier do not implement this msp call if compiled for quad only (micro scisky)
                    if (config.isBetaflight && !config.isApiVersionAtLeast("1.36")) || success {
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
        if isBetaflightOrCleanflight2 {    // BF 3.1 / CF 2
            commands.append({ callback in
                self.msp.sendCraftName(self.newSettings!.craftName, callback: callback)
            })
            if config.isApiVersionAtLeast("1.36") {
                commands.append({ callback in
                    self.msp.sendBeeperConfig(self.newSettings!.beeperMask, callback: callback)
                })
            }
        }
        chainMspSend(commands) { success in
            if success {
                self.saveMiscOrEquivalent()
            } else {
                self.saveConfigFailed()
            }
        }
    }

    fileprivate func saveMiscOrEquivalent() {
        var commands: [SendCommand]
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.35") && !config.isINav {
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
    
    fileprivate func saveNewFailsafeSettings() {
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

    fileprivate func saveINavFeatures() {
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
    
    fileprivate func saveBetaflightFeatures() {
        if isBetaflightOrCleanflight2 || isINav {
            let commands: [SendCommand] = [
                { callback in
                    self.msp.sendAdvancedConfig(self.newSettings!, callback: callback)
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
    
    fileprivate func writeToEepromAndReboot() {
        let commands: [SendCommand] = [
            { callback in
                self.msp.sendMessage(.msp_EEPROM_WRITE, data: nil, retry: 2, callback: callback)
            },
            { callback in
                DispatchQueue.main.async(execute: {
                    SVProgressHUD.setStatus("Rebooting")
                })
                self.msp.sendMessage(.msp_SET_REBOOT, data: nil, retry: 2, callback: callback)
            },
        ]
        chainMspSend(commands) { success in
            if success {
                // Wait 4 sec
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(UInt64(4000) * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC), execute: {
                    // Refetch information from FC
                    self.fetchInformation()
                })
            } else {
                self.saveConfigFailed()
            }
        }
    }
    
    fileprivate func saveConfigFailed() {
        DispatchQueue.main.async(execute: {
            Analytics.logEvent("config_saved_failed", parameters: nil)
            self.appDelegate.startTimer()
            self.showError("Save failed")
            self.enableUserInteraction(true)
        })
    }
    
    fileprivate func saveFeatureSwitchValue(_ uiSwitch: UISwitch, feature: BaseFlightFeature) {
        if uiSwitch.isOn {
            newSettings!.features.insert(feature)
        } else {
            newSettings!.features.remove(feature)
        }
    }
    
    @objc
    fileprivate func mixerTypeChanged(_ sender: Any) {
        mixerTypeView.image = MultiTypes.getImage(mixerTypePicker!.selectedIndex + 1)
    }
    
    @IBAction func enable32kHzChanged(_ sender: Any) {
        newSettings!.gyroUses32KHz = enable32kHzSwitch.isOn
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        (segue.destination as! ConfigChildViewController).setReference(self, newSettings: newSettings!, newMisc: newMisc!)
        childVisible = true
    }
    
    fileprivate var isBetaflightOrCleanflight2: Bool {
        let config = Configuration.theConfig
        return config.isApiVersionAtLeast("1.31") && !config.isINav;
    }
    
    fileprivate var isINav: Bool {
        return Configuration.theConfig.isINav
    }
}
