//
//  NumberField.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 12/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

@IBDesignable
class NumberField: UITextField, UIInputViewAudioFeedback {
    
    @IBInspectable var decimalDigits: Int = 0 {
        didSet {
            updateFieldText()
        }
    }
    @IBInspectable var value: Double = 0.0 {
        didSet {
            stepper.value = value
            updateFieldText()
        }
    }
    @IBInspectable var minimumValue: Double = 0.0 {
        didSet {
            stepper.minimumValue = minimumValue
            enforceMinMax()
        }
    }
    @IBInspectable var maximumValue: Double = 100.0 {
        didSet {
            stepper.maximumValue = maximumValue
            enforceMinMax()
        }
    }
    @IBInspectable var increment: Double = 1.0 {
        didSet {
            stepper.stepValue = increment
        }
    }
    @IBInspectable var wraps: Bool = false {
        didSet {
            stepper.wraps = wraps
        }
    }
    
    let stepper = UIStepper()
    let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customInit()
    }
    
    func customInit() {
        self.keyboardType = .DecimalPad
        self.addTarget(self, action: "fieldChanged", forControlEvents: .AllEditingEvents)
        self.addTarget(self, action: "fieldEditingEnded", forControlEvents: [.EditingDidEnd, .EditingDidEndOnExit])
        
        stepper.addTarget(self, action: "stepperChanged", forControlEvents: .ValueChanged)
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: stepper),
            UIBarButtonItem(title: "Done", style: .Done, target: self, action: "doneWithNumberPad")
        ]
        toolbar.sizeToFit()
        self.inputAccessoryView = toolbar
    }
    
    private func updateFieldText() {
        let stringFormat = String(format: "%%.%dlf", decimalDigits)
        self.text = String(format: stringFormat, value)
    }
    
    private func enforceMinMax() {
        if minimumValue > maximumValue {
            // Bad configuration, nothing to enforce
            return
        }
        let newValue = min(maximumValue, max(minimumValue, stepper.value))
        if newValue != stepper.value {
            updateFieldText()
        }
    }
    
    func doneWithNumberPad() {
        endEditing(true)
    }
    
    func fieldEditingEnded() {
        // Stepper value has been updated by previous editing events. It's now time to 
        // display the current correct value in the text field.
        value = stepper.value
        updateFieldText()
    }
    
    func fieldChanged() {
        if text != nil {
            let value = Double(text!)
            if value != nil {
                self.value = value!
                stepper.value = value!
            }
        }
    }
    
    func stepperChanged() {
//        UIDevice.currentDevice().playInputClick()     // Doesn't work?
        value = stepper.value
        updateFieldText()
    }
    
    var enableInputClicksWhenVisible: Bool {
        return true
    }
}

@IBDesignable
class ThrottleField : NumberField {
    override func customInit() {
        super.customInit()
        
        // Current throttle
        let current = UIBarButtonItem(title: "Current", style: .Plain, target: self, action: "currentThrottle")
        toolbar.items?.insert(current, atIndex: 1)
        toolbar.sizeToFit()
    }
    
    func currentThrottle() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.msp.sendMessage(.MSP_RC, data: nil, retry: 0, callback: { success in
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    self.value = Double(Receiver.theReceiver.channels[3])
                })
            }
        })
    }
}
