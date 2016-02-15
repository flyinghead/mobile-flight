//
//  InsetTextField.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 14/02/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class InsetTextField: UITextField {
    // Placeholder position
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, 8, 8)
    }
    
    // Text position
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, 8, 8)
    }
}
