//
//  BaseVerticalScale.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 26/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class BaseVerticalScale: UIView {

    var currentValue: Double = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var rightAligned: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var scale: Double = 10.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var fontSize: CGFloat = 14.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var mainTicksInterval: Double = 10.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var subTicksInterval: Double = 5.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var subSubTicksInterval: Double = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    @IBInspectable var positiveOnly: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    func drawVerticalScale(context: CGContext, top: Double) {
        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
        var value = top
        
        if subSubTicksInterval != 0 {
            value = ceil(value / subSubTicksInterval) * subSubTicksInterval
        } else if subTicksInterval != 0 {
            value = ceil(value / subTicksInterval) * subTicksInterval
        } else {
            value = ceil(value / mainTicksInterval) * mainTicksInterval
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = rightAligned ? .Right : .Left
        
        let font = UIFont(name: "Verdana", size: self.fontSize)!
        let textAttributes: [String : AnyObject]? = [ NSFontAttributeName : font, NSForegroundColorAttributeName : UIColor.whiteColor(), NSParagraphStyleAttributeName : paragraphStyle]
        let fontSize = ("0" as NSString).sizeWithAttributes(textAttributes)
        
        while true {
            let y = CGFloat((top - value) * scale) + bounds.minY
            let graduationTextTop = y - fontSize.height / 2 - 0.5
            if graduationTextTop > bounds.maxY {
                break
            }
            var width: CGFloat
            var length: CGFloat
            if value >= 0 || !positiveOnly {
                if value == round(value / mainTicksInterval) * mainTicksInterval {
                    width = 2
                    length = fontSize.width
                    
                    let string = String(format:"%.0f", value)             // FIXME how many decimals??
                    string.drawInRect(CGRect(x: rightAligned ? bounds.minX : bounds.minX + fontSize.width * 1.5, y: graduationTextTop, width: bounds.width - fontSize.width * 1.5, height: fontSize.height), withAttributes: textAttributes)
                } else if subTicksInterval != 0 && value == round(value / subTicksInterval) * subTicksInterval {
                    width = 2
                    length = fontSize.width * 0.75
                } else {
                    width = 1
                    length = fontSize.width * 0.5
                }
                
                CGContextFillRect(context, CGRect(x: rightAligned ? bounds.maxX - length : bounds.minX, y: y - width / 2, width: length, height: width))
            }
            
            if subSubTicksInterval != 0 {
                let next = (value - subSubTicksInterval) / subSubTicksInterval
                value = round(next) * subSubTicksInterval
            } else if subTicksInterval != 0 {
                value = round((value - subTicksInterval) / subTicksInterval) * subTicksInterval
            } else {
                value = round((value - mainTicksInterval) / mainTicksInterval) * mainTicksInterval
            }
        }
    }
}
