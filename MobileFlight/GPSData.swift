//
//  GPSData.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 12/06/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation
import MapKit

struct GpsSatQuality : OptionSetType, DictionaryCoding {
    let rawValue: Int
    
    static let none = GpsSatQuality(rawValue: 0)
    static let svUsed = GpsSatQuality(rawValue: 1 << 0)         // Used for navigation
    static let diffCorr = GpsSatQuality(rawValue: 1 << 1)       // Differential correction data is available for this SV
    static let orbitAvail = GpsSatQuality(rawValue: 1 << 2)     // Orbit information is available for this SV (Ephemeris or Almanach)
    static let orbitEph = GpsSatQuality(rawValue: 1 << 3)       // Orbit information is Ephemeris
    static let unhealthy = GpsSatQuality(rawValue: 1 << 4)      // SV is unhealthy / shall not be used
    static let orbitAlm = GpsSatQuality(rawValue: 1 << 5)       // Orbit information is Almanac Plus
    static let orbitAop = GpsSatQuality(rawValue: 1 << 6)       // Orbit information is AssistNow Autonomous
    static let smoothed = GpsSatQuality(rawValue: 1 << 7)       // Carrier smoothed pseudorange used (see PPP for details)
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    // MARK: DictionaryCoding
    func toDict() -> NSDictionary {
        return ["rawValue": rawValue]
    }
    
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let rawValue = dict["rawValue"] as? Int
            else { return nil }
        self.rawValue = rawValue
    }
}

struct Satellite : DictionaryCoding {
    var channel: Int    // Channel number
    var svid: Int       // Satellite ID
    var quality: GpsSatQuality    // Bitfield Quality
    var cno: Int        // Carrier to Noise Ratio (Signal Strength 0-99 dB)
    
    init(channel: Int, svid: Int, quality: GpsSatQuality, cno: Int) {
        self.channel = channel
        self.svid = svid
        self.quality = quality
        self.cno = cno
    }
    
    // MARK: DictionaryCoding
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let channel = dict["channel"] as? Int,
            let svid = dict["svid"] as? Int,
            let quality = dict["quality"] as? NSDictionary,
            let cno = dict["cno"] as? Int
            else { return nil }
        
        self.init(channel: channel, svid: svid, quality: GpsSatQuality(fromDict: quality)!, cno: cno)
    }
    
    func toDict() -> NSDictionary {
        return [ "channel": channel, "svid": svid, "quality": quality.toDict(), "cno": cno ]
    }
}

struct GPSLocation : DictionaryCoding, Equatable  {
    var latitude: Double
    var longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // MARK: DictionaryCoding
    init?(fromDict: NSDictionary?) {
        guard let dict = fromDict,
            let latitude = dict["latitude"] as? Double,
            let longitude = dict["longitude"] as? Double
            else { return nil }
        
        self.init(latitude: latitude, longitude: longitude)
    }
    
    func toDict() -> NSDictionary {
        return [ "latitude": latitude, "longitude": longitude ]
    }
    
    // MARK:
    
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
func ==(lhs: GPSLocation, rhs: GPSLocation) -> Bool {
    return lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude
}


class GPSData : AutoCoded {
    var autoEncoding = [ "fix", "latitude", "longitude", "altitude", "speed", "headingOverGround", "numSat", "distanceToHome", "directionToHome", "update", "lastKnownGoodLatitude", "lastKnownGoodLongitude", "lastKnownGoodAltitude", "lastKnownGoodTimestamp" ]
    static var theGPSData = GPSData()
    
    // MSP_RAW_GPS
    var fix = false
    var position: GPSLocation = GPSLocation(latitude: 0, longitude: 0) {
        didSet {
            if fix {
                // Hack to avoid bogus first position with lat or long at 0 when the object is decoded and uses the lat and long setters in sequence
                if position.latitude != 0 && position.longitude != 0 {
                    lastKnownGoodLatitude = position.latitude
                    lastKnownGoodLongitude = position.longitude
                    lastKnownGoodTimestamp = NSDate()
                    
                    positions.append(position.toCLLocationCoordinate2D())
                }
            }
        }
    }
    var latitude: Double {          // degree
        get {
            return position.latitude
        }
        // FIXME Only needed for backward compatibility of old flight log files
        set(value) {
            position.latitude = value
        }
    }
    var longitude: Double {         // degree
        get {
            return position.longitude
        }
        // FIXME Only needed for backward compatibility of old flight log files
        set(value) {
            position.longitude = value
        }
    }
    var altitude = 0 {           // m
        willSet(value) {
            if fix {
                lastKnownGoodAltitude = value
                maxAltitude = max(maxAltitude, value)
                if lastAltitudeTime != nil {
                    variometer = Double(value - altitude) / -lastAltitudeTime!.timeIntervalSinceNow
                }
                lastAltitudeTime = NSDate()
            }
        }
    }
    var speed = 0.0 {             // km/h
        didSet {
            if fix {
                maxSpeed = max(maxSpeed, speed)
            }
        }
    }
    var headingOverGround = 0.0 // degree
    var numSat = 0
    
    // MSP_COMP_GPS
    var distanceToHome = 0 {      // m
        didSet {
            if fix {
                maxDistanceToHome = max(maxDistanceToHome, distanceToHome)
            }
        }
    }
    var directionToHome = 0     // degree
    var update = 0
    
    // MSP_WP
    var homePosition: GPSLocation?
    var posHoldPosition: GPSLocation?
    
    // Local
    var lastKnownGoodLatitude = 0.0
    var lastKnownGoodLongitude = 0.0
    var lastKnownGoodAltitude = 0
    var lastKnownGoodTimestamp: NSDate?
    var maxDistanceToHome = 0
    var maxAltitude = 0
    var variometer = 0.0
    var lastAltitudeTime: NSDate?
    var maxSpeed = 0.0
    var positions = [CLLocationCoordinate2D]()
    
    // MSP_GPSSVINFO
    private var _satellites = [Satellite]()
    
    var satellites: [Satellite] {
        get {
            return [Satellite](_satellites)
        }
        set(value) {
            _satellites = value
        }
    }
    
    override init() {
        super.init()
    }
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if let satellitesDicts = aDecoder.decodeObjectForKey("satellites") as? [NSDictionary] {
            _satellites = [Satellite]()
            for dict in satellitesDicts {
                _satellites.append(Satellite(fromDict: dict)!)
            }
        }
        if let positionDict = aDecoder.decodeObjectForKey("position") as? NSDictionary {
            position = GPSLocation(fromDict: positionDict)!
        }
        if let positionDict = aDecoder.decodeObjectForKey("homePosition") as? NSDictionary {
            homePosition = GPSLocation(fromDict: positionDict)!
        }
        if let positionDict = aDecoder.decodeObjectForKey("posHoldPosition") as? NSDictionary {
            posHoldPosition = GPSLocation(fromDict: positionDict)!
        }
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        
        var satellitesDicts = [NSDictionary]()
        for satellite in _satellites {
            satellitesDicts.append(satellite.toDict())
        }
        aCoder.encodeObject(satellitesDicts, forKey: "satellites")
        aCoder.encodeObject(position.toDict(), forKey: "position")
        if homePosition != nil {
            aCoder.encodeObject(homePosition!.toDict(), forKey: "homePosition")
        }
        if posHoldPosition != nil {
            aCoder.encodeObject(posHoldPosition!.toDict(), forKey: "posHoldPosition")
        }
    }
}
