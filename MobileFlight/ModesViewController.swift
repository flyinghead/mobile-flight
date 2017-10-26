//
//  ModesViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 13/12/15.
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

class ModesViewController: UITableViewController, UITextFieldDelegate {
    var dontReloadTable = false

    var modeRanges: [ModeRange]?
    var modeRangeSlots = 0
    
    var channelLabels = ["Delete Range"]
    
    var previousModes = 0
    var flightModeEventHandler: Disposable?
    var receiverEventHandler: Disposable?
    
    func tableViewTapped(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .began || recognizer.state == .changed {
            dontReloadTable = true
        } else {
            dontReloadTable = false
        }
        recognizer.cancelsTouchesInView = false
    }
    
    func initialFetch() {
        dontReloadTable = true

        appDelegate.stopTimer()
        msp.sendMessage(.msp_BOXNAMES, data: nil, retry: 2, callback: { success in
            if success {
                self.msp.sendMessage(.msp_BOXIDS, data: nil, retry: 2, callback: { success in
                    if success {
                        self.msp.sendMessage(.msp_MODE_RANGES, data: nil, retry: 2, callback: { success in
                            if success {
                                DispatchQueue.main.async(execute: {
                                    self.appDelegate.startTimer()
                                    let settings = Settings.theSettings
                                    self.modeRanges = [ModeRange](settings.modeRanges!)
                                    self.modeRangeSlots = settings.modeRangeSlots
                                    self.dontReloadTable = false
                                    self.tableView.reloadData()
                                })
                            } else {
                                self.refreshError()
                            }
                        })
                    } else {
                        self.refreshError()
                    }
                })
            } else {
                self.refreshError()
            }
        })
    }

    fileprivate func refreshError() {
        DispatchQueue.main.async(execute: {
            self.appDelegate.startTimer()
            
            SVProgressHUD.showError(withStatus: "Communication error")
            if !self.dontReloadTable {
                self.tableView.reloadData()
            }
        })
    }
    
