//
//  ReceiverTuningViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 14/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import DownPicker
import SVProgressHUD
import Firebase

class ReceiverTuningViewController: StaticDataTableViewController {
    @IBOutlet weak var channelMapField: UITextField!
    @IBOutlet weak var rssiChannelField: UITextField!

    @IBOutlet weak var throttleMid: NumberField!
    @IBOutlet weak var throttleExpo: NumberField!
    @IBOutlet weak var rcRate: NumberField!
    @IBOutlet weak var rcExpo: NumberField!
    @IBOutlet weak var yawRate: NumberField!
    @IBOutlet weak var yawExpo: NumberField!
    @IBOutlet weak var midRC: NumberField!
    @IBOutlet weak var rcDeadband: NumberField!
    @IBOutlet weak var yawDeadband: NumberField!
    @IBOutlet weak var interpolationTypeField: UITextField!
    @IBOutlet weak var interpolationInterval: NumberField!
    @IBOutlet var interpolationCells: [UITableViewCell]!
    @IBOutlet weak var interpolationValueCell: UITableViewCell!
    
    let DefaultRcMap = "AETR1234"
    let SpektrumRcMap = "TAER1234"
    let RcMapChoices = ["Default", "JR, Spektrum, Graupner"]
    
    var channelMapPicker: MyDownPicker?
    var rssiChannelPicker: MyDownPicker?
    var interpolationPicker: MyDownPicker?
    
    var settings: Settings?
    var rcMap: [Int]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hideSectionsWithHiddenRows = true

        channelMapPicker = MyDownPicker(textField: channelMapField, withData: RcMapChoices)
        
        rssiChannelPicker = MyDownPicker(textField: rssiChannelField)

        if Configuration.theConfig.isApiVersionAtLeast("1.31") {
            interpolationPicker = MyDownPicker(textField: interpolationTypeField, withData: ["Off", "Preset", "Auto", "Manual"])
        } else {
            cells(interpolationCells, setHidden: true)
            reloadDataAnimated(false)
        }
        
