//
//  HeadingStrip.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 19/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

@IBDesignable
class HeadingStrip: UIView {
    
    var heading: Double = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var scale: Double = 2.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    @IBInspectable var fontSize: CGFloat = 14.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    @IBInspectable var mainTicksInterval: Double = 30.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var subTicksInterval: Double = 10.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var bugs: [(value: Double, color: UIColor)] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        
        let font = UIFont(name: "Verdana", size: self.fontSize)!
        
        CGContextClipToRect(context, bounds.insetBy(dx: layer.borderWidth, dy: layer.borderWidth))
        
        var left = heading - Double(rect.width) / 2.0 / scale
        
        if subTicksInterval != 0 {
            left = ceil(left / subTicksInterval) * subTicksInterval
        } else {
            left = ceil(left / mainTicksInterval) * mainTicksInterval
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Center
        
        let textAttributes: [String : AnyObject]? = [ NSFontAttributeName : font, NSForegroundColorAttributeName : UIColor.whiteColor(), NSParagraphStyleAttributeName : paragraphStyle]
        let fontSize = ("0" as NSString).sizeWithAttributes(textAttributes)
        
        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
        
        while true {
            let x = CGFloat(Double(rect.width) / 2.0 - (heading - left) * scale) + rect.minX
            
            var width: CGFloat
            var length: CGFloat
            if left == round(left / mainTicksInterval) * mainTicksInterval {
                width = 2
                length = fontSize.width
                
                var degrees = round(left) % 360
                if degrees < 0 {
                    degrees += 360
                }
                let string: String
                switch degrees {
                case 0:
                    string = "N"
                case 90:
                    string = "E"
                case 180:
                    string = "S"
                case 270:
                    string = "W"
                default:
                    string = String(format:"%.0f", degrees)
                }
                let textSize = (string as NSString).sizeWithAttributes(textAttributes)
                if x - textSize.width/2 > rect.maxX {
                    break
                }
                string.drawInRect(CGRect(x: x - textSize.width/2, y: rect.maxY - fontSize.width  - fontSize.height, width: textSize.width, height: textSize.height), withAttributes: textAttributes)
            } else {
                width = 2
                length = fontSize.width * 0.75
            }
            
            if x > rect.maxX {
                break
            }
            CGContextFillRect(context, CGRect(x: x, y: rect.maxY - length, width: width, height: length))
            
            if subTicksInterval != 0 {
                left = round((left + subTicksInterval) / subTicksInterval) * subTicksInterval
            } else {
                left = round((left + mainTicksInterval) / mainTicksInterval) * mainTicksInterval
            }
        }
        
        for (value, color) in bugs {
            drawBug(context, value: value, color: color, fontSize: fontSize)
        }
        
        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextMoveToPoint(context, rect.midX, rect.maxY - fontSize.width)
        CGContextAddLineToPoint(context, rect.midX - fontSize.width / 2 / CGFloat(sin(M_PI / 3)), rect.maxY)
        CGContextAddLineToPoint(context, rect.midX + fontSize.width / 2 / CGFloat(sin(M_PI / 3)), rect.maxY)
        CGContextClosePath(context)
        CGContextFillPath(context)
        
    }

    func drawBug(ctx: CGContext, value: Double, color: UIColor, fontSize: CGSize) {
        let markerWidth = fontSize.height * 2
        
        var diff = value - heading
        if diff > 180 {
            diff -= 360
        } else if diff < -180 {
            diff += 360
        }
        let left = bounds.midX - CGFloat(diff * scale) - markerWidth / 2
        if left > bounds.maxX {
            return
        }
        let right = left + markerWidth
        if right < bounds.minX {
            return
        }
        let markerHeight = fontSize.height / 2 * 0.8660 + 4        // sin(60°)
        let bottom = bounds.maxY
        let top = bottom - markerHeight
        
        CGContextMoveToPoint(ctx, left, bottom)
        CGContextAddLineToPoint(ctx, left, top)
        CGContextAddLineToPoint(ctx, right, top)
        CGContextAddLineToPoint(ctx, right, bottom)
        CGContextAddLineToPoint(ctx, left + markerWidth / 2 + fontSize.height / 4, bottom)
        CGContextAddLineToPoint(ctx, left + markerWidth / 2, bottom - markerHeight + 4)
        CGContextAddLineToPoint(ctx, left + markerWidth / 2 - fontSize.height / 4, bottom)
        CGContextClosePath(ctx)
        
        CGContextSetFillColorWithColor(ctx, color.CGColor)
        CGContextSetStrokeColorWithColor(ctx, UIColor.darkGrayColor().CGColor)
        CGContextDrawPath(ctx, .FillStroke)
    }
}
