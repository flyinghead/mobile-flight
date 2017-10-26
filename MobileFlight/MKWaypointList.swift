//
//  MKWaypointList.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 10/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
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

class MKWaypointList : Sequence {
    var modifiedEvent = Event<Void>()
    var waypointCreatedEvent = Event<MKWaypoint>()      // Raised right after a waypoint is added
    var waypointDeletedEvent = Event<MKWaypoint>()      // Raised just before a waypoint is deleted

    var index = 0 {
        didSet {
            indexChangedEvent.raise(index)
        }
    }
    var indexChangedEvent = Event<Int>()
    
    fileprivate var waypoints = [MKWaypoint]()
    
    var activeWaypoint: MKWaypoint?

    func getWaypoints() -> [Waypoint] {
        var wps = [Waypoint]()
        for (i, wpAnnot) in waypoints.enumerated() {
            var wp = wpAnnot.waypoint
            wp.number = i + 1
            wp.last = i == waypoints.count - 1
            wps.append(wp)
        }
        
        return wps
    }
    
    fileprivate func createWaypointAnnotation(_ waypoint: Waypoint) -> MKWaypoint {
        let wpAnnot = MKWaypoint(waypoint: waypoint)
        _ = wpAnnot.waypointModifiedEvent.addHandler(self, handler: MKWaypointList.waypointModifiedHandler)
        
        return wpAnnot
    }
    
    func setWaypoints(_ waypoints: [Waypoint]) {
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
    
    func append(_ waypoint: Waypoint) {
        let wpAnnot = createWaypointAnnotation(waypoint)
        if waypoint.action == INavWaypointAction.known(.returnToHome) || waypoints.isEmpty || !waypoints.last!.returnToHome {
            wpAnnot.number = waypoints.count + 1
            waypoints.append(wpAnnot)
        } else {
            wpAnnot.number = waypoints.count
            waypoints.insert(wpAnnot, at: waypoints.count - 1)
            waypoints.last!.number = waypoints.count
        }
        waypointCreatedEvent.raise(wpAnnot)
        modifiedEvent.raise()
    }
    
    func remove(_ index: Int) {
        if index >= 0 && index < waypoints.count {
            waypointDeletedEvent.raise(waypoints[index])
            waypoints.remove(at: index)
            for (i, waypoint) in waypoints.enumerated() {
                waypoint.number = i + 1
            }
            modifiedEvent.raise()
        }
    }
    
    func waypointAt(_ index: Int) -> MKWaypoint {
        return waypoints[index]
    }
    
    func indexOf(_ waypoint: MKWaypoint) -> Int? {
        return waypoints.index(of: waypoint)
    }
    
    var last: MKWaypoint? {
        return waypoints.last
    }
    
    func makeIterator() -> AnyIterator<MKWaypoint> {
        var index = 0
        return AnyIterator {
            if index >= self.waypoints.count {
                return nil
            }
            index += 1
            return self.waypoints[index - 1]
        }
    }
    
    func enumerate() -> AnyIterator<(Int, MKWaypoint)> {
        var index = 0
        let g = makeIterator()
        return AnyIterator {
            if let item = g.next() {
                index += 1
                return (index - 1, item)
            }
            return nil
        }
    }
    
    fileprivate func waypointModifiedHandler(_ data: MKWaypoint) {
        modifiedEvent.raise()
    }
}
