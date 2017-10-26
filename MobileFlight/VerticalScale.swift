//
//  VerticalScale.swift
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
class VerticalScale: BaseVerticalScale, NeedsOrigin {

    @IBInspectable var origin: Double = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
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

    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        
        ctx.clip(to: bounds.insetBy(dx: layer.borderWidth, dy: layer.borderWidth))

        drawVerticalScale(ctx, top: (origin - Double(bounds.minY)) / scale + currentValue)
        for (value, color) in bugs {
            drawBug(ctx, value: value, color: color)
        }
        drawRollingDigitCounter(ctx)
    }

    fileprivate func drawRollingDigitCounter(_ ctx: CGContext) {
        ctx.saveGState()
        
        let precision = pow(10.0, Double(self.precision))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        
        let font = UIFont(name: "Verdana-Bold", size: self.fontSize)!
        let textAttributes: [String : Any]? = [ NSFontAttributeName : font, NSForegroundColorAttributeName : UIColor.white, NSParagraphStyleAttributeName : paragraphStyle]
        let fontSize = ("0" as NSString).size(attributes: textAttributes)
        
        let cornerRadius: CGFloat = fontSize.width / 3
        let markWidth = fontSize.height / 2 * 0.8660        // sin(60°)
        
        let fOrigin = CGFloat(origin)
        let minX = !rightAligned ? bounds.minX + markWidth + 4 : bounds.minX + 1
        let maxX = !rightAligned ? bounds.maxX - 1 : bounds.maxX - markWidth - 4
        let minY = fOrigin - fontSize.height
        let maxY = fOrigin + fontSize.height
        
        let rollerWidth = fontSize.width * CGFloat(self.precision + 1) + 8
        
        let path = CGMutablePath()
        let commonHalfHeight = fontSize.height / 2
        path.move(to: CGPoint(x: minX + cornerRadius, y: fOrigin - commonHalfHeight))
        // Top
        path.addLine(to: CGPoint(x: maxX - rollerWidth, y: fOrigin - commonHalfHeight))
        path.addLine(to: CGPoint(x: maxX - rollerWidth, y: minY + cornerRadius))
        path.addArc(tangent1End: CGPoint(x: maxX - rollerWidth, y: minY), tangent2End: CGPoint(x: maxX - rollerWidth + cornerRadius, y: minY), radius: cornerRadius)
        path.addLine(to: CGPoint(x: maxX - cornerRadius, y: minY))
        path.addArc(tangent1End: CGPoint(x: maxX, y: minY), tangent2End: CGPoint(x: maxX, y: minY + cornerRadius), radius: cornerRadius)
        // Right
        if rightAligned {
            path.addLine(to: CGPoint(x: maxX, y: fOrigin - commonHalfHeight / 2))
            path.addLine(to: CGPoint(x: bounds.maxX - 4, y: fOrigin))
            path.addLine(to: CGPoint(x: maxX, y: fOrigin + commonHalfHeight / 2))
        }
        path.addLine(to: CGPoint(x: maxX, y: maxY - cornerRadius))
        path.addArc(tangent1End: CGPoint(x: maxX, y: maxY), tangent2End: CGPoint(x: maxX - cornerRadius, y: maxY), radius: cornerRadius)
        // Bottom
        path.addLine(to: CGPoint(x: maxX - rollerWidth + cornerRadius, y: maxY))
        path.addArc(tangent1End: CGPoint(x: maxX - rollerWidth, y: maxY), tangent2End: CGPoint(x: maxX - rollerWidth, y: maxY - cornerRadius), radius: cornerRadius)
        path.addLine(to: CGPoint(x: maxX - rollerWidth, y: fOrigin + commonHalfHeight))
        path.addLine(to: CGPoint(x: minX + cornerRadius, y: fOrigin + commonHalfHeight))
        path.addArc(tangent1End: CGPoint(x: minX, y: fOrigin + commonHalfHeight), tangent2End: CGPoint(x: minX, y: fOrigin + commonHalfHeight - cornerRadius), radius: cornerRadius)
        // Left
        if !rightAligned {
            path.addLine(to: CGPoint(x: minX, y: fOrigin + commonHalfHeight / 2))
            path.addLine(to: CGPoint(x: bounds.minX + 4, y: fOrigin))
            path.addLine(to: CGPoint(x: minX, y: fOrigin - commonHalfHeight / 2))
        }
        path.addLine(to: CGPoint(x: minX, y: fOrigin - commonHalfHeight + cornerRadius))
        path.addArc(tangent1End: CGPoint(x: minX, y: fOrigin - commonHalfHeight), tangent2End: CGPoint(x: minX + cornerRadius, y: fOrigin - commonHalfHeight), radius: cornerRadius)
        
        // Draw fill and stroke
        ctx.addPath(path)
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.setStrokeColor(UIColor.lightGray.cgColor)
        ctx.drawPath(using: .fillStroke)
        
        ctx.addPath(path)
        ctx.clip()
        
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
        var textRect = CGRect(x: minX, y: fOrigin - 2.5 + textLeading * CGFloat(-1.5 + delta), width: maxX - minX - 4, height: fontSize.height)
        suffix.draw(in: textRect, withAttributes: textAttributes)
        
        textRect = textRect.offsetBy(dx: 0, dy: textLeading)
        suffix = uniqueSuffix(stringValues[1], refString: delta <= 0 ? stringValues[2] : stringValues[0]) as NSString
        
        let suffixWidth = suffix.size(attributes: textAttributes).width
        suffix.draw(in: textRect, withAttributes: textAttributes)
        commonPrefixString.draw(in: CGRect(x: textRect.minX, y: fOrigin - 2.5 - textLeading / 2, width: textRect.width - suffixWidth, height: fontSize.height), withAttributes: textAttributes)
        
        textRect = textRect.offsetBy(dx: 0, dy: textLeading)
        suffix = uniqueSuffix(stringValues[2], refString: stringValues[1]) as NSString
        
        suffix.draw(in: textRect, withAttributes: textAttributes)
        
        ctx.clip(to: CGRect(x: maxX - rollerWidth + 4, y: minY, width: rollerWidth + 4 - 1, height: bounds.height))
        let locations: [CGFloat] = [ 0.0, 0.25, 0.75, 1 ]
        let colors = [UIColor.black.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.cgColor] as CFArray

        let colorspace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorspace, colors: colors, locations: locations)
        ctx.drawLinearGradient(gradient!, start: CGPoint(x: maxX, y: minY), end: CGPoint(x: maxX, y: maxY), options: CGGradientDrawingOptions(rawValue: 0))
        
        ctx.restoreGState()
    }
    
    fileprivate func commonPrefix(_ strings: [String]) -> String {
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
                let c = s.characters[s.characters.index(s.characters.startIndex, offsetBy: index)]
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
            index += 1
        }
        
        return commonPrefix
    }
    
    fileprivate func uniqueSuffix(_ string: String, refString: String) -> String {
        let chars = string.characters
        let refChars = refString.characters
        let length = chars.count
        if length != refChars.count {
            return string
        }
        for index in 0 ..< length {
            let charIndex = chars.index(chars.startIndex, offsetBy: index)
            if chars[charIndex] != refChars[refChars.index(refChars.startIndex, offsetBy: index)] {
                return string.substring(from: charIndex)
            }
        }
        return ""
    }
    
    func drawBug(_ ctx: CGContext, value: Double, color: UIColor) {
        let font = UIFont(name: "Verdana", size: self.fontSize)!
        let textAttributes: [String : Any] = [ NSFontAttributeName : font ]
        let fontSize = ("0" as NSString).size(attributes: textAttributes)
        
        let markerHeight = fontSize.height * 2
        
        let top = CGFloat(origin - (value - currentValue) * scale) - markerHeight / 2
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
        
        ctx.move(to: CGPoint(x: left, y: top))
        ctx.addLine(to: CGPoint(x: right, y: top))
        if !rightAligned {
            ctx.addLine(to: CGPoint(x: right, y: top + markerHeight / 2 - fontSize.height / 4))
            ctx.addLine(to: CGPoint(x: right - markerWidth + 4, y: top + markerHeight / 2))
            ctx.addLine(to: CGPoint(x: right, y: top + markerHeight / 2 + fontSize.height / 4))
        }
        ctx.addLine(to: CGPoint(x: right, y: bottom))
        ctx.addLine(to: CGPoint(x: left, y: bottom))
        if rightAligned {
            ctx.addLine(to: CGPoint(x: left, y: top + markerHeight / 2 + fontSize.height / 4))
            ctx.addLine(to: CGPoint(x: left + markerWidth - 4, y: top + markerHeight / 2))
            ctx.addLine(to: CGPoint(x: left, y: top + markerHeight / 2 - fontSize.height / 4))
        }
        ctx.closePath()
        
        ctx.setFillColor(color.cgColor)
        ctx.setStrokeColor(UIColor.darkGray.cgColor)
        ctx.drawPath(using: .fillStroke)
    }

}
