//
//  ModesViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 13/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import DownPicker
import SVProgressHUD

class ModesViewController: UITableViewController, FlightDataListener, UITextFieldDelegate {
    var fastTimer: NSTimer?
    var dontReloadTable = false

    var modeRanges: [ModeRange]?
    var modeRangeSlots = 0
    
    var channelLabels = ["Delete Range"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        initialFetch()
    }
    
    func initialFetch() {
        dontReloadTable = true
        // FIXME Error cases
        msp.sendMessage(.MSP_BOXNAMES, data: nil, retry: 2, callback: { success in
            self.msp.sendMessage(.MSP_BOXIDS, data: nil, retry: 2, callback: { success in
                self.msp.sendMessage(.MSP_MODE_RANGES, data: nil, retry: 2, callback: { success in
                    self.msp.sendMessage(.MSP_RC, data: nil, retry: 2, callback: { success in
                        dispatch_async(dispatch_get_main_queue(), {
                            let settings = Settings.theSettings
                            self.modeRanges = [ModeRange](settings.modeRanges!)
                            self.modeRangeSlots = settings.modeRangeSlots
                            self.dontReloadTable = false
                            self.tableView.reloadData()
                        })
                    })
                })
            })
        })
    }

    func receivedReceiverData() {
        let channelCount = Receiver.theReceiver.activeChannels - 3
        // If the receiver config has changed, remove extraneous channels
        while channelCount < channelLabels.count {
            channelLabels.removeLast()
        }
        // Similarly, add missing channels if needed
        for var i = channelLabels.count; i < channelCount; i++ {
            channelLabels.append(String(format: "AUX%d", i))
        }

        if !dontReloadTable {
            tableView.reloadData()
        }
    }
    func receivedData() {
        if !dontReloadTable {
            tableView.reloadData()
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        msp.addDataListener(self)
        
        if (fastTimer == nil) {
            fastTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "fastTimerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        msp.removeDataListener(self)
        
        fastTimer?.invalidate()
        fastTimer = nil
    }
    
    func fastTimerDidFire(sender: AnyObject?) {
        if modeRanges != nil {
            msp.sendMessage(.MSP_RC, data: nil)
        }
    }
    
    func pickerDidBeginEditing() {
        dontReloadTable = true
    }
    
    func pickerDidEndEditing() {
        dontReloadTable = false
    }
    
    func addRangeAction(sender: AnyObject?) {
        if let button = sender as! AddRangeButton? {
            if modeRanges?.count >= modeRangeSlots {
                SVProgressHUD.showErrorWithStatus(String(format:"Maximum %d mode ranges", modeRangeSlots))
            } else {
                modeRanges?.append(ModeRange(id: button.modeId, auxChannelId: 0, start: 1250, end: 1750))
                tableView.reloadData()
            }
        }
    }
    
    func findModeRangeIndex(modeIdx modeIdx: Int, rangeIdx: Int) -> Int {
        let settings = Settings.theSettings

        var index = -1
        if let modeRanges = modeRanges {
            if let modeId = settings.boxIds?[modeIdx] {
                for (fullIndex, range) in modeRanges.enumerate() {
                    if range.id == modeId {
                        if ++index == rangeIdx {
                            return fullIndex
                        }
                    }
                }
            }
        }
    
        return 0
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Settings.theSettings.boxIds?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        if let modeId = Settings.theSettings.boxIds?[section] {
            if modeRanges != nil {
                for range in modeRanges! {
                    if range.id == modeId {
                        count++
                    }
                }
            }
        }
        return count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ModeRangeCell", forIndexPath: indexPath) as! ModeRangeCell

        cell.viewController = self
        
        // Remove first to avoid adding duplicate targets (?)
        cell.channelPicker.removeTarget(self, action: "pickerDidBeginEditing", forControlEvents: .EditingDidBegin)
        cell.channelPicker.removeTarget(self, action: "pickerDidEndEditing", forControlEvents: .EditingDidEnd)
        cell.channelPicker.addTarget(self, action: "pickerDidBeginEditing", forControlEvents: .EditingDidBegin)
        cell.channelPicker.addTarget(self, action: "pickerDidEndEditing", forControlEvents: .EditingDidEnd)
        
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

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))

        let label = UILabel(frame: CGRect(x: 10, y: 5, width: tableView.frame.width, height: 25))
        label.text = Settings.theSettings.boxNames![section]
        label.textColor = Configuration.theConfig.mode & (1 << section) != 0 ? UIColor.redColor() : UIColor.blackColor()
        label.font = UIFont.systemFontOfSize(16)

        view.addSubview(label)
        
        return view
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 44
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 44))
        view.userInteractionEnabled = true
        
        let addButton = AddRangeButton(type: .ContactAdd)
        addButton.addTarget(self, action: "addRangeAction:", forControlEvents: .TouchDown)
        addButton.modeId = Settings.theSettings.boxIds![section]
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
        
        view.addConstraint(NSLayoutConstraint(item: addButton, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .LeadingMargin, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: addButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0, constant: 80))
        view.addConstraint(NSLayoutConstraint(item: addButton, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .TopMargin, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: addButton, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .BottomMargin, multiplier: 1, constant: 0))
        
        return view

        /*
        let view = NSBundle.mainBundle().loadNibNamed("ModeTableViewFooter", owner: self, options: nil)[0] as! UIView
        let addButton = view.subviews[0] as! AddRangeButton
        addButton.addTarget(self, action: "addRangeAction:", forControlEvents: .TouchDown)
        addButton.modeId = Settings.theSettings.boxIds![section]
        
        return view
        */
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        dontReloadTable = true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        dontReloadTable = false
    }
    
    @IBAction func saveAction(sender: AnyObject) {
        sendModeRange(0)
    }
    
    func sendModeRange(index: Int) {
        var range = ModeRange(id: 0, auxChannelId: 0, start: 900, end: 900)
        if index < modeRanges!.count {
            range = modeRanges![index]
        }
        msp.sendSetModeRange(index, range: range, callback: { success in
            if success {
                if index >= self.modeRangeSlots - 1 {
                    self.msp.sendMessage(.MSP_EEPROM_WRITE, data: nil, retry: 2, callback: { success in
                        dispatch_async(dispatch_get_main_queue(), {
                            if success {
                                SVProgressHUD.showSuccessWithStatus("Settings saved")
                            } else {
                                SVProgressHUD.showErrorWithStatus("Save failed")
                            }
                        })
                    })
                } else {
                    self.sendModeRange(index+1)
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    SVProgressHUD.showErrorWithStatus("Save failed")
                })
            }
        })
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        initialFetch()
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
            _channelPicker?.addTarget(self, action: "channelChanged:", forControlEvents: .ValueChanged)
            _channelPicker?.setPlaceholder("")
        }
        return _channelPicker!
    }
    
    private var _channelPicker: MyDownPicker?
    
    @IBAction func rangeChanged(sender: AnyObject) {
        lowerLabel.text = String(format: "%.0f", locale: NSLocale.currentLocale(), rangeSlider.lowerValue)
        upperLabel.text = String(format: "%.0f", locale: NSLocale.currentLocale(), rangeSlider.upperValue)
        
        viewController!.modeRanges![modeRangeIdx].start = Int(rangeSlider.lowerValue)
        viewController!.modeRanges![modeRangeIdx].end = Int(rangeSlider.upperValue)
    }
    func channelChanged(sender: AnyObject) {
        if channelPicker.selectedIndex >= 0 {
            if channelPicker.selectedIndex == 0 {
                viewController!.modeRanges!.removeAtIndex(modeRangeIdx)
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
