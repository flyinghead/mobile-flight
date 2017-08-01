//
//  BeeperConfigViewController.swift
//  MobileFlight
//
//  Created by Raphael Jean-Leconte on 01/08/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class BeeperConfigViewController: ConfigChildViewController {
    @IBOutlet var switches: [UISwitch]!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        for uiswitch in switches {
            uiswitch.on = (settings.beeperMask & (1 << (uiswitch.tag - 1)) == 0)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        for uiswitch in switches {
            if uiswitch.on {
                settings.beeperMask &= ~(1 << (uiswitch.tag - 1))
            } else {
                settings.beeperMask |= 1 << (uiswitch.tag - 1)
            }
        }
    }
}
