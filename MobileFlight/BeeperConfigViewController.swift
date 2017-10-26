//
//  BeeperConfigViewController.swift
//  MobileFlight
//
//  Created by Raphael Jean-Leconte on 01/08/17.
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

class BeeperConfigViewController: ConfigChildViewController {
    @IBOutlet var switches: [UISwitch]!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        for uiswitch in switches {
            uiswitch.isOn = (settings.beeperMask & (1 << (uiswitch.tag - 1)) == 0)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        for uiswitch in switches {
            if uiswitch.isOn {
                settings.beeperMask &= ~(1 << (uiswitch.tag - 1))
            } else {
                settings.beeperMask |= 1 << (uiswitch.tag - 1)
            }
        }
    }
}
