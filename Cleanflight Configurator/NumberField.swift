//
//  NumberField.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 12/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

@IBDesignable
class NumberField: UITextField {
    
    @IBInspectable var decimalDigits: Int = 0 {
        didSet {
            updateFieldText()
        }
    }
    
    var _value = 0.0
    @IBInspectable var value: Double {
        get {
            return _value
        }
        set(value) {
            stepper.value = value
            _value = stepper.value
            updateFieldText()
        }
    }
    @IBInspectable var minimumValue: Double = 0.0 {
        didSet {
            stepper.minimumValue = minimumValue
            let prevValue = _value
            _value = stepper.value
            if prevValue != _value {
                updateFieldText()
            }
        }
    }
    @IBInspectable var maximumValue: Double = 100.0 {
        didSet {
            stepper.maximumValue = maximumValue
            let prevValue = _value
            _value = stepper.value
            if prevValue != _value {
                updateFieldText()
            }
        }
    }
    @IBInspectable var increment: Double = 1.0 {
        didSet {
            if increment == 0 {
                stepper.hidden = true
            } else {
                stepper.hidden = false
                stepper.stepValue = increment
            }
        }
    }
    @IBInspectable var wraps: Bool = false {
        didSet {
            stepper.wraps = wraps
        }
    }
    @IBInspectable var suggestedMinimum: Double? {
        didSet {
            setStepperTintColor()
        }
    }
    @IBInspectable var suggestedMaximum: Double? {
        didSet {
            setStepperTintColor()
        }
    }
    
    let stepper = UIStepper()
    let toolbar = InputAccessoryToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
    
    var savedTextColor: UIColor!
    
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
        
        savedTextColor = textColor
    }
    
    private func updateFieldText() {
        let formatter = NSNumberFormatter()
        formatter.locale = NSLocale.currentLocale()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = decimalDigits
        self.text = formatter.stringFromNumber(value)
    }

    func doneWithNumberPad() {
        endEditing(true)
    }
    
    func fieldEditingEnded() {
        // Stepper value has been updated by previous editing events. It's now time to 
        // display the current correct value in the text field.
        value = stepper.value
    }
    
    func fieldChanged() {
        if text != nil {
            // Remove the thousand separators as they confuse the NSNumberFormatter
            var tmpText = text!
            if let thousandChar = NSLocale.currentLocale().objectForKey(NSLocaleGroupingSeparator) as! String? {
                tmpText = tmpText.stringByReplacingOccurrencesOfString(thousandChar, withString: "")
            }
            
            let nf = NSNumberFormatter()
            nf.locale = NSLocale.currentLocale()
            nf.maximumSignificantDigits = decimalDigits
            nf.minimumSignificantDigits = 0
            let value = nf.numberFromString(tmpText)
            if value != nil {
                stepper.value = value!.doubleValue
                self._value = stepper.value
                setStepperTintColor()
            }
        }
    }
    
    func stepperChanged() {
        UIDevice.currentDevice().playInputClick()
        value = stepper.value
        updateFieldText()
        setStepperTintColor()
    }
    
    override var enabled: Bool {
        didSet {
            textColor = enabled ? savedTextColor : UIColor.lightGrayColor()
        }
    }
    
    private func setStepperTintColor() {
        if (suggestedMinimum != nil && _value < suggestedMinimum!) || (suggestedMaximum != nil && _value > suggestedMaximum!) {
            stepper.tintColor = UIColor.redColor()
        } else {
            stepper.tintColor = stepper.superview!.tintColor
        }
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
    
    private var vehicle: Vehicle {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.vehicle
    }
    
    func currentThrottle() {
        if let throttleValue = vehicle.rcChannels.value?[2] {
            self.value = Double(throttleValue)
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        if super.becomeFirstResponder() {
            vehicle.rcChannels.addObserver(self, listener: { newValue in })
            
            return true
        } else {
            return false
        }
    }
    
    override func resignFirstResponder() -> Bool {
        if super.resignFirstResponder() {
            vehicle.rcChannels.removeObserver(self)
            
            return true
        } else {
            return false
        }
    }
}

class InputAccessoryToolbar : UIToolbar, UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool {
        return true
    }
}
