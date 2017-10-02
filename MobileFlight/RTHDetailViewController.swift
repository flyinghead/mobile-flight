//
//  RTHDetailViewController.swift
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

import UIKit

class RTHDetailViewController: BaseWaypointDetailViewController {
    @IBOutlet weak var rthSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        hideSectionsWithHiddenRows = true
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if index >= waypointList.count || !waypointList.last!.returnToHome {
            rthSwitch.on = false
        } else {
            rthSwitch.on = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if rthSwitch.on {
            if index >= waypointList.count || !waypointList.last!.returnToHome {
                waypointList.append(Waypoint.rthWaypoint())
            }
        } else {
            if waypointList.count > 0 && waypointList.last!.returnToHome {
                waypointList.remove(waypointList.count - 1)
            }
        }
    }
}
