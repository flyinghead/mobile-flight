//
//  ReceiverViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 04/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class ReceiverViewController: UITableViewController {
    
    var colors = [UIColor(hex6: 0xf1453d), UIColor(hex6: 0x673fb4), UIColor(hex6: 0x2b98f0), UIColor(hex6: 0x1fbcd2),
        UIColor(hex6: 0x159588), UIColor(hex6: 0x50ae55), UIColor(hex6: 0xcdda49), UIColor(hex6: 0xfdc02f),
        UIColor(hex6: 0xfc5830), UIColor(hex6: 0x785549), UIColor(hex6: 0x9e9e9e), UIColor(hex6: 0x617d8a),
        UIColor(hex6: 0xcf267d), UIColor(hex6: 0x7a1464), UIColor(hex6: 0x3a7a14), UIColor(hex6: 0x14407a)]

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        vehicle.rcChannels.addObserver(self, listener: { newValue in
            self.tableView.reloadData()
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        vehicle.rcChannels.removeObserver(self)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return vehicle.rcChannels.value?.count ?? 0
        } else {
            return 1
        }
    }
    
    class func channelLabel(i: Int) -> String {
        switch i {
        case 0:
            return "Roll"
        case 1:
            return "Pitch"
        case 2:
            return "Throttle"
        case 3:
            return "Yaw"
        default:
            return String(format: "AUX %d", i - 3)
        }
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            return tableView.dequeueReusableCellWithIdentifier("ConfigCell", forIndexPath: indexPath)
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("ChannelCell", forIndexPath: indexPath) as! ChannelCell
        var channelNum = indexPath.row
        if channelNum < 4 {
            channelNum = vehicle.rcChannelsNativeOrder[channelNum]
        }
        cell.channelView.label = ReceiverViewController.channelLabel(channelNum)
        cell.channelView.color = indexPath.row >= colors.count ? colors[colors.count - 1] : colors[indexPath.row]
        cell.channelView.value = vehicle.rcChannels.value![channelNum]

        return cell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 1
        } else {
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
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