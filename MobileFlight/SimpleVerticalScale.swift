//
//  SimpleVerticalScale.swift
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

@IBDesignable
class SimpleVerticalScale: BaseVerticalScale, NeedsOrigin {

    @IBInspectable var origin: Double = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        
        ctx.clip(to: bounds.insetBy(dx: layer.borderWidth, dy: layer.borderWidth))
        
        let topValue = (origin - Double(bounds.minY)) / scale
        drawVerticalScale(ctx, top: topValue)
        drawNeedle(ctx, topValue: topValue)
    }

    func drawNeedle(_ ctx: CGContext, topValue: Double) {
        let font = UIFont(name: "Verdana", size: self.fontSize)!
        let textAttributes: [String : Any] = [ NSFontAttributeName : font ]
        let fontSize = ("0" as NSString).size(attributes: textAttributes)
        
        let markerHeight = fontSize.height / 1.5
        
        var top = bounds.minY + CGFloat((topValue - currentValue) * scale) - markerHeight / 2
        if top < bounds.minY + markerHeight / 2 {
            top = bounds.minY + markerHeight / 2
        }
        var bottom = top + markerHeight
        if bottom > bounds.maxY - markerHeight / 2 {
            bottom = bounds.maxY - markerHeight / 2
            top = bottom - markerHeight
        }

        let markerWidth = markerHeight * 0.8660 + 4        // sin(60°)
        let right: CGFloat
        
        if rightAligned {
            right = bounds.maxX
        } else {
            right = bounds.minX + markerWidth
        }
        let left = right - markerWidth
        
        if !rightAligned {
            ctx.move(to: CGPoint(x: right, y: top))
            ctx.addLine(to: CGPoint(x: right - markerWidth + 4, y: top + markerHeight / 2))
            ctx.addLine(to: CGPoint(x: right, y: top + markerHeight))
        }
        if rightAligned {
            ctx.move(to: CGPoint(x: left, y: top))
            ctx.addLine(to: CGPoint(x: left + markerWidth - 4, y: top + markerHeight / 2))
            ctx.addLine(to: CGPoint(x: left, y: top + markerHeight))
        }
        ctx.closePath()
        
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.drawPath(using: .fillStroke)
    }
}
