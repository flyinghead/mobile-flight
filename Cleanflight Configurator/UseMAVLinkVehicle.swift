//
//  MAVLinkViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 12/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

protocol UseMAVLinkVehicle {
}

extension UseMAVLinkVehicle {
    var mavlinkVehicle: MAVLinkVehicle {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.vehicle as! MAVLinkVehicle
    }
}