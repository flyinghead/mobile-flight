//
//  NumberField.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 12/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

@IBDesignable
class NumberField: UITextField {
    
    typealias ChangeCallback = (value: Double) -> Void
    
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
            changeCallback?(value: self._value)
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
            stepper.stepValue = increment
        }
    }
    @IBInspectable var wraps: Bool = false {
        didSet {
            stepper.wraps = wraps
        }
    }
    
    var changeCallback: ChangeCallback?
    
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
        self.addTarget(self, action: #selector(NumberField.fieldChanged), forControlEvents: .AllEditingEvents)
        self.addTarget(self, action: #selector(NumberField.fieldEditingEnded), forControlEvents: [.EditingDidEnd, .EditingDidEndOnExit])
        
        stepper.addTarget(self, action: #selector(NumberField.stepperChanged), forControlEvents: .ValueChanged)
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: stepper),
            UIBarButtonItem(title: "Done", style: .Done, target: self, action: #selector(NumberField.doneWithNumberPad))
        ]
        toolbar.sizeToFit()
        self.inputAccessoryView = toolbar
        
        savedTextColor = textColor
    }
    
    private func updateFieldText() {
        self.text = formatNumber(value, precision: decimalDigits)
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
                changeCallback?(value: self._value)
            }
        }
    }
    
    func stepperChanged() {
        UIDevice.currentDevice().playInputClick()
        value = stepper.value
        updateFieldText()
    }
    
    override var enabled: Bool {
        didSet {
            textColor = enabled ? savedTextColor : UIColor.lightGrayColor()
        }
    }
}

@IBDesignable
class ThrottleField : NumberField {
    override func customInit() {
        super.customInit()
        
        // Current throttle
        let current = UIBarButtonItem(title: "Current", style: .Plain, target: self, action: #selector(ThrottleField.currentThrottle))
        toolbar.items?.insert(current, atIndex: 1)
        toolbar.sizeToFit()
    }
    
    func currentThrottle() {
        self.value = Double(Receiver.theReceiver.channels[3])
    }
}

class InputAccessoryToolbar : UIToolbar, UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool {
        return true
    }
}
