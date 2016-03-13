//
//  MSPViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 13/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

protocol UseMSPVehicle {
}

extension UseMSPVehicle {
    var mspVehicle: MSPVehicle {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.vehicle as! MSPVehicle
    }
}