//
//  RTHDetailViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 10/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

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
