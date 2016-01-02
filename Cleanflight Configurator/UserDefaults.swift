//
//  UserDefaults.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 30/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

enum UserDefault : String {
    case RecordFlightlog = "record_flightlog"
    case ConnectionLostAlarm = "connection_lost_alarm"
    case GPSFixLostAlarm = "gps_fix_lost_alarm"
    case BatteryLowAlarm = "battery_low_alarm"
}

func registerInitialUserDefaults() {
    let baseUrl = NSBundle.mainBundle().bundleURL
    let settingsBundleUrl = baseUrl.URLByAppendingPathComponent("Settings.bundle")
    let rootPlistUrl = settingsBundleUrl.URLByAppendingPathComponent("Root.plist")
    let settingsDict = NSDictionary(contentsOfFile: rootPlistUrl.path!)
    let prefSpecifierArray = settingsDict!.objectForKey("PreferenceSpecifiers") as! NSArray
    
    var defaults:[String:AnyObject] = [:]
    
    for prefItem in prefSpecifierArray {
        
        if let key = prefItem.objectForKey("Key") as? String {
            defaults[key] = prefItem.objectForKey("DefaultValue")
        }
    }
    
    NSUserDefaults.standardUserDefaults().registerDefaults(defaults)
}

func userDefaultEnabled(userDefault: UserDefault) -> Bool {
    return NSUserDefaults.standardUserDefaults().boolForKey(userDefault.rawValue)
}
