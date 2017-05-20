//
//  SimulatorViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 19/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class SimulatorViewController: UIViewController {
    @IBOutlet weak var startButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        startButton.layer.borderColor = startButton.tintColor.CGColor

    }
    
    @IBAction func startAction(sender: AnyObject) {
        _ = Simulator(msp: self.msp)
        (self.parentViewController as! MainConnectionViewController).presentNextViewController()
        
    }
}
