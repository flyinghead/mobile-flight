//
//  VerticalScale.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 19/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

@IBDesignable
class VerticalScale: BaseVerticalScale {

    var bugs: [(value: Double, color: UIColor)] = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    @IBInspectable var precision: Int = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        
        CGContextClipToRect(ctx, bounds.insetBy(dx: layer.borderWidth, dy: layer.borderWidth))

        drawVerticalScale(ctx, top: Double(bounds.height) / 2.0 / scale + currentValue)
        for (value, color) in bugs {
            drawBug(ctx, value: value, color: color)
        }
        drawRollingDigitCounter(ctx)
    }

    private func drawRollingDigitCounter(ctx: CGContext) {
        CGContextSaveGState(ctx)
        
        let precision = pow(10.0, Double(self.precision))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Right
        
        let font = UIFont(name: "Verdana-Bold", size: self.fontSize)!
        let textAttributes: [String : AnyObject]? = [ NSFontAttributeName : font, NSForegroundColorAttributeName : UIColor.whiteColor(), NSParagraphStyleAttributeName : paragraphStyle]
        let fontSize = ("0" as NSString).sizeWithAttributes(textAttributes)
        
        let cornerRadius: CGFloat = fontSize.width / 3
        let markWidth = fontSize.height / 2 * 0.8660        // sin(60°)
        
        let minX = !rightAligned ? bounds.minX + markWidth + 4 : bounds.minX + 1
        let maxX = !rightAligned ? bounds.maxX - 1 : bounds.maxX - markWidth - 4
        let minY = bounds.midY - fontSize.height
        let maxY = bounds.midY + fontSize.height
        
        let rollerWidth = fontSize.width * CGFloat(self.precision + 1) + 8
        
        let path = CGPathCreateMutable()
        let commonHalfHeight = fontSize.height / 2
        CGPathMoveToPoint(path, nil, minX + cornerRadius, bounds.midY - commonHalfHeight)
        // Top
        CGPathAddLineToPoint(path, nil, maxX - rollerWidth, bounds.midY - commonHalfHeight)
        CGPathAddLineToPoint(path, nil, maxX - rollerWidth, minY + cornerRadius)
        CGPathAddArcToPoint(path, nil, maxX - rollerWidth, minY, maxX - rollerWidth + cornerRadius, minY, cornerRadius)
        CGPathAddLineToPoint(path, nil, maxX - cornerRadius, minY)
        CGPathAddArcToPoint(path, nil, maxX, minY, maxX, minY + cornerRadius, cornerRadius)
        // Right
        if rightAligned {
            CGPathAddLineToPoint(path, nil, maxX, bounds.midY - commonHalfHeight / 2)
            CGPathAddLineToPoint(path, nil, bounds.maxX - 4, bounds.midY)
            CGPathAddLineToPoint(path, nil, maxX, bounds.midY + commonHalfHeight / 2)
        }
        CGPathAddLineToPoint(path, nil, maxX, maxY - cornerRadius)
        CGPathAddArcToPoint(path, nil, maxX, maxY, maxX - cornerRadius, maxY, cornerRadius)
        // Bottom
        CGPathAddLineToPoint(path, nil, maxX - rollerWidth + cornerRadius, maxY)
        CGPathAddArcToPoint(path, nil, maxX - rollerWidth, maxY, maxX - rollerWidth, maxY - cornerRadius, cornerRadius)
        CGPathAddLineToPoint(path, nil, maxX - rollerWidth, bounds.midY + commonHalfHeight)
        CGPathAddLineToPoint(path, nil, minX + cornerRadius, bounds.midY + commonHalfHeight)
        CGPathAddArcToPoint(path, nil, minX, bounds.midY + commonHalfHeight, minX, bounds.midY + commonHalfHeight - cornerRadius, cornerRadius)
        // Left
        if !rightAligned {
            CGPathAddLineToPoint(path, nil, minX, bounds.midY + commonHalfHeight / 2)
            CGPathAddLineToPoint(path, nil, bounds.minX + 4, bounds.midY)
            CGPathAddLineToPoint(path, nil, minX, bounds.midY - commonHalfHeight / 2)
        }
        CGPathAddLineToPoint(path, nil, minX, bounds.midY - commonHalfHeight + cornerRadius)
        CGPathAddArcToPoint(path, nil, minX, bounds.midY - commonHalfHeight, minX + cornerRadius, bounds.midY - commonHalfHeight, cornerRadius)
        
        // Draw fill and stroke
        CGContextAddPath(ctx, path)
        CGContextSetFillColorWithColor(ctx, UIColor.blackColor().CGColor)
        CGContextSetStrokeColorWithColor(ctx, UIColor.lightGrayColor().CGColor)
        CGContextDrawPath(ctx, .FillStroke)
        
        CGContextAddPath(ctx, path)
        CGContextClip(ctx)
        
        let stringFormat: String
        if self.precision < 0 {
            stringFormat = String(format:"%%.0%df", -self.precision)
        } else {
            stringFormat = "%.0f"
        }
        
        let roundedValue = round(currentValue / precision) * precision
        let delta = (currentValue - roundedValue) / precision
        let textLeading = fontSize.height * 0.8
        
        // FIXME Check for negative values (if not allowed) and replace by empty string
        let stringValues: [String] = [String(format: stringFormat, roundedValue + precision), String(format: stringFormat, roundedValue), String(format: stringFormat, roundedValue - precision)]
        
        let commonPrefixString = commonPrefix([String](delta > 0 ? stringValues.prefix(2) : stringValues.suffix(2))) as NSString
        
        var suffix = uniqueSuffix(stringValues[0], refString: stringValues[1]) as NSString
        
        // FIXME: Not sure why we need the -2.5 offset to have the text perfectly centered in the control
        var textRect = CGRect(x: minX, y: bounds.midY - 2.5 + textLeading * CGFloat(-1.5 + delta), width: maxX - minX - 4, height: fontSize.height)
        suffix.drawInRect(textRect, withAttributes: textAttributes)
        
        textRect = textRect.offsetBy(dx: 0, dy: textLeading)
        suffix = uniqueSuffix(stringValues[1], refString: delta <= 0 ? stringValues[2] : stringValues[0]) as NSString
        
        let suffixWidth = suffix.sizeWithAttributes(textAttributes).width
        suffix.drawInRect(textRect, withAttributes: textAttributes)
        commonPrefixString.drawInRect(CGRect(x: textRect.minX, y: bounds.midY - 2.5 - textLeading / 2, width: textRect.width - suffixWidth, height: fontSize.height), withAttributes: textAttributes)
        
        textRect = textRect.offsetBy(dx: 0, dy: textLeading)
        suffix = uniqueSuffix(stringValues[2], refString: stringValues[1]) as NSString
        
        suffix.drawInRect(textRect, withAttributes: textAttributes)
        
        CGContextClipToRect(ctx, CGRect(x: maxX - rollerWidth + 4, y: minY, width: rollerWidth + 4 - 1, height: bounds.height))
        let locations: [CGFloat] = [ 0.0, 0.25, 0.75, 1 ]
        let colors: CFArray = [UIColor.blackColor().CGColor, UIColor.clearColor().CGColor, UIColor.clearColor().CGColor, UIColor.blackColor().CGColor]
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradientCreateWithColors(colorspace, colors, locations)
        CGContextDrawLinearGradient(ctx, gradient, CGPoint(x: maxX, y: minY), CGPoint(x: maxX, y: maxY), CGGradientDrawingOptions(rawValue: 0))
        
        CGContextRestoreGState(ctx)
    }
    
    private func commonPrefix(strings: [String]) -> String {
        var length = -1
        for s in strings {
            if length == -1 {
                length = s.characters.count
            } else if s.characters.count != length {
                return ""
            }
        }
        var commonPrefix = ""
        var index = 0
        while true {
            if index >= length {
                break
            }
            var char: Character?
            for s in strings {
                let c = s.characters[s.characters.startIndex.advancedBy(index)]
                if char == nil {
                    char = c
                } else if char != c {
                    char = nil
                    break
                }
            }
            if char == nil {
                break
            }
            commonPrefix.append(char!)
            index++
        }
        
        return commonPrefix
    }
    
    private func uniqueSuffix(string: String, refString: String) -> String {
        let chars = string.characters
        let refChars = refString.characters
        let length = chars.count
        if length != refChars.count {
            return string
        }
        for var index = 0; index < length; index++ {
            let charIndex = chars.startIndex.advancedBy(index)
            if chars[charIndex] != refChars[refChars.startIndex.advancedBy(index)] {
                return string.substringFromIndex(charIndex)
            }
        }
        return ""
    }
    
    func drawBug(ctx: CGContext, value: Double, color: UIColor) {
        let font = UIFont(name: "Verdana", size: self.fontSize)!
        let textAttributes: [String : AnyObject] = [ NSFontAttributeName : font ]
        let fontSize = ("0" as NSString).sizeWithAttributes(textAttributes)
        
        let markerHeight = fontSize.height * 2
        
        let top = bounds.midY - CGFloat((value - currentValue) * scale) - markerHeight / 2
        if top > bounds.maxY {
            return
        }
        let bottom = top + markerHeight
        if bottom < bounds.minY {
            return
        }
        let markerWidth = fontSize.height / 2 * 0.8660 + 4        // sin(60°)
        let right: CGFloat
        
        if rightAligned {
            right = bounds.maxX
        } else {
            right = bounds.minX + markerWidth
        }
        let left = right - markerWidth
        
        CGContextMoveToPoint(ctx, left, top)
        CGContextAddLineToPoint(ctx, right, top)
        if !rightAligned {
            CGContextAddLineToPoint(ctx, right, top + markerHeight / 2 - fontSize.height / 4)
            CGContextAddLineToPoint(ctx, right - markerWidth + 4, top + markerHeight / 2)
            CGContextAddLineToPoint(ctx, right, top + markerHeight / 2 + fontSize.height / 4)
        }
        CGContextAddLineToPoint(ctx, right, bottom)
        CGContextAddLineToPoint(ctx, left, bottom)
        if rightAligned {
            CGContextAddLineToPoint(ctx, left, top + markerHeight / 2 + fontSize.height / 4)
            CGContextAddLineToPoint(ctx, left + markerWidth - 4, top + markerHeight / 2)
            CGContextAddLineToPoint(ctx, left, top + markerHeight / 2 - fontSize.height / 4)
        }
        CGContextClosePath(ctx)
        
        CGContextSetFillColorWithColor(ctx, color.CGColor)
        CGContextSetStrokeColorWithColor(ctx, UIColor.darkGrayColor().CGColor)
        CGContextDrawPath(ctx, .FillStroke)
    }

}
