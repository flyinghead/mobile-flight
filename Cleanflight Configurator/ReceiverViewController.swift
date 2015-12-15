//
//  ReceiverViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 04/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class ReceiverViewController: UIViewController, FlightDataListener {

    var timer: NSTimer?

    @IBOutlet weak var rollChannel: ReceiverChannel!
    @IBOutlet weak var pitchChannel: ReceiverChannel!
    @IBOutlet weak var yawChannel: ReceiverChannel!
    @IBOutlet weak var throttleChannel: ReceiverChannel!
    @IBOutlet weak var aux1Channel: ReceiverChannel!
    @IBOutlet weak var aux2Channel: ReceiverChannel!
    @IBOutlet weak var aux3Channel: ReceiverChannel!
    @IBOutlet weak var aux4Channel: ReceiverChannel!
    @IBOutlet weak var aux5Channel: ReceiverChannel!
    @IBOutlet weak var aux6Channel: ReceiverChannel!
    @IBOutlet weak var aux7Channel: ReceiverChannel!
    @IBOutlet weak var aux8Channel: ReceiverChannel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        msp.addDataListener(self)
    }

    func receivedReceiverData() {
        let controls = [rollChannel, pitchChannel, yawChannel, throttleChannel, aux1Channel, aux2Channel, aux3Channel, aux4Channel, aux5Channel, aux6Channel, aux7Channel, aux8Channel]
        let receiver = Receiver.theReceiver
        
        for (i,control) in controls.enumerate() {
            if (i < receiver.activeChannels) {
                control.setValue(receiver.channels[i])
            } else {
                control.setValue(1000)
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (timer == nil) {
            // Cleanflight/chrome uses configurable interval (default 50ms)
            timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        timer?.invalidate()
        timer = nil
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    func timerDidFire(sender: AnyObject) {
//        msp.sendMessage(.MSP_MISC, data: nil)
        msp.sendMessage(.MSP_RC, data: nil)
        msp.sendMessage(.MSP_RX_MAP, data: nil)
    }
}

class Receiver2ViewController: UITableViewController, FlightDataListener {
    
    var colors = [UIColor(hex6: 0xf1453d), UIColor(hex6: 0x673fb4), UIColor(hex6: 0x2b98f0), UIColor(hex6: 0x1fbcd2),
        UIColor(hex6: 0x159588), UIColor(hex6: 0x50ae55), UIColor(hex6: 0xcdda49), UIColor(hex6: 0xfdc02f),
        UIColor(hex6: 0xfc5830), UIColor(hex6: 0x785549), UIColor(hex6: 0x9e9e9e), UIColor(hex6: 0x617d8a),
        UIColor(hex6: 0xcf267d), UIColor(hex6: 0x7a1464), UIColor(hex6: 0x3a7a14), UIColor(hex6: 0x14407a)]
    var timer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        msp.addDataListener(self)
    }
    
    func receivedReceiverData() {
        tableView.reloadData()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (timer == nil) {
            // Cleanflight/chrome uses configurable interval (default 50ms)
            timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer?.invalidate()
        timer = nil
    }
    
    func timerDidFire(sender: AnyObject) {
        msp.sendMessage(.MSP_RC, data: nil)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return Receiver.theReceiver.activeChannels
        } else {
            return 1
        }
    }
    
    func channelLabel(i: Int) -> String {
        switch i {
        case 0:
            return "Roll"
        case 1:
            return "Pitch"
        case 2:
            return "Yaw"
        case 3:
            return "Throttle"
        default:
            return String(format: "AUX %d", i - 3)
        }
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            return tableView.dequeueReusableCellWithIdentifier("ConfigCell", forIndexPath: indexPath)
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("ChannelCell", forIndexPath: indexPath) as! ChannelCell
        let channelNum = indexPath.row
        cell.channelView.label = channelLabel(channelNum)
        cell.channelView.color = channelNum >= colors.count ? colors[colors.count - 1] : colors[channelNum]
        cell.channelView.setValue(Receiver.theReceiver.channels[channelNum])
        return cell
    }
}

class ChannelCell : UITableViewCell {
    @IBOutlet weak var channelView: ReceiverChannel!
    
}

extension UIColor {
    public convenience init(hex6: UInt32, alpha: CGFloat = 1) {
        let divisor = CGFloat(255)
        let red     = CGFloat((hex6 & 0xFF0000) >> 16) / divisor
        let green   = CGFloat((hex6 & 0x00FF00) >>  8) / divisor
        let blue    = CGFloat( hex6 & 0x0000FF       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}