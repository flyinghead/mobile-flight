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

class ReceiverTuningViewController: UITableViewController {
    @IBOutlet weak var channelMapField: UITextField!
    @IBOutlet weak var rssiChannelField: UITextField!

    @IBOutlet weak var throttleMid: NumberField!
    @IBOutlet weak var throttleExpo: NumberField!
    @IBOutlet weak var rcRate: NumberField!
    @IBOutlet weak var rcExpo: NumberField!
    @IBOutlet weak var yawExpo: NumberField!
    
    let DefaultRcMap = "AETR1234"
    let SpektrumRcMap = "TAER1234"
    let RcMapChoices = ["Default", "JR, Spektrum, Graupner"]
    
    var channelMapPicker: MyDownPicker?
    var rssiChannelPicker: MyDownPicker?
    
    var settings: Settings?
    var rcMap: [Int]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        channelMapPicker = MyDownPicker(textField: channelMapField, withData: RcMapChoices)
        channelMapPicker!.setPlaceholder("")
        
        rssiChannelPicker = MyDownPicker(textField: rssiChannelField)
        rssiChannelPicker!.setPlaceholder("")
        
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
        msp.sendMessage(.MSP_RX_MAP, data: nil, retry: 2, callback: { success in
            if success {
                self.msp.sendMessage(.MSP_RC_TUNING, data: nil, retry: 2, callback: { success in
                    if success {
                        self.msp.sendMessage(.MSP_RSSI_CONFIG, data: nil, retry: 2, callback: { success in
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
                                    self.yawExpo.value = self.settings!.yawExpo
                                    
                                })
                            } else {
                                self.fetchError()
                            }
                        })
                    } else {
                        self.fetchError()
                    }
                })
            } else {
                self.fetchError()
            }
        })
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
                            self.msp.sendSetRcTuning(self.settings!, callback: { success in
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
    }
    
    func showSaveFailedError() {
        dispatch_async(dispatch_get_main_queue(), {
            SVProgressHUD.showErrorWithStatus("Save failed")
        })
    }
    func showSuccess(msg: String) {
        dispatch_async(dispatch_get_main_queue(), {
            SVProgressHUD.showSuccessWithStatus(msg)
        })
    }
}
