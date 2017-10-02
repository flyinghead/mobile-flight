//
//  TurnRateIndicator.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 19/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
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
class TurnRateIndicator: UIView {

    var value: Double = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var scale: Double =  0.5 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var color: UIColor =  UIColor.magentaColor() {
        didSet {
            setNeedsDisplay()
        }
    }

    override func drawRect(rectxxx: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        
        CGContextSetFillColorWithColor(ctx, color.CGColor)
        if value < 0 {
            CGContextFillRect(ctx, CGRect(x: bounds.midX + CGFloat(value * scale), y: bounds.minY, width: -CGFloat(value * scale), height: bounds.height))
        } else {
            CGContextFillRect(ctx, CGRect(x: bounds.midX, y: bounds.minY, width: CGFloat(value * scale), height: bounds.height))
        }
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextFillRect(ctx, CGRect(x: bounds.midX - 0.5, y: bounds.minY + 1, width: 1, height: bounds.height - 2))
    }

}
