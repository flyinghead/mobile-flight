//
//  WaypointViewController.swift
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

class WaypointViewController: UIViewController {
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var previousButton: UIBarButtonItem!
    @IBOutlet weak var nextButton: UIBarButtonItem!

    var waypointList: MKWaypointList! {
        didSet {
            _ = waypointList?.indexChangedEvent.addHandler(self, handler: WaypointViewController.indexChanged)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        indexChanged(waypointList.index)
    }
    
    func indexChanged(_ data: Int) {
        title = String(format: "Waypoint #%d", data + 1)
        previousButton?.isEnabled = data > 0
        nextButton?.isEnabled = data + 1 < waypointList.count || (data + 1 < INavConfig.theINavConfig.maxWaypoints && data + 1 == waypointList.count && !waypointList.last!.returnToHome)
        deleteButton.isEnabled = data < waypointList.count && !waypointList.waypointAt(data).returnToHome
    }
    
    @IBAction func closeAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        if waypointList.index < 0 || waypointList.index >= waypointList.count {
            return
        }
        if waypointList.waypointAt(waypointList.index).returnToHome {
            return
        }
        waypointList.remove(waypointList.index)
        if waypointList.count == 0 || (waypointList.count == 1 && waypointList.last!.returnToHome) {
            closeAction(self)
        } else if waypointList.index > 0 {
            waypointList.index -= 1
        } else {
            waypointList.index = waypointList.index
        }
    }
    
    @IBAction func nextAction(_ sender: Any) {
        waypointList.index += 1
    }
    
    @IBAction func previousAction(_ sender: Any) {
        waypointList.index -= 1
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let pageViewController = segue.destination as? WaypointPageViewController {
            pageViewController.waypointList = waypointList
        }
    }
}
