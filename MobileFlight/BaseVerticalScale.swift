//
//  BaseVerticalScale.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 26/01/16.
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
    
    func drawVerticalScale(_ context: CGContext, top: Double) {
        context.setFillColor(UIColor.white.cgColor)
        var value = top
        
        if subSubTicksInterval != 0 {
            value = ceil(value / subSubTicksInterval) * subSubTicksInterval
        } else if subTicksInterval != 0 {
            value = ceil(value / subTicksInterval) * subTicksInterval
        } else {
            value = ceil(value / mainTicksInterval) * mainTicksInterval
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = rightAligned ? .right : .left
        
        let font = UIFont(name: "Verdana", size: self.fontSize)!
        let textAttributes: [String : Any]? = [ NSFontAttributeName : font, NSForegroundColorAttributeName : UIColor.white, NSParagraphStyleAttributeName : paragraphStyle]
        let fontSize = ("0" as NSString).size(attributes: textAttributes)
        
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
                    string.draw(in: CGRect(x: rightAligned ? bounds.minX : bounds.minX + fontSize.width * 1.5, y: graduationTextTop, width: bounds.width - fontSize.width * 1.5, height: fontSize.height), withAttributes: textAttributes)
                } else if subTicksInterval != 0 && value == round(value / subTicksInterval) * subTicksInterval {
                    width = 2
                    length = fontSize.width * 0.75
                } else {
                    width = 1
                    length = fontSize.width * 0.5
                }
                
                context.fill(CGRect(x: rightAligned ? bounds.maxX - length : bounds.minX, y: y - width / 2, width: length, height: width))
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
