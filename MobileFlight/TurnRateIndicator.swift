//
//  TurnRateIndicator.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 19/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

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
