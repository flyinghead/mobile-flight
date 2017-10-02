//
//  DataflashController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 18/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import SVProgressHUD
import Firebase

class DataflashController: StaticDataTableViewController {
    @IBOutlet weak var deviceField: UITextField!
    @IBOutlet weak var rateField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var gauge: LinearGauge!
    @IBOutlet weak var usedLabel: UILabel!
    @IBOutlet weak var freeLabel: UILabel!
    @IBOutlet weak var eraseButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton?
    @IBOutlet weak var eraseCell: UITableViewCell!
    @IBOutlet weak var sdcardStateCell: UITableViewCell!
    @IBOutlet weak var sdcardStateImage: UIImageView!
    @IBOutlet weak var sdcardStateLabel: UILabel!

    private var devicePicker: MyDownPicker!
    private var ratePicker: MyDownPicker!
    private var deviceValues: [Int]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        eraseButton.layer.borderColor = eraseButton.tintColor.CGColor
        saveButton.layer.borderColor = saveButton.tintColor.CGColor
        downloadButton?.layer.borderColor = downloadButton?.tintColor.CGColor

        devicePicker = MyDownPicker(textField: deviceField)
        ratePicker = MyDownPicker(textField: rateField)
        setDeviceOptions()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateSummary()
    }
    
    private func setDeviceOptions() {
        let dataflash = Dataflash.theDataflash
        var deviceChoices: [String]
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.33") && !config.isINav {
            deviceChoices = [ "None" ]
            deviceValues = [ 0 ]
            if dataflash.ready {
                deviceChoices.append("On-board dataflash")
                deviceValues.append(1)
            }
            if dataflash.sdcardSupported {
                deviceChoices.append("SD Card")
                deviceValues.append(2)
            }
            deviceChoices.append("Serial port")
            deviceValues.append(3)
        } else {
            deviceChoices = [ "Serial port" ]
            deviceValues = [ 0 ]
            if dataflash.ready {
                deviceChoices.append("On-board dataflash")
                deviceValues.append(1)
            }
            if dataflash.sdcardSupported {
                deviceChoices.append("SD Card")
                deviceValues.append(2)
            }
        }
        devicePicker.setData(deviceChoices)
        
        let settings = Settings.theSettings
        let freq: Double
        if Configuration.theConfig.isApiVersionAtLeast("1.24") && settings.gyroSyncDenom > 0 && Double(settings.pidProcessDenom) > 0 {
            freq = (settings.gyroUses32KHz ? 32000.0 : 8000.0) / Double(settings.gyroSyncDenom) / Double(settings.pidProcessDenom)
        } else if settings.loopTime > 0 {
            freq = 1000000 / Double(settings.loopTime)
        } else {
            freq = 1000000
        }
        var rates = [String]()
        for i in [ 1, 2, 3, 4, 5, 6, 7, 8, 16, 32 ] {
            var f = freq / Double(i)
            let percent = Int(round(100/Double(i)))
            let formatted: String
            if f >= 1000 {
                f /= 1000
                formatted = String(format: "%.1f kHz (%d%%)", f, percent)
            } else {
                formatted = String(format: "%.0f Hz (%d%%)", f, percent)
            }
            rates.append(formatted)
        }
        ratePicker.setData(rates)

    }
    
    private func updateSummary() {
        chainMspCalls(msp, calls: [ .MSP_ADVANCED_CONFIG, .MSP_LOOP_TIME, .MSP_BLACKBOX_CONFIG, .MSP_DATAFLASH_SUMMARY, .MSP_SDCARD_SUMMARY ], ignoreFailure: true) { success in
            dispatch_async(dispatch_get_main_queue()) {
                SVProgressHUD.dismiss()
                self.setDeviceOptions()
                let dataflash = Dataflash.theDataflash
                
                self.devicePicker.selectedIndex = self.deviceValues.indexOf(dataflash.blackboxDevice) ?? -1
                if dataflash.blackboxRateNum > 1 {
                    self.ratePicker.selectedIndex = -1
                } else {
                    switch dataflash.blackboxRateDenom {
                    case 1:
                        self.ratePicker.selectedIndex = 0
                    case 2:
                        self.ratePicker.selectedIndex = 1
                    case 3:
                        self.ratePicker.selectedIndex = 2
                    case 4:
                        self.ratePicker.selectedIndex = 3
                    case 5:
                        self.ratePicker.selectedIndex = 4
                    case 6:
                        self.ratePicker.selectedIndex = 5
                    case 7:
                        self.ratePicker.selectedIndex = 6
                    case 8:
                        self.ratePicker.selectedIndex = 7
                    case 16:
                        self.ratePicker.selectedIndex = 8
                    case 32:
                        self.ratePicker.selectedIndex = 9
                    default:
                        self.ratePicker.selectedIndex = -1
                    }
                }
                self.saveButton.enabled = dataflash.blackboxSupported
                
                if dataflash.totalSize > 0 {
                    self.gauge.maximumValue = Double(dataflash.totalSize)
                    self.gauge.value = Double(dataflash.usedSize)
                    self.usedLabel.text = String(format: "Used: %@", NSByteCountFormatter().stringFromByteCount(Int64(dataflash.usedSize)))
                    self.freeLabel.text = String(format: "Free: %@", NSByteCountFormatter().stringFromByteCount(Int64(dataflash.totalSize - dataflash.usedSize)))
                    self.eraseButton.enabled = true
                    self.downloadButton?.enabled = true
                    self.cell(self.sdcardStateCell, setHidden: true)
                } else if dataflash.sdcardSupported {
                    self.gauge.maximumValue = Double(dataflash.sdcardTotalSpace)
                    self.gauge.value = Double(dataflash.sdcardTotalSpace - dataflash.sdcardFreeSpace)
                    self.usedLabel.text = String(format: "Used: %@", NSByteCountFormatter().stringFromByteCount(dataflash.sdcardTotalSpace - dataflash.sdcardFreeSpace))
                    self.freeLabel.text = String(format: "Free: %@", NSByteCountFormatter().stringFromByteCount(dataflash.sdcardFreeSpace))
                    switch dataflash.sdcardState {
                    case 0:
                        self.sdcardStateLabel.text = "No card inserted"
                        self.sdcardStateImage.image = UIImage(named: "crossmark")
                    case 1:
                        self.sdcardStateLabel.text = "Card error"
                        self.sdcardStateImage.image = UIImage(named: "crossmark")
                    case 2:
                        self.sdcardStateLabel.text = "Card initializing..."
                        self.sdcardStateImage.image = UIImage(named: "crossmark")
                    case 3:
                        self.sdcardStateLabel.text = "File system initializing..."
                        self.sdcardStateImage.image = UIImage(named: "crossmark")
                    case 4:
                        self.sdcardStateLabel.text = "Card ready"
                        self.sdcardStateImage.image = UIImage(named: "checkmark")
                    default:
                        self.sdcardStateLabel.text = "Unknown state"
                        self.sdcardStateImage.image = UIImage(named: "crossmark")
                    }
                    self.eraseButton.enabled = false
                    self.downloadButton?.enabled = false
                    self.cell(self.eraseCell, setHidden: true)
                } else {
                    self.sdcardStateLabel.text = "No dataflash memory or SD Card"
                    self.sdcardStateImage.image = nil
                    self.usedLabel.text = ""
                    self.freeLabel.text = ""
                    self.gauge.maximumValue = 1.0
                    self.gauge.value = 0.0
                    self.eraseButton.enabled = false
                    self.downloadButton?.enabled = false
                    self.cell(self.eraseCell, setHidden: true)
                }
                self.reloadDataAnimated(false)
            }
        }
    }
    
    @IBAction func downloadAction(sender: AnyObject) {
        appDelegate.stopTimer()
        downloadAddress(0)
    }
    
    func downloadAddress(address: Int) {
        NSLog("Reading address %d", address)
        msp.sendDataflashRead(address, callback: { data in
            var done = true
            if data == nil {
                NSLog("Error!")
            } else if data!.count == 0 {
                NSLog("Done. Success!")
            } else {
                NSLog("Received address %d size %d", readUInt32(data!, index: 0), data!.count - 4)
                let nextAddress = address + data!.count - 4
                if (nextAddress > Dataflash.theDataflash.usedSize) {
                    NSLog("Done (> usedSize). Success!")
                } else {
                    done = false
                    self.downloadAddress(nextAddress)
                }
            }
            if done {
                self.appDelegate.startTimer()
            }
        })
    }

    func eraseTimer(timer: NSTimer) {
        msp.sendMessage(.MSP_DATAFLASH_SUMMARY, data: nil, retry: 0, callback: { success in
            if success && Dataflash.theDataflash.ready {
                dispatch_async(dispatch_get_main_queue(), {
                    timer.invalidate()
                    self.updateSummary()
                    SVProgressHUD.dismiss()
                })
            }
        })
    }
    
    @IBAction func eraseAction(sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: "This will erase all data contained in the dataflash and will take about a minute. Are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { alertController in
            SVProgressHUD.showWithStatus("Erasing dataflash. Please wait.", maskType: .Black)
            Analytics.logEvent("dataflash_erase", parameters: nil)
            self.msp.sendMessage(.MSP_DATAFLASH_ERASE, data: nil, retry: 0, callback: { success in
                dispatch_async(dispatch_get_main_queue(), {
                    if success {
                        NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(DataflashController.eraseTimer(_:)), userInfo: nil, repeats: true)
                    } else {
                        Analytics.logEvent("dataflash_erase_failed", parameters: nil)
                        SVProgressHUD.showErrorWithStatus("Erase failed");
                        self.updateSummary()
                    }
                })
            })
        }))
        alertController.popoverPresentationController?.sourceView = (sender as! UIView)
        presentViewController(alertController, animated: true, completion: nil)

    }
    @IBAction func saveAction(sender: AnyObject) {
        let dataflash = Dataflash.theDataflash
        dataflash.blackboxDevice = deviceValues[devicePicker.selectedIndex]
        switch ratePicker.selectedIndex {
        case 0:
            dataflash.blackboxRateNum = 1
            dataflash.blackboxRateDenom = 1
        case 1:
            dataflash.blackboxRateNum = 1
            dataflash.blackboxRateDenom = 2
        case 2:
            dataflash.blackboxRateNum = 1
            dataflash.blackboxRateDenom = 3
        case 3:
            dataflash.blackboxRateNum = 1
            dataflash.blackboxRateDenom = 4
        case 4:
            dataflash.blackboxRateNum = 1
            dataflash.blackboxRateDenom = 5
        case 5:
            dataflash.blackboxRateNum = 1
            dataflash.blackboxRateDenom = 6
        case 6:
            dataflash.blackboxRateNum = 1
            dataflash.blackboxRateDenom = 7
        case 7:
            dataflash.blackboxRateNum = 1
            dataflash.blackboxRateDenom = 8
        case 8:
            dataflash.blackboxRateNum = 1
            dataflash.blackboxRateDenom = 16
        case 9:
            dataflash.blackboxRateNum = 1
            dataflash.blackboxRateDenom = 32
        default:
            break
        }
        msp.sendBlackboxConfig(dataflash) { success in
            if success {
                dispatch_async(dispatch_get_main_queue()) {
                    SVProgressHUD.showWithStatus("Rebooting...")
                }
                self.msp.sendMessage(.MSP_EEPROM_WRITE, data: nil, retry: 2) { success in
                    if success {
                        self.msp.sendMessage(.MSP_SET_REBOOT, data: nil, retry: 2) { success in
                            if success {
                                // Wait 4 sec
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(4000) * NSEC_PER_MSEC)), dispatch_get_main_queue(), {
                                    // Refetch information from FC
                                    self.updateSummary()
                                })
                            } else {
                                dispatch_async(dispatch_get_main_queue()) {
                                    SVProgressHUD.showErrorWithStatus("Reboot failed")
                                }
                            }
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            SVProgressHUD.showErrorWithStatus("Save failed")
                        }
                    }
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    SVProgressHUD.showErrorWithStatus("Save failed")
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return Dataflash.theDataflash.sdcardSupported ? "SD Card" : "Dataflash"
        } else {
            return super.tableView(tableView, titleForHeaderInSection: section)
        }
    }
}
