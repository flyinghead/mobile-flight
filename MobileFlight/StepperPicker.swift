//
//  StepperPicker.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 17/05/17.
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

class StepperPicker: StepperWithLabel {
    
    var selectedIndex: Int {
        get {
            return Int(value)
        }
        set(newValue) {
            self.value = Double(newValue)
        }
    }
    
    override func xibSetup() {
        super.xibSetup()

        stepper.minimumValue = 0
        stepper.maximumValue = 0
        stepper.stepValue = 1
        
        self.labelFormatter = { value in
            let index = Int(value)
            if self.labels != nil && index >= 0 && index < self.labels!.count {
                return String(format: "%@", self.labels![index])
            } else {
                return ""
            }
        }
    }
    
    var labels: [String]? {
        didSet {
            stepper.maximumValue = labels == nil || labels!.isEmpty ? 0.0 : Double(labels!.count - 1)
        }
    }
}
