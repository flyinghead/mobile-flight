//
//  SimulatorViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 19/05/17.
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
