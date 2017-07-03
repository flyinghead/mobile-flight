//
//  OSDSettingsViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 15/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import SVProgressHUD
import Firebase

class ElementCell : UITableViewCell {
    @IBOutlet weak var elementLabel: UILabel!
    @IBOutlet weak var elementSwitch: UISwitch!
    
    var element: OSDElementPosition!
    
    @IBAction func switchChanged(sender: AnyObject) {
        element.visible = elementSwitch.on
    }
}

class RssiCell : UITableViewCell {
    @IBOutlet weak var rssiField: NumberField!
}

class CapacityCell : UITableViewCell {
    @IBOutlet weak var capacityField: NumberField!
    
}

class MinutesCell : UITableViewCell {
    @IBOutlet weak var minutesField: NumberField!
    
}

class AltitudeCell : UITableViewCell {
    @IBOutlet weak var altitudeField: NumberField!
    @IBOutlet weak var altitudeLabel: UILabel!
    
}

class VideoFormatCell : UITableViewCell {
    @IBOutlet weak var videoFormatField: UITextField!
    
    private var videoFormatPicker: MyDownPicker!

    override func awakeFromNib() {
        super.awakeFromNib()
        videoFormatPicker = MyDownPicker(textField: videoFormatField!, withData: VideoMode.descriptions)
    }
}

class UnitsCell : UITableViewCell {
    @IBOutlet weak var unitsField: UITextField!
    private var unitsPicker: MyDownPicker!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        unitsPicker = MyDownPicker(textField: unitsField!, withData: UnitMode.descriptions)
    }
}

class FontCell : UITableViewCell {
    @IBOutlet weak var fontField: UITextField!
    private var fontPicker: MyDownPicker!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        fontPicker = MyDownPicker(textField: fontField!, withData: FONTS)
    }
}

class OSDSettingsViewController: UITableViewController {

    weak var osdViewController: OSDViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        let osd = OSD.theOSD
        
        if let rssiCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as? RssiCell {
            osd.rssiAlarm = Int(round(rssiCell.rssiField.value))
        }
        if let capacityCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 1)) as? CapacityCell {
            osd.capacityAlarm = Int(round(capacityCell.capacityField.value))
        }
        if let minutesCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 1)) as? MinutesCell {
            osd.minutesAlarm = Int(round(minutesCell.minutesField.value))
        }
        if let altitudeCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 1)) as? AltitudeCell {
            osd.altitudeAlarm = Int(round(altitudeCell.altitudeField.value))
        }

        
        if let videoFormatCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2)) as? VideoFormatCell {
            osd.videoMode = VideoMode(rawValue: videoFormatCell.videoFormatPicker.selectedIndex)!
        }
        if let unitsCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 2)) as? UnitsCell {
            osd.unitMode = UnitMode(rawValue: unitsCell.unitsPicker.selectedIndex)!
        }
        if let fontCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 2)) as? FontCell {
            osd.loadFont(FONTS[fontCell.fontPicker.selectedIndex])
        }
        
        osdViewController.refreshUI()
    }

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:     // elements
            return OSD.theOSD.elements.count
        case 1:     // Alarms
            return 4
        case 2:     // Others
            return 4
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:     // elements
            return "Elements"
        case 1:     // Alarms
            return "Alarms"
        case 2:     // Others
            return "Other"
        default:
            return nil
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let osd = OSD.theOSD
        
        switch indexPath.section {
        case 0:     // elements
            let cell = tableView.dequeueReusableCellWithIdentifier("elementCell", forIndexPath: indexPath) as! ElementCell
            let position = osd.elements[indexPath.row]
            cell.element = position
            cell.elementLabel.text = position.element.description
            cell.elementSwitch.on = position.visible
            return cell
            
        case 1:     // Alarms
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier("rssiCell", forIndexPath: indexPath) as! RssiCell
                cell.rssiField.value = Double(osd.rssiAlarm)
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("capacityCell", forIndexPath: indexPath) as! CapacityCell
                cell.capacityField.value = Double(osd.capacityAlarm)
                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("minutesCell", forIndexPath: indexPath) as! MinutesCell
                cell.minutesField.value = Double(osd.minutesAlarm)
                return cell
            default:
                let cell = tableView.dequeueReusableCellWithIdentifier("altitudeCell", forIndexPath: indexPath) as! AltitudeCell
                cell.altitudeField.value = Double(osd.altitudeAlarm)
                cell.altitudeLabel.text = "Altitude (" + (osd.unitMode == .Imperial ? "ft" : "m") + ")"
                return cell
            }
        default:     // Others
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier("videoFormatCell", forIndexPath: indexPath) as! VideoFormatCell
                cell.videoFormatPicker.selectedIndex = osd.videoMode.rawValue
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("unitsCell", forIndexPath: indexPath) as! UnitsCell
                cell.unitsPicker.selectedIndex = osd.unitMode.rawValue
                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("fontCell", forIndexPath: indexPath) as! FontCell
                cell.fontPicker.selectedIndex = FONTS.indexOf(osd.fontName) ?? -1
                return cell
            default:
                return tableView.dequeueReusableCellWithIdentifier("uploadFontCell", forIndexPath: indexPath)
            }
        }
    }
    
    @IBAction func uploadFontAction(sender: AnyObject) {
        if let fontCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 2)) as? FontCell {
            Analytics.logEvent("osd_font_upload", parameters: [ "font" : fontCell.fontPicker.selectedIndex ])

            let osd = OSD.theOSD
            appDelegate.stopTimer()
            let status = "Uploading font..."
            SVProgressHUD.showProgress(0, status: status)
            osd.loadFont(FONTS[fontCell.fontPicker.selectedIndex])
            osd.fontDefinition.writeToOsd(msp, progressCallback: { progress in
                dispatch_async(dispatch_get_main_queue()) {
                    SVProgressHUD.showProgress(progress, status: status)
                }
            }) { success in
                dispatch_async(dispatch_get_main_queue()) {
                    if success {
                        SVProgressHUD.showWithStatus("Rebooting...")
                        self.msp.sendMessage(.MSP_SET_REBOOT, data: nil, retry: 2) { success in
                            if success {
                                // Wait 4 sec
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(4000) * NSEC_PER_MSEC)), dispatch_get_main_queue(), {
                                    SVProgressHUD.dismiss()
                                    self.appDelegate.startTimer()
                                })
                            } else {
                                dispatch_async(dispatch_get_main_queue()) {
                                    Analytics.logEvent("osd_font_upload_failed", parameters: nil)
                                    SVProgressHUD.showErrorWithStatus("Reboot failed")
                                    self.appDelegate.startTimer()
                                }
                            }
                        }
                    } else {
                        Analytics.logEvent("osd_font_upload_failed", parameters: nil)
                        SVProgressHUD.showErrorWithStatus("Upload failed")
                        self.appDelegate.startTimer()
                    }
                }
            }
        }
    }
}
