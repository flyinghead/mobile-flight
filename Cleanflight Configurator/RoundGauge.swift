//
//  RoundGauge.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 21/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

@IBDesignable
class RoundGauge: UIView {

    var value: Double = 50.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var minimum: Double = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var maximum: Double = 100.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var ranges = [(min: Double, max: Double, color: UIColor)]()
    
    override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!

        let squareBounds: CGRect
        if bounds.width > bounds.height {
            squareBounds = bounds.insetBy(dx: (bounds.width - bounds.height) / 2, dy: 0)
        } else {
            squareBounds = bounds.insetBy(dx: 0, dy: (bounds.height - bounds.width) / 2)
        }
        
        let minAngle = 2 * M_PI / 3
        let maxAngle = 2 * M_PI
        CGContextAddArc(ctx, squareBounds.midX, squareBounds.midY, squareBounds.height / 2 - 1, CGFloat(minAngle), CGFloat(maxAngle), 0)
        CGContextSetStrokeColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextSetLineWidth(ctx, 2)
        CGContextStrokePath(ctx)
        
        for (rangeMin, rangeMax, color) in ranges {
            CGContextAddArc(ctx, squareBounds.midX, squareBounds.midY, squareBounds.height / 2 - 3, CGFloat(minAngle + (rangeMin - minimum) * (maxAngle - minAngle) / (maximum - minimum)), CGFloat(minAngle + (rangeMax - minimum) * (maxAngle - minAngle) / (maximum - minimum)), 0)
            CGContextSetStrokeColorWithColor(ctx, color.CGColor)
            CGContextSetLineWidth(ctx, 4)
            CGContextStrokePath(ctx)
        }
        
        CGContextTranslateCTM(ctx, squareBounds.midX, squareBounds.midY)
        CGContextRotateCTM(ctx, CGFloat(minAngle + (constrain(value, min: minimum, max: maximum) - minimum) * (maxAngle - minAngle) / (maximum - minimum) + M_PI / 2))
        let radius: CGFloat = squareBounds.height / 20
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextFillEllipseInRect(ctx, CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2).offsetBy(dx: -radius, dy: -radius))
        
        let dy = radius * radius / 2 / squareBounds.height / 2
        let dx = sqrt(radius * radius - dy * dy)
        
        CGContextMoveToPoint(ctx, 0, -squareBounds.height / 2)
        CGContextAddLineToPoint(ctx, -dx, -dy)
        CGContextAddLineToPoint(ctx, dx, -dy)
        CGContextClosePath(ctx)
        CGContextFillPath(ctx)
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        value = minimum + (maximum - minimum) * 0.5
        ranges.removeAll()
        ranges.append((min: minimum, max: minimum + (maximum - minimum) * 0.6, color: UIColor.greenColor()))
        ranges.append((min: minimum + (maximum - minimum) * 0.6, max: minimum + (maximum - minimum) * 0.8, color: UIColor.yellowColor()))
        ranges.append((min: minimum + (maximum - minimum) * 0.8, max: maximum, color: UIColor.redColor()))
    }
}
