//
//  HeadingStrip.swift
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
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        
        let font = UIFont(name: "Verdana", size: self.fontSize)!
        
        context.clip(to: bounds.insetBy(dx: layer.borderWidth, dy: layer.borderWidth))
        
        var left = heading - Double(rect.width) / 2.0 / scale
        
        if subTicksInterval != 0 {
            left = ceil(left / subTicksInterval) * subTicksInterval
        } else {
            left = ceil(left / mainTicksInterval) * mainTicksInterval
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let textAttributes: [String : Any]? = [ NSFontAttributeName : font, NSForegroundColorAttributeName : UIColor.white, NSParagraphStyleAttributeName : paragraphStyle]
        let fontSize = ("0" as NSString).size(attributes: textAttributes)
        
        context.setFillColor(UIColor.white.cgColor)
        
        while true {
            let x = CGFloat(Double(rect.width) / 2.0 - (heading - left) * scale) + rect.minX
            
            var width: CGFloat
            var length: CGFloat
            if left == round(left / mainTicksInterval) * mainTicksInterval {
                width = 2
                length = fontSize.width
                
                var degrees = round(left).truncatingRemainder(dividingBy: 360)
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
                let textSize = (string as NSString).size(attributes: textAttributes)
                if x - textSize.width/2 > rect.maxX {
                    break
                }
                string.draw(in: CGRect(x: x - textSize.width/2, y: rect.maxY - fontSize.width  - fontSize.height, width: textSize.width, height: textSize.height), withAttributes: textAttributes)
            } else {
                width = 2
                length = fontSize.width * 0.75
            }
            
            if x > rect.maxX {
                break
            }
            context.fill(CGRect(x: x, y: rect.maxY - length, width: width, height: length))
            
            if subTicksInterval != 0 {
                left = round((left + subTicksInterval) / subTicksInterval) * subTicksInterval
            } else {
                left = round((left + mainTicksInterval) / mainTicksInterval) * mainTicksInterval
            }
        }
        
        for (value, color) in bugs {
            drawBug(context, value: value, color: color, fontSize: fontSize)
        }
        
        context.setFillColor(UIColor.white.cgColor)
        context.move(to: CGPoint(x: rect.midX, y: rect.maxY - fontSize.width))
        context.addLine(to: CGPoint(x: rect.midX - fontSize.width / 2 / CGFloat(sin(Float.pi / 3)), y: rect.maxY))
        context.addLine(to: CGPoint(x: rect.midX + fontSize.width / 2 / CGFloat(sin(Float.pi / 3)), y: rect.maxY))
        context.closePath()
        context.fillPath()
        
    }

    func drawBug(_ ctx: CGContext, value: Double, color: UIColor, fontSize: CGSize) {
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
        
        ctx.move(to: CGPoint(x: left, y: bottom))
        ctx.addLine(to: CGPoint(x: left, y: top))
        ctx.addLine(to: CGPoint(x: right, y: top))
        ctx.addLine(to: CGPoint(x: right, y: bottom))
        ctx.addLine(to: CGPoint(x: left + markerWidth / 2 + fontSize.height / 4, y: bottom))
        ctx.addLine(to: CGPoint(x: left + markerWidth / 2, y: bottom - markerHeight + 4))
        ctx.addLine(to: CGPoint(x: left + markerWidth / 2 - fontSize.height / 4, y: bottom))
        ctx.closePath()
        
        ctx.setFillColor(color.cgColor)
        ctx.setStrokeColor(UIColor.darkGray.cgColor)
        ctx.drawPath(using: .fillStroke)
    }
}
