//
//  OSDSettingsViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 15/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
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
import SVProgressHUD
import Firebase

class ElementCell : UITableViewCell {
    @IBOutlet weak var elementLabel: UILabel!
    @IBOutlet weak var elementSwitch: UISwitch!
    
    var element: OSDElementPosition!
    
    @IBAction func switchChanged(_ sender: Any) {
        element.visible = elementSwitch.isOn
    }
}

class FlightStatCell : ConditionalTableViewCell {
    @IBOutlet weak var statLabel: UILabel!
    @IBOutlet weak var statSwitch: UISwitch!
    
    var statIndex = 0
    
    @IBAction func switchChanged(_ sender: Any) {
        if let stats = OSD.theOSD.displayedStats, statIndex < stats.count {
            OSD.theOSD.displayedStats![statIndex] = statSwitch.isOn
        }
    }
}

class TimerCell : UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var TimerLabel: UILabel!
    @IBOutlet weak var timerTypeField: UITextField!
    @IBOutlet weak var precisionField: UITextField!
    @IBOutlet weak var alarmField: NumberField!
    
    var timerTypePicker: MyDownPicker!
    var precisionPicker: MyDownPicker!
    var timerIndex = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        timerTypePicker = MyDownPicker(textField: timerTypeField, withData: OSDTimerSources)
        timerTypePicker.addTarget(self, action: #selector(TimerCell.timerTypeChanged(_:)), for: .valueChanged)
        precisionPicker = MyDownPicker(textField: precisionField, withData: [ "1 second", "1/100 second" ])
        precisionPicker.addTarget(self, action: #selector(TimerCell.precisionChanged(_:)), for: .valueChanged)
        alarmField.delegate = self
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let osd = OSD.theOSD
        osd.timers![timerIndex].alarm = Int(alarmField.value)
    }
    
    @objc func timerTypeChanged(_ sender: NSObject) {
        let osd = OSD.theOSD
        osd.timers![timerIndex].source = timerTypePicker.selectedIndex
    }
    
    @objc func precisionChanged(_ sender: NSObject) {
        let osd = OSD.theOSD
        osd.timers![timerIndex].precision = precisionPicker.selectedIndex
    }
}

class RssiCell : UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var rssiField: NumberField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        rssiField.delegate = self
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        OSD.theOSD.rssiAlarm = Int(round(rssiField.value))
    }
}

class CapacityCell : UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var capacityField: NumberField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        capacityField.delegate = self
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        OSD.theOSD.capacityAlarm = Int(round(capacityField.value))
    }
}

class MinutesCell : UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var minutesField: NumberField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        minutesField.delegate = self
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        OSD.theOSD.minutesAlarm = Int(round(minutesField.value))
    }
}

class AltitudeCell : UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var altitudeField: NumberField!
    @IBOutlet weak var altitudeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        altitudeField.delegate = self
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        OSD.theOSD.altitudeAlarm = Int(round(altitudeField.value))
    }
}

class VideoFormatCell : UITableViewCell {
    @IBOutlet weak var videoFormatField: UITextField!
    
    fileprivate var videoFormatPicker: MyDownPicker!

    override func awakeFromNib() {
        super.awakeFromNib()
        videoFormatPicker = MyDownPicker(textField: videoFormatField!, withData: VideoMode.descriptions)
        videoFormatPicker.addTarget(self, action: #selector(VideoFormatCell.videoFormatChanged(_:)), for: .valueChanged)
    }
    
    @objc func videoFormatChanged(_ sender: NSObject) {
        OSD.theOSD.videoMode = VideoMode(rawValue: videoFormatPicker.selectedIndex)!
    }
}

class UnitsCell : UITableViewCell {
    @IBOutlet weak var unitsField: UITextField!
    fileprivate var unitsPicker: MyDownPicker!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        unitsPicker = MyDownPicker(textField: unitsField!, withData: UnitMode.descriptions)
        unitsPicker.addTarget(self, action: #selector(UnitsCell.unitsChanged(_:)), for: .valueChanged)
    }
    
    @objc func unitsChanged(_ sender: NSObject) {
        OSD.theOSD.unitMode = UnitMode(rawValue: unitsPicker.selectedIndex)!
    }
}

class FontCell : UITableViewCell {
    @IBOutlet weak var fontField: UITextField!
    fileprivate var fontPicker: MyDownPicker!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        fontPicker = MyDownPicker(textField: fontField!, withData: FONTS)
        fontPicker.addTarget(self, action: #selector(FontCell.fontChanged(_:)), for: .valueChanged)
    }
    
    @objc func fontChanged(_ sender: NSObject) {
        OSD.theOSD.loadFont(FONTS[fontPicker.selectedIndex])
    }
}

class OSDSettingsViewController: UITableViewController {

    weak var osdViewController: OSDViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        osdViewController.refreshUI()
    }

