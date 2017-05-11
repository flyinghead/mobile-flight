//
//  MKWaypointList.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 10/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class MKWaypointList : SequenceType {
    var modifiedEvent = Event<Void>()
    var waypointCreatedEvent = Event<MKWaypoint>()      // Raised right after a waypoint is added
    var waypointDeletedEvent = Event<MKWaypoint>()      // Raised just before a waypoint is deleted

    var index = 0 {
        didSet {
            indexChangedEvent.raise(index)
        }
    }
    var indexChangedEvent = Event<Int>()
    
    private var waypoints = [MKWaypoint]()

    func getWaypoints() -> [Waypoint] {
        var wps = [Waypoint]()
        for (i, wpAnnot) in waypoints.enumerate() {
            var wp = wpAnnot.waypoint
            wp.number = i + 1
            wp.last = i == waypoints.count - 1
            wps.append(wp)
        }
        
        return wps
    }
    
    private func createWaypointAnnotation(waypoint: Waypoint) -> MKWaypoint {
        let wpAnnot = MKWaypoint(waypoint: waypoint)
        wpAnnot.waypointModifiedEvent.addHandler(self, handler: MKWaypointList.waypointModifiedHandler)
        
        return wpAnnot
    }
    
    func setWaypoints(waypoints: [Waypoint]) {
        for waypoint in self.waypoints {
            waypointDeletedEvent.raise(waypoint)
        }
        self.waypoints.removeAll()
        for waypoint in waypoints {
            let wpAnnot = createWaypointAnnotation(waypoint)
            self.waypoints.append(wpAnnot)
            waypointCreatedEvent.raise(wpAnnot)
        }
    }
    
    var count: Int {
        return waypoints.count
    }
    
    func append(waypoint: Waypoint) {
        let wpAnnot = createWaypointAnnotation(waypoint)
        if waypoint.action == INavWaypointAction.Known(.ReturnToHome) || waypoints.isEmpty || !waypoints.last!.returnToHome {
            wpAnnot.number = waypoints.count + 1
            waypoints.append(wpAnnot)
        } else {
            wpAnnot.number = waypoints.count
            waypoints.insert(wpAnnot, atIndex: waypoints.count - 1)
            waypoints.last!.number = waypoints.count
        }
        waypointCreatedEvent.raise(wpAnnot)
        modifiedEvent.raise()
    }
    
    func remove(index: Int) {
        if index >= 0 && index < waypoints.count {
            waypointDeletedEvent.raise(waypoints[index])
            waypoints.removeAtIndex(index)
            for (i, waypoint) in waypoints.enumerate() {
                waypoint.number = i + 1
            }
            modifiedEvent.raise()
        }
    }
    
    func waypointAt(index: Int) -> MKWaypoint {
        return waypoints[index]
    }
    
    func indexOf(waypoint: MKWaypoint) -> Int? {
        return waypoints.indexOf(waypoint)
    }
    
    var last: MKWaypoint? {
        return waypoints.last
    }
    
    func generate() -> AnyGenerator<MKWaypoint> {
        var index = 0
        return AnyGenerator {
            if index >= self.waypoints.count {
                return nil
            }
            index += 1
            return self.waypoints[index - 1]
        }
    }
    
    func enumerate() -> AnyGenerator<(Int, MKWaypoint)> {
        var index = 0
        let g = generate()
        return AnyGenerator {
            if let item = g.next() {
                index += 1
                return (index - 1, item)
            }
            return nil
        }
    }
    
    private func waypointModifiedHandler(data: MKWaypoint) {
        modifiedEvent.raise()
    }
}
