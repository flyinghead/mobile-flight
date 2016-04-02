//
//  UserDefaults.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 30/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

enum UnitSystem {
    case Default
    case Metric
    case Imperial
    case Aviation
}

enum UserDefault : String {
    case RecordFlightlog = "record_flightlog"
    case ConnectionLostAlarm = "connection_lost_alarm"
    case GPSFixLostAlarm = "gps_fix_lost_alarm"
    case BatteryLowAlarm = "battery_low_alarm"
    case UnitSystem = "unit_system"
    case RSSIAlarm = "rssialarm_enabled"
    case RSSIAlarmLow = "rssialarm_low"
    case RSSIAlarmCritical = "rssialarm_critical"
    case DisableIdleTimer = "disable_idle_timer"
}

func registerInitialUserDefaults(plistFile: String)  -> [String:AnyObject] {
    let baseUrl = NSBundle.mainBundle().bundleURL
    let settingsBundleUrl = baseUrl.URLByAppendingPathComponent("Settings.bundle")
    let plistUrl = settingsBundleUrl.URLByAppendingPathComponent(plistFile)
    let settingsDict = NSDictionary(contentsOfFile: plistUrl.path!)
    let prefSpecifierArray = settingsDict!.objectForKey("PreferenceSpecifiers") as! NSArray
    
    var defaults:[String:AnyObject] = [:]
    
    for prefItem in prefSpecifierArray {
        if prefItem.objectForKey("Type") as? String == "PSChildPaneSpecifier" {
            for (k,v) in registerInitialUserDefaults((prefItem.objectForKey("File") as! String) + ".plist") {
                defaults[k] = v
            }
        }
        else if let key = prefItem.objectForKey("Key") as? String {
            defaults[key] = prefItem.objectForKey("DefaultValue")
        }
    }
    
    return defaults
}

func registerInitialUserDefaults() {
    let defaults = registerInitialUserDefaults("Root.plist")
    
    NSUserDefaults.standardUserDefaults().registerDefaults(defaults)
}

func userDefaultEnabled(userDefault: UserDefault) -> Bool {
    return NSUserDefaults.standardUserDefaults().boolForKey(userDefault.rawValue)
}

func userDefaultAsString(userDefault: UserDefault) -> String {
    return NSUserDefaults.standardUserDefaults().stringForKey(userDefault.rawValue)!
}

func userDefaultAsInt(userDefault: UserDefault) -> Int {
    return NSUserDefaults.standardUserDefaults().integerForKey(userDefault.rawValue)
}

func selectedUnitSystem() -> UnitSystem {
    switch userDefaultAsString(.UnitSystem) {
    case "imperial":
        return .Imperial
    case "metric":
        return .Metric
    case "aviation":
        return .Aviation
    default:
        return (NSLocale.currentLocale().objectForKey(NSLocaleUsesMetricSystem) as? Bool ?? true) ? .Metric : .Imperial
    }
    
}
