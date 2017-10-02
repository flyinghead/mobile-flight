//
//  MetarManager.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 03/04/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
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

class MetarManager : NSObject, NSURLSessionDelegate, NSURLSessionDataDelegate {
    static let instance = MetarManager()
    
    private let updateFrequency = 60.0 * 15   // Every 15 min
    
    private let latitudeRange = 0.9         // Approx. 100 km
    private let longitudeRange = 1.4        // Approx. 100 km at 48° lat

    private var urlSession : NSURLSession!
    private var dataTask: NSURLSessionDataTask?
    
    private var position: GPSLocation!
    private var rangeMultiplier = 1.0
    private var lastRetrieveDate: NSDate?
    private var observers = [(object: AnyObject, selector: Selector)]()

    private(set) var reports: [MetarReport]!
    
    private var updateTimer: NSTimer?
    
    private override init() {
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
        appDidBecomeActive()
        urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)
    }
    
    weak var locationProvider: UserLocationProvider! {
        didSet {
            // Only when setting the initial provider. Otherwise, let the update timer do its job
            if updateTimer == nil {
                updateCurrentLocationAndRetrieveReports()
            }
        }
    }
    
    private func updateCurrentLocationAndRetrieveReports() {
        locationProvider?.currentLocation() { [weak self] in
            self?.position = $0
            self?.retrieveMetarReports()
        }
    }
    
    private func retrieveMetarReports() {
        if dataTask != nil {
            return
        }
        
        let minLat = position.latitude - rangeMultiplier * latitudeRange
        let maxLat = position.latitude + rangeMultiplier * latitudeRange
        let minLon = position.longitude - rangeMultiplier * longitudeRange
        let maxLon = position.longitude + rangeMultiplier * longitudeRange
        
        let urlString = String(format: "https://aviationweather.gov/gis/scripts/MetarJSON.php?bbox=%f,%f,%f,%f&density=all", minLon, minLat, maxLon, maxLat)
        NSLog("Retrieving METARs: %@", urlString)
        
        let url = NSURL(string: urlString)!
        
        dataTask = urlSession.dataTaskWithURL(url) { (data, response, error) in
            self.dataTask = nil
            
            if error != nil || data == nil {
                NSLog("Failed to retrieve METAR reports. Retrying in 30 secs.")
                self.scheduleUpdateTimer(30)
                return
            }
            
            do {
                let result = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! Dictionary<String, NSObject>
                let results = result["features"] as! Array<Dictionary<String, NSObject>>
                
                let isoDateFormatter = NSDateFormatter()
                isoDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                isoDateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
                
                var reports = [MetarReport]()
                for airport in results {
                    let geometry = airport["geometry"] as! Dictionary<String, NSObject>
                    let coordinates = geometry["coordinates"] as! Array<NSNumber>
                    
                    let metarReport = MetarReport()
                    metarReport.position = GPSLocation(latitude: coordinates[1].doubleValue, longitude: coordinates[0].doubleValue)
                    
                    let properties = airport["properties"] as! Dictionary<String, NSObject>
                    metarReport.site = properties["site"] as? NSString as? String ?? "Unknown"
                    metarReport.observationTime = isoDateFormatter.dateFromString(properties["obsTime"] as! NSString as String)
                    if let temp = properties["temp"] as? NSNumber {
                        metarReport.temperature = temp.doubleValue
                    }
                    if let wspd = properties["wspd"] as? NSNumber {
                        metarReport.windSpeed = wspd.doubleValue
                    }
                    if let wdir = properties["wdir"] as? NSNumber {
                        metarReport.windDirection = wdir.doubleValue
                    }
                    if let wgst = properties["wgst"] as? NSNumber {
                        metarReport.windGust = wgst.doubleValue
                    }
                    if let visib = properties["visib"] as? NSNumber {
                        metarReport.visibility = visib.doubleValue
                    }
                    if metarReport.temperature == nil && metarReport.windSpeed == nil && metarReport.visibility == nil {
                        // Ignore empty reports
                        continue
                    }
                    metarReport.cover = properties["cover"] as? NSString as? String ?? nil
                    metarReport.wx = properties["wx"] as? NSString as? String ?? nil
                    metarReport.distance = getDistance(metarReport.position, self.position)
                    metarReport.heading = getHeading(self.position, to: metarReport.position)
                    
                    reports.append(metarReport)
                }
                
                if reports.isEmpty {
                    self.enlargeAreaAndRetryRetrieve()
                    return
                }
                
                reports.sortInPlace({
                    return $0.distance < $1.distance
                })
                
                self.reports = reports
            } catch let error as NSError {
                NSLog("METAR: Cannot read METAR result: %@", error)
            }
            self.finishedRetrieval()
        }
        dataTask!.resume()
    }
    
    private func enlargeAreaAndRetryRetrieve() {
        rangeMultiplier += 1
        if rangeMultiplier <= 5 {
            NSLog("No METAR site found. Retrying with multiplier %f", rangeMultiplier)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(100) * NSEC_PER_MSEC)), dispatch_get_main_queue(), {
                self.retrieveMetarReports()
            })
        } else {
            self.reports = nil
            finishedRetrieval()
        }
    }
    
    private func finishedRetrieval() {
        NSLog("Finished METARs retrieval")
        self.rangeMultiplier = 1
        self.lastRetrieveDate = NSDate()
        notifyObservers()
        scheduleUpdateTimer(self.updateFrequency)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        // Normally not called
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        // Normally not called
    }
    
    func addObserver(object: AnyObject, selector: Selector) {
        observers.append((object: object, selector: selector))
    }
    
    func removeObserver(observer: AnyObject) {
        for i in 0..<observers.count {
            if (observers[i].object === observer) {
                observers.removeAtIndex(i)
                break
            }
        }
    }
    
    private func notifyObservers() {
        dispatch_async(dispatch_get_main_queue()) {
            for (object, selector) in self.observers {
                object.performSelector(selector)
            }
        }
    }
    
    @objc
    private func appDidEnterBackground() {
        updateTimer?.invalidate();
        updateTimer = nil
    }
    
    @objc
    private func appDidBecomeActive() {
        if updateTimer == nil {
            if self.lastRetrieveDate == nil {
                updateTimerFired(nil)
            } else {
                let timeToNextUpdate = self.lastRetrieveDate!.dateByAddingTimeInterval(updateFrequency).timeIntervalSinceNow
                scheduleUpdateTimer(timeToNextUpdate)
            }
        }
    }
    
    private func scheduleUpdateTimer(interval: NSTimeInterval) {
        dispatch_async(dispatch_get_main_queue()) {
            if interval  <= 0 {
                self.updateTimerFired(nil)
            } else {
                NSLog("METARs update in %.0f sec", interval)
                self.updateTimer?.invalidate()
                self.updateTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(self.updateTimerFired), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc
    private func updateTimerFired(timer: NSTimer?) {
        updateCurrentLocationAndRetrieveReports()
    }
}

enum WeatherLevel : Int {
    case Clear = 0
    case PartlyCloudy
    case Overcast
    case Rain
    case Snow
    case Thunderstorm
}

class MetarReport {
    private static let wxWeatherLevels: [String : WeatherLevel] = [ "RA" : .Rain, "SN" : .Snow, "FG" : .Overcast, "TS" : .Thunderstorm, "IC" : .Snow, "GR" : .Snow, "UP" : .Rain,
                                    "BR" : .Overcast, "DU" : .Overcast, "SA" : .Overcast, "DS" : .Overcast, "DZ" : .Rain,
                                    "SG" : .Snow, "PL" : .Snow, "GS" : .Snow, "VA" : .Overcast, "HZ" : .Overcast, "FU" : .Overcast, "PY" : .Overcast,
                                    "PO" : .Overcast, "SS" : .Overcast, "SH" : .Rain ]
    private static let wxEvents = [ "RA" : "rain", "SN" : "snow", "FG" : "fog", "TS" : "thunderstorm", "IC" : "ice", "GR" : "hail", "UP" : "precipitations",
                                    "BR" : "mist", "DU" : "dust", "SA" : "sand", "SQ" : "squall", "DS" : "duststorm", "FC" : "funnel cloud", "DZ" : "drizzle",
                                    "SG" : "snow grains", "PL" : "ice pellets", "GS" : "snow pellets", "VA" : "ash", "HZ" : "haze", "FU" : "smoke", "PY" : "spray",
                                    "PO" : "dust", "SS" : "sandstorm", "SH" : "showers" ]
    private static let wxQualifiers = [ "-" : "light %@", "+" : "heavy %@", "MI" : "shallow %@", "BC" : "%@ patches", "BL" : "blowing %@", "TS" : "%@ thunderstorm",
                                        "VC" : "%@", "PR" : "partial %@", "DR" : "blowing %@", "SH" : "%@ showers", "FZ" : "freezing %@" ]
    
    var site = "Unknown"
    var position: GPSLocation!
    var observationTime: NSDate!
    var temperature: Double?        // ° Celsius
    var windSpeed: Double?          // knots
    var windGust: Double?           // knots
    var windDirection: Double?
    var visibility: Double?         // NM
    var cover: String?
    var wx: String?
    
    var distance: Double!
    var heading: Double!
    
    var _weatherLevel: WeatherLevel!
    var _description: String!
    
    var observationTimeFromNow: String {
        let interval = -observationTime!.timeIntervalSinceNow
        if interval < 3600 {
            return String(format: "%d min ago", Int(round(interval / 60)))
        } else {
            return String(format: "%d h ago", Int(round(interval / 3600)))
        }
    }
    
    var description: String {
        if _description == nil {
            parseWxAndCover()
        }
        return _description
    }

    var weatherLevel: WeatherLevel {
        if _weatherLevel == nil {
            parseWxAndCover()
        }
        return _weatherLevel
    }
    
    private func parseWxAndCover() {
        _description = ""
        _weatherLevel = .Clear
        if wx != nil {
            let events = wx!.characters.split(" ")
            for event in events {
                var eventDescription = describeEvent(String(event))
                if eventDescription.isEmpty {
                    continue
                }
                // Capitalize first char
                eventDescription.replaceRange(eventDescription.startIndex...eventDescription.startIndex, with: String(eventDescription[eventDescription.startIndex]).uppercaseString)
                
                if !description.isEmpty {
                    _description = _description.stringByAppendingString(", ")
                }
                _description = _description.stringByAppendingString(eventDescription)
            }
        }
        if _weatherLevel == .Clear && cover != nil {
            switch cover! {
            case "OVC":
                _weatherLevel = .Overcast
                if _description.isEmpty {
                    _description = "Cloudy"
                }
            case "BKN":
                _weatherLevel = .Overcast
                if _description.isEmpty {
                    _description = "Mostly cloudy"
                }
            case "SCT":
                _weatherLevel = .PartlyCloudy
                if _description.isEmpty {
                    _description = "Partly cloudy"
                }
            case "FEW":
                _weatherLevel = .PartlyCloudy
                if _description.isEmpty {
                    _description = "Mostly clear"
                }
                
            default:
                if _description.isEmpty {
                    _description = "Clear"
                }
                break
            }
        }
    }
    
    private func describeEvent(code: String) -> String {
        if code.hasPrefix("+") || code.hasPrefix("-") {
            let event = describeEvent(code.substringFromIndex(code.startIndex.successor()))
            if event == "" {
                return ""
            }
            return String(format: MetarReport.wxQualifiers[code.substringToIndex(code.startIndex.successor())]!, event)
        }
        var events = [String]()
        var moreEvents = [String]()
        var qualifiers = [String]()
        var lessQualifiers = [String]()
        var index = code.startIndex
        while index < code.endIndex.predecessor() {
            let nextIndex = index.advancedBy(2)
            let token = code.substringWithRange(index..<nextIndex)
            index = nextIndex
            
            if let level = MetarReport.wxWeatherLevels[token] where level.rawValue > _weatherLevel.rawValue {
                _weatherLevel = level
            }

            if let qualifier = MetarReport.wxQualifiers[token] {
                qualifiers.append(qualifier)
                if let event = MetarReport.wxEvents[token] {
                    moreEvents.append(event)
                } else {
                    lessQualifiers.append(qualifier)
                }
            }
            else if let event = MetarReport.wxEvents[token] {
                events.append(event)
            }
        }
        var event: String
        if events.isEmpty {
            if moreEvents.isEmpty {
                return ""
            }
            event = moreEvents.first!
            for qualifier in lessQualifiers {
                event = String(format: qualifier, event)
            }
        } else {
            event = events.first!
            for qualifier in qualifiers {
                event = String(format: qualifier, event)
            }
        }
        
        return event
    }
}
