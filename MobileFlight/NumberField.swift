//
//  NumberField.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 12/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
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

@IBDesignable
class NumberField: UITextField {
    
    typealias ChangeCallback = (_ value: Double) -> Void
    
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
            changeCallback?(self._value)
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
        self.keyboardType = .decimalPad
        self.addTarget(self, action: #selector(NumberField.fieldChanged), for: .allEditingEvents)
        self.addTarget(self, action: #selector(NumberField.fieldEditingEnded), for: [.editingDidEnd, .editingDidEndOnExit])
        
        stepper.addTarget(self, action: #selector(NumberField.stepperChanged), for: .valueChanged)
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: stepper),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(NumberField.doneWithNumberPad))
        ]
        toolbar.sizeToFit()
        self.inputAccessoryView = toolbar
        
        savedTextColor = textColor
    }
    
    fileprivate func updateFieldText() {
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
            if let thousandChar = (Locale.current as NSLocale).object(forKey: NSLocale.Key.groupingSeparator) as! String? {
                tmpText = tmpText.replacingOccurrences(of: thousandChar, with: "")
            }
            
            let nf = NumberFormatter()
            nf.locale = Locale.current
            nf.maximumSignificantDigits = decimalDigits
            nf.minimumSignificantDigits = 0
            let value = nf.number(from: tmpText)
            if value != nil {
                stepper.value = value!.doubleValue
                self._value = stepper.value
                changeCallback?(self._value)
            }
        }
    }
    
    func stepperChanged() {
        UIDevice.current.playInputClick()
        value = stepper.value
        updateFieldText()
    }
    
    override var isEnabled: Bool {
        didSet {
            textColor = isEnabled ? savedTextColor : UIColor.lightGray
        }
    }
}

@IBDesignable
class ThrottleField : NumberField {
    override func customInit() {
        super.customInit()
        
        // Current throttle
        let current = UIBarButtonItem(title: "Current", style: .plain, target: self, action: #selector(ThrottleField.currentThrottle))
        toolbar.items?.insert(current, at: 1)
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
