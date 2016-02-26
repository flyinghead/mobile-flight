//
//  SimpleVerticalScale.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 26/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

@IBDesignable
class SimpleVerticalScale: BaseVerticalScale {

    override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        
        CGContextClipToRect(ctx, bounds.insetBy(dx: layer.borderWidth, dy: layer.borderWidth))
        
        let topValue = Double(bounds.height) / 2.0 / scale
        drawVerticalScale(ctx, top: topValue)
        drawNeedle(ctx, topValue: topValue)
    }

    func drawNeedle(ctx: CGContext, topValue: Double) {
        let font = UIFont(name: "Verdana", size: self.fontSize)!
        let textAttributes: [String : AnyObject] = [ NSFontAttributeName : font ]
        let fontSize = ("0" as NSString).sizeWithAttributes(textAttributes)
        
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
            CGContextMoveToPoint(ctx, right, top)
            CGContextAddLineToPoint(ctx, right - markerWidth + 4, top + markerHeight / 2)
            CGContextAddLineToPoint(ctx, right, top + markerHeight)
        }
        if rightAligned {
            CGContextMoveToPoint(ctx, left, top)
            CGContextAddLineToPoint(ctx, left + markerWidth - 4, top + markerHeight / 2)
            CGContextAddLineToPoint(ctx, left, top + markerHeight)
        }
        CGContextClosePath(ctx)
        
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextDrawPath(ctx, .FillStroke)
    }
}
