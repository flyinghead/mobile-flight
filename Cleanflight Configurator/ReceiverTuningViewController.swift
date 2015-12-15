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

class ReceiverTuningViewController: UITableViewController, BackButtonListener {
    @IBOutlet weak var channelMapField: UITextField!
    @IBOutlet weak var rssiChannelField: UITextField!

    @IBOutlet weak var throttleMid: NumberField!
    @IBOutlet weak var throttleExpo: NumberField!
    @IBOutlet weak var rcRate: NumberField!
    @IBOutlet weak var rcExpo: NumberField!
    @IBOutlet weak var yawExpo: NumberField!
    
    let DefaultRcMap = "AETR1234"
    let SpektrumRcMap = "TAER1234"
    
    var channelMapPicker: DownPicker?
    var rssiChannelPicker: DownPicker?
    
    var settings: Settings?
    var rcMap: [Int]?
    var rssiChannel = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        channelMapPicker = DownPicker(textField: channelMapField, withData: ["Default", "JR, Spektrum, Graupner"])
        
        refreshAction(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getRcMapString() -> String {
        let reference = ["A", "E", "R", "T", "1", "2", "3", "4"]
        var string = ""
        for var i = 0; i < 8; i++ {
            let refIdx = rcMap!.indexOf(i) ?? i
            string += reference[refIdx]
        }
        
        return string
    }
    
    @IBAction func refreshAction(sender: AnyObject) {
        rssiChannelPicker = DownPicker(textField: rssiChannelField)
        msp.sendMessage(.MSP_RX_MAP, data: nil, retry: 2, callback: { success in
            if success {
                self.msp.sendMessage(.MSP_RC_TUNING, data: nil, retry: 2, callback: { success in
                    if success {
                        self.msp.sendMessage(.MSP_MISC, data: nil, retry: 2, callback: { success in
                            if success {
                                self.msp.sendMessage(.MSP_RC, data: nil, retry: 2, callback: { success in
                                    if success {
                                        self.settings = Settings(copyOf: Settings.theSettings)
                                        self.rcMap = Receiver.theReceiver.map
                                        self.rssiChannel = Misc.theMisc.rssiChannel
                                        NSLog("Received rcMap=%@", self.rcMap!)
                                        
                                        var rssiChannels = [ "Disabled" ]
                                        for var i = 0; i < Receiver.theReceiver.activeChannels - 4; i++ {
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
                                                self.channelMapPicker!.setData(["Default", "JR, Spektrum, Graupner", rcMapString])
                                                self.channelMapPicker?.selectedIndex = 2
                                            }
                                            self.rssiChannelPicker?.setData(rssiChannels)
                                            
                                            self.rssiChannelPicker?.selectedIndex = self.rssiChannel < 5 ? 0 : self.rssiChannel - 4
                                            
                                            self.throttleMid.value = self.settings!.throttleMid
                                            self.throttleExpo.value = self.settings!.throttleExpo
                                            
                                            self.rcRate.value = self.settings!.rcRate
                                            self.rcExpo.value = self.settings!.rcExpo
                                            self.yawExpo.value = self.settings!.yawExpo
                                            
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
    
    func backButtonTapped() {
        // Save settings
        let misc = Misc.theMisc
        misc.rssiChannel = self.rssiChannelPicker!.selectedIndex
        if misc.rssiChannel > 0 {
            misc.rssiChannel += 4
        }
        let receiver = Receiver.theReceiver
        if channelMapPicker?.selectedIndex == 0 {
            // Default
            receiver.map = [ 0, 1, 3, 2, 4, 5, 6, 7 ]
        } else if channelMapPicker!.selectedIndex == 1 {
            // Spektrum
            receiver.map = [ 1, 2, 3, 0, 4, 5, 6, 7 ]
        }
        self.settings!.throttleMid = self.throttleMid.value
        self.settings!.throttleExpo = self.throttleExpo.value
        
        self.settings!.rcRate = self.rcRate.value
        self.settings!.rcExpo = self.rcExpo.value
        self.settings!.yawExpo = self.yawExpo.value
        
        msp.sendSetMisc(misc, callback: { success in
            if !success {
                SVProgressHUD.showErrorWithStatus("Save failed")
            } else {
                var data = [UInt8]()
                for b in receiver.map {
                    data.append(UInt8(b))
                }
                self.msp.sendSetRxMap(data, callback: { success in
                    if !success {
                        SVProgressHUD.showErrorWithStatus("Save failed")
                    } else {
                        self.msp.sendSetRcTuning(self.settings!, callback: { success in
                            if !success {
                                SVProgressHUD.showErrorWithStatus("Save failed")
                            } else {
                                self.msp.sendMessage(.MSP_EEPROM_WRITE, data: nil, retry: 2, callback: { success in
                                    if !success {
                                        SVProgressHUD.showErrorWithStatus("Save failed")
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