        refreshAction(self)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        saveIfNeeded()
    }
    
    func getRcMapString() -> String {
        let reference = ["A", "E", "R", "T", "1", "2", "3", "4"]
        var string = ""
        for i in 0..<8 {
            let refIdx = rcMap!.indexOf(i) ?? i
            string += reference[refIdx]
        }
        
        return string
    }
    
    @IBAction func refreshAction(sender: AnyObject) {
        chainMspCalls(msp, calls: [.MSP_RX_MAP, .MSP_RX_CONFIG, .MSP_RC_TUNING, .MSP_RSSI_CONFIG, .MSP_RC_DEADBAND]) { success in
            if success {
                self.settings = Settings(copyOf: Settings.theSettings)
                self.rcMap = Receiver.theReceiver.map
                
                var rssiChannels = [ "Disabled" ]
                for i in 0..<Receiver.theReceiver.activeChannels - 4 {
                    rssiChannels.append(String(format: "AUX %d", i + 1))
                }
                dispatch_async(dispatch_get_main_queue(), {
                    let rcMapString = self.getRcMapString()
                    switch rcMapString {
                    case self.DefaultRcMap:
                        self.channelMapPicker?.selectedIndex = 0
                    case self.SpektrumRcMap:
                        self.channelMapPicker?.selectedIndex = 1
                    default:
                        var choices = self.RcMapChoices
                        choices.append(rcMapString)
                        self.channelMapPicker!.setData(choices)
                        self.channelMapPicker?.selectedIndex = 2
                    }
                    self.rssiChannelPicker?.setData(rssiChannels)
                    
                    self.rssiChannelPicker?.selectedIndex = self.settings!.rssiChannel < 5 ? 0 : self.settings!.rssiChannel - 4
                    
                    self.throttleMid.value = self.settings!.throttleMid
                    self.throttleExpo.value = self.settings!.throttleExpo
                    
                    self.rcRate.value = self.settings!.rcRate
                    self.rcExpo.value = self.settings!.rcExpo
                    self.yawRate.value = self.settings!.yawRate
                    self.yawExpo.value = self.settings!.yawExpo
                    
                    self.midRC.value = Double(self.settings!.midRC)
                    self.rcDeadband.value = Double(self.settings!.rcDeadband)
                    self.yawDeadband.value = Double(self.settings!.yawDeadband)
                    
                    if Configuration.theConfig.isApiVersionAtLeast("1.31") {
                        self.interpolationPicker?.selectedIndex = self.settings!.rcInterpolation
                        self.interpolationInterval.value = Double(self.settings!.rcInterpolationInterval)
                        self.cell(self.interpolationValueCell, setHidden: self.interpolationPicker!.selectedIndex != 3)  // Manual
                        self.reloadDataAnimated(false)
                    }
                })
            } else {
                self.fetchError()
            }
        }
    }

    private func fetchError() {
        dispatch_async(dispatch_get_main_queue()) {
            SVProgressHUD.showErrorWithStatus("Communication error")
        }
    }

    func saveIfNeeded() {
        // Save settings
        
        if settings == nil {
            // In case we failed to fetch exiting data
            return
        }
        Analytics.logEvent("receiver_saved", parameters: nil)

        var somethingChanged = false
        
        if rssiChannelPicker!.selectedIndex >= 0 {
            let previousRssi = settings!.rssiChannel
            settings!.rssiChannel = rssiChannelPicker!.selectedIndex
            if settings!.rssiChannel > 0 {
                settings!.rssiChannel += 4
            }
            somethingChanged = somethingChanged || previousRssi != settings!.rssiChannel
        }
        
        let receiver = Receiver.theReceiver
        var newMap: [Int]?
        if channelMapPicker?.selectedIndex == 0 {
            // Default
            newMap = [ 0, 1, 3, 2, 4, 5, 6, 7 ]
        } else if channelMapPicker!.selectedIndex == 1 {
            // Spektrum
            newMap = [ 1, 2, 3, 0, 4, 5, 6, 7 ]
        }
        if newMap != nil {
            somethingChanged = somethingChanged || newMap! != receiver.map
            receiver.map = newMap!
        }
        
        // FIXME Due to rounding, these values sometimes change although the resulting saved setting is the same
        somethingChanged = somethingChanged || settings!.throttleMid != throttleMid.value
        settings!.throttleMid = throttleMid.value
        somethingChanged = somethingChanged || settings!.throttleExpo != throttleExpo.value
        settings!.throttleExpo = throttleExpo.value
        
        somethingChanged = somethingChanged || settings!.rcRate != rcRate.value
        settings!.rcRate = rcRate.value
        somethingChanged = somethingChanged || settings!.rcExpo != rcExpo.value
        settings!.rcExpo = rcExpo.value
        somethingChanged = somethingChanged || settings!.yawExpo != yawExpo.value
        settings!.yawExpo = yawExpo.value
        somethingChanged = somethingChanged || settings!.yawRate != yawRate.value
        settings!.yawRate = yawRate.value
        
        somethingChanged = somethingChanged || settings!.midRC != Int(midRC.value)
        settings!.midRC = Int(midRC.value)
        somethingChanged = somethingChanged || settings!.rcDeadband != Int(rcDeadband.value)
        settings!.rcDeadband = Int(rcDeadband.value)
        somethingChanged = somethingChanged || settings!.yawDeadband != Int(yawDeadband.value)
        settings!.yawDeadband = Int(yawDeadband.value)

        if Configuration.theConfig.isApiVersionAtLeast("1.31") {
            somethingChanged = somethingChanged || settings!.rcInterpolation != interpolationPicker!.selectedIndex
            settings!.rcInterpolation = interpolationPicker!.selectedIndex
            somethingChanged = somethingChanged || settings!.rcInterpolationInterval != Int(interpolationInterval.value)
            settings!.rcInterpolationInterval = Int(interpolationInterval.value)
        }
        
        if somethingChanged {
            msp.sendRssiConfig(settings!.rssiChannel, callback: { success in
                if !success {
                    self.showSaveFailedError()
                } else {
                    var data = [UInt8]()
                    for b in receiver.map {
                        data.append(UInt8(b))
                    }
                    self.msp.sendSetRxMap(data, callback: { success in
                        if !success {
                            self.showSaveFailedError()
                        } else {
                            self.msp.sendRxConfig(self.settings!, callback: { success in
                                if !success {
                                    self.showSaveFailedError()
                                } else {
                                    self.msp.sendSetRcTuning(self.settings!, callback: { success in
                                        if !success {
                                            self.showSaveFailedError()
                                        } else {
                                            self.msp.sendRcDeadband(self.settings!, callback: { success in
                                                if !success {
                                                    self.showSaveFailedError()
                                                } else {
                                                    self.msp.sendMessage(.MSP_EEPROM_WRITE, data: nil, retry: 2, callback: { success in
                                                        if !success {
                                                            self.showSaveFailedError()
                                                        } else {
                                                            self.showSuccess("Settings saved")
                                                        }
                                                    })
                                                }
                                            })
                                        }
                                    })
                                }
                            })
                        }
                    })
                }
            })
        }
    }
    
    func showSaveFailedError() {
        dispatch_async(dispatch_get_main_queue(), {
            Analytics.logEvent("receiver_saved_failed", parameters: nil)
            SVProgressHUD.showErrorWithStatus("Save failed")
        })
    }
    func showSuccess(msg: String) {
        dispatch_async(dispatch_get_main_queue(), {
            SVProgressHUD.showSuccessWithStatus(msg)
        })
    }
    @IBAction func interpolationTypeChanged(sender: AnyObject) {
        self.cell(interpolationValueCell, setHidden: self.interpolationPicker!.selectedIndex != 3)  // Manual
        self.reloadDataAnimated(true)
    }
}
