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

class MetarManager : NSObject, URLSessionDelegate, URLSessionDataDelegate {
    static let instance = MetarManager()
    
    fileprivate let updateFrequency = 60.0 * 15   // Every 15 min
    
    fileprivate let latitudeRange = 0.9         // Approx. 100 km
    fileprivate let longitudeRange = 1.4        // Approx. 100 km at 48° lat

    fileprivate var urlSession : Foundation.URLSession!
    fileprivate var dataTask: URLSessionDataTask?
    
    fileprivate var position: GPSLocation!
    fileprivate var rangeMultiplier = 1.0
    fileprivate var lastRetrieveDate: Date?
    fileprivate var observers = [(object: AnyObject, selector: Selector)]()

    fileprivate(set) var reports: [MetarReport]!
    
    fileprivate var updateTimer: Timer?
    
    fileprivate override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        appDidBecomeActive()
        urlSession = Foundation.URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    }
    
    weak var locationProvider: UserLocationProvider! {
        didSet {
            // Only when setting the initial provider. Otherwise, let the update timer do its job
            if updateTimer == nil {
                updateCurrentLocationAndRetrieveReports()
            }
        }
    }
    
    fileprivate func updateCurrentLocationAndRetrieveReports() {
        locationProvider?.currentLocation() { [weak self] in
            self?.position = $0
            self?.retrieveMetarReports()
        }
    }
    
    fileprivate func retrieveMetarReports() {
        if dataTask != nil {
            return
        }
        
        let minLat = position.latitude - rangeMultiplier * latitudeRange
        let maxLat = position.latitude + rangeMultiplier * latitudeRange
        let minLon = position.longitude - rangeMultiplier * longitudeRange
        let maxLon = position.longitude + rangeMultiplier * longitudeRange
        
        let urlString = String(format: "https://aviationweather.gov/gis/scripts/MetarJSON.php?bbox=%f,%f,%f,%f&density=all", minLon, minLat, maxLon, maxLat)
        NSLog("Retrieving METARs: %@", urlString)
        
        let url = URL(string: urlString)!
        
        dataTask = urlSession.dataTask(with: url, completionHandler: { (data, response, error) in
            self.dataTask = nil
            
            if error != nil || data == nil {
                NSLog("Failed to retrieve METAR reports. Retrying in 30 secs.")
                self.scheduleUpdateTimer(30)
                return
            }
            
            do {
                let result = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! Dictionary<String, NSObject>
                let results = result["features"] as! Array<Dictionary<String, NSObject>>
                
                let isoDateFormatter = DateFormatter()
                isoDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                isoDateFormatter.locale = Locale(identifier: "en_US_POSIX")
                
                var reports = [MetarReport]()
                for airport in results {
                    let geometry = airport["geometry"] as! Dictionary<String, NSObject>
                    let coordinates = geometry["coordinates"] as! Array<NSNumber>
                    
                    let metarReport = MetarReport()
                    metarReport.position = GPSLocation(latitude: coordinates[1].doubleValue, longitude: coordinates[0].doubleValue)
                    
                    let properties = airport["properties"] as! Dictionary<String, NSObject>
                    metarReport.site = properties["site"] as? String ?? "Unknown"
                    metarReport.observationTime = isoDateFormatter.date(from: properties["obsTime"] as! String)
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
                    metarReport.cover = properties["cover"] as? String? ?? nil
                    metarReport.wx = properties["wx"] as? String? ?? nil
                    metarReport.distance = getDistance(metarReport.position, self.position)
                    metarReport.heading = getHeading(self.position, to: metarReport.position)
                    
                    reports.append(metarReport)
                }
                
                if reports.isEmpty {
                    self.enlargeAreaAndRetryRetrieve()
                    return
                }
                
                reports.sort(by: {
                    return $0.distance < $1.distance
                })
                
                self.reports = reports
            } catch let error as NSError {
                NSLog("METAR: Cannot read METAR result: %@", error)
            }
            self.finishedRetrieval()
        }) 
        dataTask!.resume()
    }
    
    fileprivate func enlargeAreaAndRetryRetrieve() {
        rangeMultiplier += 1
        if rangeMultiplier <= 5 {
            NSLog("No METAR site found. Retrying with multiplier %f", rangeMultiplier)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(UInt64(100) * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC), execute: {
                self.retrieveMetarReports()
            })
        } else {
            self.reports = nil
            finishedRetrieval()
        }
    }
    
    fileprivate func finishedRetrieval() {
        NSLog("Finished METARs retrieval")
        self.rangeMultiplier = 1
        self.lastRetrieveDate = Date()
        notifyObservers()
        scheduleUpdateTimer(self.updateFrequency)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Normally not called
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Normally not called
    }
    
    func addObserver(_ object: AnyObject, selector: Selector) {
        observers.append((object: object, selector: selector))
    }
    
    func removeObserver(_ observer: AnyObject) {
        for i in 0..<observers.count {
            if (observers[i].object === observer) {
                observers.remove(at: i)
                break
            }
        }
    }
    
    fileprivate func notifyObservers() {
        DispatchQueue.main.async {
            for (object, selector) in self.observers {
                _ = object.perform(selector)
            }
        }
    }
    
    @objc
    fileprivate func appDidEnterBackground() {
        updateTimer?.invalidate();
        updateTimer = nil
    }
    
    @objc
    fileprivate func appDidBecomeActive() {
        if updateTimer == nil {
            if self.lastRetrieveDate == nil {
                updateTimerFired(nil)
            } else {
                let timeToNextUpdate = self.lastRetrieveDate!.addingTimeInterval(updateFrequency).timeIntervalSinceNow
                scheduleUpdateTimer(timeToNextUpdate)
            }
        }
    }
    
    fileprivate func scheduleUpdateTimer(_ interval: TimeInterval) {
        DispatchQueue.main.async {
            if interval  <= 0 {
                self.updateTimerFired(nil)
            } else {
                NSLog("METARs update in %.0f sec", interval)
                self.updateTimer?.invalidate()
                self.updateTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.updateTimerFired), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc
    fileprivate func updateTimerFired(_ timer: Timer?) {
        updateCurrentLocationAndRetrieveReports()
    }
}

enum WeatherLevel : Int {
    case clear = 0
    case partlyCloudy
    case overcast
    case rain
    case snow
    case thunderstorm
}

class MetarReport {
    fileprivate static let wxWeatherLevels: [String : WeatherLevel] = [ "RA" : .rain, "SN" : .snow, "FG" : .overcast, "TS" : .thunderstorm, "IC" : .snow, "GR" : .snow, "UP" : .rain,
                                    "BR" : .overcast, "DU" : .overcast, "SA" : .overcast, "DS" : .overcast, "DZ" : .rain,
                                    "SG" : .snow, "PL" : .snow, "GS" : .snow, "VA" : .overcast, "HZ" : .overcast, "FU" : .overcast, "PY" : .overcast,
                                    "PO" : .overcast, "SS" : .overcast, "SH" : .rain ]
    fileprivate static let wxEvents = [ "RA" : "rain", "SN" : "snow", "FG" : "fog", "TS" : "thunderstorm", "IC" : "ice", "GR" : "hail", "UP" : "precipitations",
                                    "BR" : "mist", "DU" : "dust", "SA" : "sand", "SQ" : "squall", "DS" : "duststorm", "FC" : "funnel cloud", "DZ" : "drizzle",
                                    "SG" : "snow grains", "PL" : "ice pellets", "GS" : "snow pellets", "VA" : "ash", "HZ" : "haze", "FU" : "smoke", "PY" : "spray",
                                    "PO" : "dust", "SS" : "sandstorm", "SH" : "showers" ]
    fileprivate static let wxQualifiers = [ "-" : "light %@", "+" : "heavy %@", "MI" : "shallow %@", "BC" : "%@ patches", "BL" : "blowing %@", "TS" : "%@ thunderstorm",
                                        "VC" : "%@", "PR" : "partial %@", "DR" : "blowing %@", "SH" : "%@ showers", "FZ" : "freezing %@" ]
    
    var site = "Unknown"
    var position: GPSLocation!
    var observationTime: Date!
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
    
    fileprivate func parseWxAndCover() {
        _description = ""
        _weatherLevel = .clear
        if wx != nil {
            let events = wx!.characters.split(separator: " ")
            for event in events {
                var eventDescription = describeEvent(String(event))
                if eventDescription.isEmpty {
                    continue
                }
                // Capitalize first char
                eventDescription.replaceSubrange(eventDescription.startIndex...eventDescription.startIndex, with: String(eventDescription[eventDescription.startIndex]).uppercased())
                
                if !description.isEmpty {
                    _description = _description + ", "
                }
                _description = _description + eventDescription
            }
        }
        if _weatherLevel == .clear && cover != nil {
            switch cover! {
            case "OVC":
                _weatherLevel = .overcast
                if _description.isEmpty {
                    _description = "Cloudy"
                }
            case "BKN":
                _weatherLevel = .overcast
                if _description.isEmpty {
                    _description = "Mostly cloudy"
                }
            case "SCT":
                _weatherLevel = .partlyCloudy
                if _description.isEmpty {
                    _description = "Partly cloudy"
                }
            case "FEW":
                _weatherLevel = .partlyCloudy
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
    
    fileprivate func describeEvent(_ code: String) -> String {
        if code.hasPrefix("+") || code.hasPrefix("-") {
            let event = describeEvent(code.substring(from: code.characters.index(after: code.startIndex)))
            if event == "" {
                return ""
            }
            return String(format: MetarReport.wxQualifiers[code.substring(to: code.characters.index(after: code.startIndex))]!, event)
        }
        var events = [String]()
        var moreEvents = [String]()
        var qualifiers = [String]()
        var lessQualifiers = [String]()
        var index = code.startIndex
        while index < code.characters.index(before: code.endIndex) {
            let nextIndex = code.characters.index(index, offsetBy: 2)
            let token = code.substring(with: index..<nextIndex)
            index = nextIndex
            
            if let level = MetarReport.wxWeatherLevels[token], level.rawValue > _weatherLevel.rawValue {
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
