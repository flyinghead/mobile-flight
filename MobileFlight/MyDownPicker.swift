//
//  MyDownPicker.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 14/12/15.
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
import DownPicker

class MyDownPicker: DownPicker {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override init!(textField tf: UITextField!) {
        super.init(textField: tf)
        setPlaceholder("")
    }
    
    override init!(textField tf: UITextField!, withData data: [AnyObject]!) {
        super.init(textField: tf, withData: data)
        setPlaceholder("")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        let beginEditing = super.textFieldShouldBeginEditing(textField)
        if beginEditing {
            sendActionsForControlEvents(.EditingDidBegin)
        }
        
        return beginEditing
    }
    
    override func textFieldDidEndEditing(textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        sendActionsForControlEvents(.EditingDidEnd)
    }

    override var selectedIndex: Int {
        get {
            return super.selectedIndex
        }
        set(value) {
            // Hack to get the size of the data array
            let dataCount = super.pickerView(UIPickerView(), numberOfRowsInComponent: 0)
            if value < 0 || value >= dataCount {
                super.selectedIndex = -1
            } else {
                super.selectedIndex = value
            }
        }
    }
}
