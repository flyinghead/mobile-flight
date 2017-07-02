//
//  MKWaypoint.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 02/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation
import MapKit

class MKWaypoint : NSObject, MKAnnotation {
    var waypoint: Waypoint
    var waypointModifiedEvent = Event<MKWaypoint>()
    
    init(waypoint: Waypoint) {
        self.waypoint = waypoint
        super.init()
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return waypoint.position.toCLLocationCoordinate2D()
        }
        set {
            let newLocation = GPSLocation(latitude: newValue.latitude, longitude: newValue.longitude)
            if newLocation != waypoint.position {
                waypoint.position = newLocation
                waypointModifiedEvent.raise(self)
            }
        }
    }
    
    var title: String? {
        return String(format:"Waypoint #%d", waypoint.number)
    }
    
    var subtitle: String? {
        return waypoint.altitude == 0.0 ? nil : String(format:"Altitude: %@", formatAltitude(waypoint.altitude))
    }
    
    var altitude: Double {
        get {
            return waypoint.altitude
        }
        set {
            if waypoint.altitude != newValue {
                willChangeValueForKey("title")      // To update the title in the callout
                waypoint.altitude = newValue
                didChangeValueForKey("title")
                waypointModifiedEvent.raise(self)
            }
        }
    }
    
    var returnToHome: Bool {
        return waypoint.action == .Known(.ReturnToHome)
    }
    
    var number: Int {
        get {
            return waypoint.number
        }
        set {
            willChangeValueForKey("title")      // To update the title in the callout
            waypoint.number = newValue
            didChangeValueForKey("title")
        }
    }
    
    // Speed in m/s
    var speed: Double {
        // param1 is the speed in cm/s
        get {
            return Double(waypoint.param1) / 100
        }
        set {
            let newSpeed = Int(round(newValue * 100.0))
            if waypoint.param1 != newSpeed {
                waypoint.param1 = newSpeed
                waypointModifiedEvent.raise(self)
            }
        }
    }
}