    var hasFlightStatsAndTimers: Bool {
        return (OSD.theOSD.displayedStats?.count ?? 0) > 0
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return hasFlightStatsAndTimers ? 5 : 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var fixedSection = section
        if !hasFlightStatsAndTimers && fixedSection > 0 {
            fixedSection += 2
        }
        let osd = OSD.theOSD
        switch fixedSection {
        case 0:     // elements
            return osd.elements.count
        case 1:     // Flight Stats
            return osd.displayedStats!.count
        case 2:     // Timers
            return osd.timers?.count ?? 0
        case 3:     // Alarms
            return hasFlightStatsAndTimers ? 3 : 4
        case 4:     // Others
            return 4
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var fixedSection = section
        if !hasFlightStatsAndTimers && fixedSection > 0 {
            fixedSection += 2
        }
        switch fixedSection {
        case 0:     // elements
            return "Elements"
        case 1:     // Flight Stats
            return "Flight Statistics"
        case 2:     // Timers
            return "Timers"
        case 3:     // Alarms
            return "Alarms"
        case 4:     // Others
            return "Other"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let osd = OSD.theOSD
        
        var section = indexPath.section
        if !hasFlightStatsAndTimers && section > 0 {
            section += 2
        }
        switch section {
        case 0:     // elements
            let cell = tableView.dequeueReusableCell(withIdentifier: "elementCell", for: indexPath) as! ElementCell
            let position = osd.elements[indexPath.row]
            cell.element = position
            cell.elementLabel.text = position.element.description
            cell.elementSwitch.isOn = position.visible
            return cell
        
        case 1:     // Flight Stats
            let cell = tableView.dequeueReusableCell(withIdentifier: "flightStatCell", for: indexPath) as! FlightStatCell
            cell.statIndex = indexPath.row
            if let stat = FlightStats(rawValue: indexPath.row) {
                cell.statLabel.text = stat.label
            } else {
                cell.statLabel.text = String(format: "Stat %d", indexPath.row)
            }
            cell.statSwitch.isOn = osd.displayedStats![indexPath.row]
            return cell
            
        case 2:     // Timers
            let cell = tableView.dequeueReusableCell(withIdentifier: "timerCell", for: indexPath) as! TimerCell
            cell.timerIndex = indexPath.row
            cell.TimerLabel.text = String(format: "Timer %d", indexPath.row + 1)
            let timer = osd.timers![indexPath.row]
            cell.timerTypePicker.selectedIndex = timer.source
            cell.precisionPicker.selectedIndex = timer.precision
            cell.alarmField.value = Double(timer.alarm)
            return cell

        case 3:     // Alarms
            var row = indexPath.row
            if hasFlightStatsAndTimers && row == 2 {
                row = 3
            }
            switch row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "rssiCell", for: indexPath) as! RssiCell
                cell.rssiField.value = Double(osd.rssiAlarm)
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "capacityCell", for: indexPath) as! CapacityCell
                cell.capacityField.value = Double(osd.capacityAlarm)
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "minutesCell", for: indexPath) as! MinutesCell
                cell.minutesField.value = Double(osd.minutesAlarm)
                return cell
                
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "altitudeCell", for: indexPath) as! AltitudeCell
                cell.altitudeField.value = Double(osd.altitudeAlarm)
                cell.altitudeLabel.text = "Altitude (" + (osd.unitMode == .imperial ? "ft" : "m") + ")"
                return cell
            }
        default:     // Others
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "videoFormatCell", for: indexPath) as! VideoFormatCell
                cell.videoFormatPicker.selectedIndex = osd.videoMode.rawValue
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "unitsCell", for: indexPath) as! UnitsCell
                cell.unitsPicker.selectedIndex = osd.unitMode.rawValue
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "fontCell", for: indexPath) as! FontCell
                cell.fontPicker.selectedIndex = FONTS.index(of: osd.fontName) ?? -1
                return cell
            default:
                return tableView.dequeueReusableCell(withIdentifier: "uploadFontCell", for: indexPath)
            }
        }
    }

    // MARK:
    
    @IBAction func uploadFontAction(_ sender: Any) {
        if let fontCell = tableView.cellForRow(at: IndexPath(row: 2, section: 2)) as? FontCell {
            Analytics.logEvent("osd_font_upload", parameters: [ "font" : fontCell.fontPicker.selectedIndex ])

            let osd = OSD.theOSD
            appDelegate.stopTimer()
            let status = "Uploading font..."
            SVProgressHUD.showProgress(0, status: status)
            osd.loadFont(FONTS[fontCell.fontPicker.selectedIndex])
            osd.fontDefinition.writeToOsd(msp, progressCallback: { progress in
                DispatchQueue.main.async {
                    SVProgressHUD.showProgress(progress, status: status)
                }
            }) { success in
                DispatchQueue.main.async {
                    if success {
                        SVProgressHUD.show(withStatus: "Rebooting...")
                        self.msp.sendMessage(.msp_SET_REBOOT, data: nil, retry: 2) { success in
                            if success {
                                // Wait 4 sec
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(UInt64(4000) * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC), execute: {
                                    SVProgressHUD.dismiss()
                                    self.appDelegate.startTimer()
                                })
                            } else {
                                DispatchQueue.main.async {
                                    Analytics.logEvent("osd_font_upload_failed", parameters: nil)
                                    SVProgressHUD.showError(withStatus: "Reboot failed")
                                    self.appDelegate.startTimer()
                                }
                            }
                        }
                    } else {
                        Analytics.logEvent("osd_font_upload_failed", parameters: nil)
                        SVProgressHUD.showError(withStatus: "Upload failed")
                        self.appDelegate.startTimer()
                    }
                }
            }
        }
    }
}
