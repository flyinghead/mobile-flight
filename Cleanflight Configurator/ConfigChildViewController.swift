//
//  ConfigChildViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 12/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class ConfigChildViewController: MyStaticDataViewController {
    
    var configViewController: ConfigurationViewController!
    var settings: Settings!
    var misc: Misc!

    func setReference(viewController: ConfigurationViewController, newSettings: Settings, newMisc: Misc) {
        self.configViewController = viewController
        self.settings = newSettings
        self.misc = newMisc
    }
}
