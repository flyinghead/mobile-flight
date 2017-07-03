//
//  StepperPicker.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 17/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

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