    func receivedReceiverData() {
        let receiver = Receiver.theReceiver
        
        let channelCount = receiver.activeChannels - 3
        // If the receiver config has changed, remove extraneous channels
        while channelCount < channelLabels.count {
            channelLabels.removeLast()
        }
        // Similarly, add missing channels if needed
        for i in channelLabels.count ..< channelCount {
            channelLabels.append(String(format: "AUX%d", i))
        }
        if let visibleRowIndices = tableView.indexPathsForVisibleRows {
            for indexPath in visibleRowIndices {
                if let cell = tableView.cellForRow(at: indexPath) as? ModeRangeCell {
                    let channel = modeRanges![cell.modeRangeIdx].auxChannelId
                    cell.rangeSlider.referenceValue = Double(receiver.channels[channel + 4])
                }
            }
        }
    }
    func flightModeChanged() {
        let config = Configuration.theConfig
        if !dontReloadTable && config.mode != previousModes {
            previousModes = config.mode
            tableView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        initialFetch()
        
        receivedReceiverData()
        flightModeEventHandler = msp.flightModeEvent.addHandler(self, handler: ModesViewController.flightModeChanged)
        receiverEventHandler = msp.receiverEvent.addHandler(self, handler: ModesViewController.receivedReceiverData)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        flightModeEventHandler?.dispose()
        receiverEventHandler?.dispose()
    }
    
    func pickerDidBeginEditing() {
        dontReloadTable = true
    }
    
    func pickerDidEndEditing() {
        dontReloadTable = false
    }
    
    func addRangeAction(_ sender: Any?) {
        if let button = sender as! AddRangeButton? {
            if modeRanges?.count >= modeRangeSlots {
                SVProgressHUD.showError(withStatus: String(format:"Maximum %d mode ranges", modeRangeSlots))
            } else {
                modeRanges?.append(ModeRange(id: button.modeId, auxChannelId: 0, start: 1250, end: 1750))
                tableView.reloadData()
            }
        }
    }
    
    func findModeRangeIndex(modeIdx: Int, rangeIdx: Int) -> Int {
        let settings = Settings.theSettings

        var index = -1
        if let modeRanges = modeRanges {
            if let modeId = settings.boxIds?[modeIdx] {
                for (fullIndex, range) in modeRanges.enumerated() {
                    if range.id == modeId {
                        index += 1
                        if index == rangeIdx {
                            return fullIndex
                        }
                    }
                }
            }
        }
    
        return 0
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Settings.theSettings.boxIds?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        if let modeId = Settings.theSettings.boxIds?[section] {
            if modeRanges != nil {
                for range in modeRanges! {
                    if range.id == modeId {
                        count += 1
                    }
                }
            }
        }
        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ModeRangeCell", for: indexPath) as! ModeRangeCell

        cell.viewController = self
        
        // Remove first to avoid adding duplicate targets (?)
        cell.channelPicker.removeTarget(self, action: #selector(ModesViewController.pickerDidBeginEditing), for: .editingDidBegin)
        cell.channelPicker.removeTarget(self, action: #selector(ModesViewController.pickerDidEndEditing), for: .editingDidEnd)
        cell.channelPicker.addTarget(self, action: #selector(ModesViewController.pickerDidBeginEditing), for: .editingDidBegin)
        cell.channelPicker.addTarget(self, action: #selector(ModesViewController.pickerDidEndEditing), for: .editingDidEnd)
        
        cell.rangeSlider.interval = 25
        cell.rangeSlider.minimumValue = 900
        cell.rangeSlider.maximumValue = 2100

        let rangeIdx = findModeRangeIndex(modeIdx: indexPath.section, rangeIdx: indexPath.row)
        let range = modeRanges![rangeIdx]
        
        cell.modeRangeIdx = rangeIdx
        cell.channelPicker.setData(channelLabels)
        cell.channelPicker.selectedIndex = range.auxChannelId + 1
        cell.rangeSlider.lowerValue = Double(range.start)
        cell.rangeSlider.upperValue = Double(range.end)
        
        cell.rangeSlider.referenceValue = 0         // Hidden by default
        if cell.channelPicker.selectedIndex >= 0 {
            let rcChannel = cell.channelPicker.selectedIndex + 3
            let receiver = Receiver.theReceiver
            if rcChannel < receiver.channels.count {
                cell.rangeSlider.referenceValue = Double(receiver.channels[rcChannel])
            }
        }
        
        cell.rangeChanged(cell.rangeSlider)

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))

        let label = UILabel(frame: CGRect(x: 10, y: 5, width: tableView.frame.width, height: 25))
        label.text = Settings.theSettings.boxNames![section]
        label.textColor = Configuration.theConfig.mode & (1 << section) != 0 ? UIColor.red : UIColor.black
        label.font = UIFont.systemFont(ofSize: 16)
        
        view.addSubview(label)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 44))
        view.isUserInteractionEnabled = true
        
        let addButton = AddRangeButton(type: .contactAdd)
        addButton.addTarget(self, action: #selector(ModesViewController.addRangeAction(_:)), for: .touchDown)
        addButton.modeId = Settings.theSettings.boxIds![section]
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
        
        view.addConstraint(NSLayoutConstraint(item: addButton, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leadingMargin, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: addButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 80))
        view.addConstraint(NSLayoutConstraint(item: addButton, attribute: .top, relatedBy: .equal, toItem: view, attribute: .topMargin, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: addButton, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottomMargin, multiplier: 1, constant: 0))
        
        return view
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        dontReloadTable = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        dontReloadTable = false
    }
    
    @IBAction func saveAction(_ sender: Any) {
        Analytics.logEvent("modes_save", parameters: nil)
        appDelegate.stopTimer()
        sendModeRange(0)
    }
    
    func sendModeRange(_ index: Int) {
        var range = ModeRange(id: 0, auxChannelId: 0, start: 900, end: 900)
        if index < modeRanges!.count {
            range = modeRanges![index]
        }
        msp.sendSetModeRange(index, range: range, callback: { success in
            if success {
                if index >= self.modeRangeSlots - 1 {
                    self.msp.sendMessage(.msp_EEPROM_WRITE, data: nil, retry: 2, callback: { success in
                        DispatchQueue.main.async(execute: {
                            self.appDelegate.startTimer()
                            if success {
                                SVProgressHUD.showSuccess(withStatus: "Settings saved")
                            } else {
                                Analytics.logEvent("modes_save_failed", parameters: nil)
                                SVProgressHUD.showError(withStatus: "Save failed")
                            }
                        })
                    })
                } else {
                    self.sendModeRange(index+1)
                }
            } else {
                DispatchQueue.main.async(execute: {
                    self.appDelegate.startTimer()
                    Analytics.logEvent("modes_save_failed", parameters: nil)
                    SVProgressHUD.showError(withStatus: "Save failed")
                })
            }
        })
    }
}

class ModeRangeCell : UITableViewCell {
    
    @IBOutlet weak var channelField: UITextField!
    @IBOutlet weak var rangeSlider: RangeSlider!
    @IBOutlet weak var lowerLabel: UILabel!
    @IBOutlet weak var upperLabel: UILabel!
    
    var viewController: ModesViewController?
    var modeRangeIdx: Int = -1
    
    var channelPicker: MyDownPicker {
        if _channelPicker == nil {
            _channelPicker = MyDownPicker(textField: channelField)
            _channelPicker?.addTarget(self, action: #selector(ModeRangeCell.channelChanged(_:)), for: .valueChanged)
        }
        return _channelPicker!
    }
    
    fileprivate var _channelPicker: MyDownPicker?
    
    @IBAction func rangeChanged(_ sender: Any) {
        lowerLabel.text = String(format: "%.0f", rangeSlider.lowerValue)
        upperLabel.text = String(format: "%.0f", rangeSlider.upperValue)
        
        viewController!.modeRanges![modeRangeIdx].start = Int(rangeSlider.lowerValue)
        viewController!.modeRanges![modeRangeIdx].end = Int(rangeSlider.upperValue)
    }
    func channelChanged(_ sender: Any) {
        if channelPicker.selectedIndex >= 0 {
            if channelPicker.selectedIndex == 0 {
                viewController!.modeRanges!.remove(at: modeRangeIdx)
                viewController!.tableView.reloadData()
            } else {
                viewController!.modeRanges![modeRangeIdx].auxChannelId = channelPicker.selectedIndex - 1
            }
        }
    }
}

class AddRangeButton : UIButton {
    var modeId: Int = 0
    
}
