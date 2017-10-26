//
//  UserDefaults.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 30/12/15.
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

import Foundation

enum UnitSystem {
    case `default`
    case metric
    case imperial
    case aviation
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
    case FlightModeAlert = "flight_mode_alert"
    case OSDFont = "osd_font"
    case INavAlert = "inav_alert"
    case UsageReporting = "usage_reporting"
    
    var stringValue: String? {
        get {
            return UserDefaults.standard.string(forKey: self.rawValue)
        }
    }
    
    func setValue(_ string: String) {
        setUserDefault(self, string: string)
    }
}

func registerInitialUserDefaults(_ plistFile: String)  -> [String:Any] {
    let baseUrl = Bundle.main.bundleURL
    let settingsBundleUrl = baseUrl.appendingPathComponent("Settings.bundle")
    let plistUrl = settingsBundleUrl.appendingPathComponent(plistFile)
    let settingsDict = NSDictionary(contentsOfFile: plistUrl.path)
    let prefSpecifierArray = settingsDict!.object(forKey: "PreferenceSpecifiers") as! NSArray
    
    var defaults = [String : Any]()
    
    for prefItem in prefSpecifierArray {
        if (prefItem as AnyObject).object(forKey: "Type") as? String == "PSChildPaneSpecifier" {
            for (k,v) in registerInitialUserDefaults(((prefItem as AnyObject).object(forKey: "File") as! String) + ".plist") {
                defaults[k] = v
            }
        }
        else if let key = (prefItem as AnyObject).object(forKey: "Key") as? String {
            defaults[key] = (prefItem as AnyObject).object(forKey: "DefaultValue")
        }
    }
    
    return defaults
}

func registerInitialUserDefaults() {
    let defaults = registerInitialUserDefaults("Root.plist")
    
    UserDefaults.standard.register(defaults: defaults)
}

func userDefaultEnabled(_ userDefault: UserDefault) -> Bool {
    return UserDefaults.standard.bool(forKey: userDefault.rawValue)
}

func userDefaultAsString(_ userDefault: UserDefault) -> String {
    return UserDefaults.standard.string(forKey: userDefault.rawValue)!
}

func userDefaultAsInt(_ userDefault: UserDefault) -> Int {
    return UserDefaults.standard.integer(forKey: userDefault.rawValue)
}

func setUserDefault(_ userDefault: UserDefault, string: String?) {
    return UserDefaults.standard.setValue(string, forKey: userDefault.rawValue)
}

func selectedUnitSystem() -> UnitSystem {
    switch userDefaultAsString(.UnitSystem) {
    case "imperial":
        return .imperial
    case "metric":
        return .metric
    case "aviation":
        return .aviation
    default:
        return ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem) as? Bool ?? true) ? .metric : .imperial
    }
    
}
