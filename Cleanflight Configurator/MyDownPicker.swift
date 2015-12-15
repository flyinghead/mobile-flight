//
//  MyDownPicker.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 14/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import DownPicker

class MyDownPicker: DownPicker {
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
}
