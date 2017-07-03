//
//  AttitudeIndicator2.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 19/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

@IBDesignable
class AttitudeIndicator2: UIView {
    var roll = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var pitch = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var horizonY: Double = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    @IBInspectable var fontSize: CGFloat = 11.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var skyColor: UIColor =  UIColor(colorLiteralRed: Float(0x33) / 255, green: Float(0x99) / 255, blue: Float(0xFF) / 255, alpha: 1) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var groundColor: UIColor =  UIColor.brownColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        
        CGContextClipToRect(ctx, rect)
        
        let horizonY = self.horizonY * Double(bounds.height) + Double(bounds.minY)
        let roll = self.roll * M_PI / 180

        let topRollMarkHeight = 15 * CGFloat(sin(M_PI / 2.7))
        
        var indicatorWidth = min(bounds.midX - bounds.minX - layoutMargins.left, bounds.maxX - layoutMargins.right - bounds.midX)
        indicatorWidth = min(indicatorWidth, CGFloat(horizonY) - bounds.minY - layoutMargins.top - topRollMarkHeight)
        indicatorWidth = min(indicatorWidth, bounds.maxY - layoutMargins.bottom - bounds.midY) * 2

        let pitchScale = Double(indicatorWidth) / 100.0 as Double         // pixels per degree
        
        CGContextTranslateCTM(ctx, bounds.midX, CGFloat(horizonY - pitch * pitchScale))
        CGContextRotateCTM(ctx, CGFloat(-roll))
        
        // Sky
        CGContextSetFillColorWithColor(ctx, skyColor.CGColor)
        CGContextFillRect(ctx, CGRect(x: -bounds.width * 1.5, y: -bounds.height * 1.5, width: bounds.width * 3, height: bounds.height * 1.5))
        
        // Ground
        CGContextSetFillColorWithColor(ctx, groundColor.CGColor)
        CGContextFillRect(ctx, CGRect(x: -bounds.width * 1.5, y: 0, width: bounds.width * 3, height: bounds.height * 1.5))
        
        // Horizon
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextFillRect(ctx, CGRect(x: -bounds.width * 1.5, y: -0.5, width: bounds.width * 3, height: 1))
        
        // Pitch angle scale
        CGContextSetStrokeColorWithColor(ctx, UIColor.whiteColor().CGColor)
        let scaleFont = UIFont(name: "Verdana", size: fontSize)!
        let attributes: [String : AnyObject]? = [ NSFontAttributeName : scaleFont, NSForegroundColorAttributeName : UIColor.whiteColor()]
        for pitch in [-20, -10, 10, 20] {
            let y = CGFloat(Double(pitch) * pitchScale)
            CGContextMoveToPoint(ctx, -20, y)
            CGContextAddLineToPoint(ctx, 20, y)
            
            let legend = String(format: "%d", abs(pitch)) as NSString
            let legendSize = legend.sizeWithAttributes(attributes)
            legend.drawInRect(CGRect(origin: CGPoint(x: -24 - legendSize.width, y: y - legendSize.height / 2), size: legendSize), withAttributes: attributes)
            legend.drawInRect(CGRect(origin: CGPoint(x: 24, y: y - legendSize.height / 2), size: legendSize), withAttributes: attributes)
        }
        for pitch in [-25, -15, -5, 5, 15, 25] {
            let y = CGFloat(Double(pitch) * pitchScale)
            CGContextMoveToPoint(ctx, -10, y)
            CGContextAddLineToPoint(ctx, 10, y)
        }
        CGContextStrokePath(ctx)
        
        // Roll angle scale
        CGContextRotateCTM(ctx, CGFloat(roll))
        CGContextTranslateCTM(ctx, 0, CGFloat(pitch * pitchScale))
        CGContextRotateCTM(ctx, CGFloat(-roll))
        
        CGContextSetStrokeColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextAddArc(ctx, 0, 0, indicatorWidth / 2, CGFloat(-5 * M_PI / 6.0), CGFloat(-M_PI / 6.0), 0)
        
        for a in [-5.0, -4.0, -2.0, -1.0] {
            CGContextMoveToPoint(ctx, CGFloat(cos(a * M_PI / 6.0)) * (indicatorWidth / 2), CGFloat(sin(a * M_PI / 6.0)) * (indicatorWidth / 2))
            CGContextAddLineToPoint(ctx, CGContextGetPathCurrentPoint(ctx).x + CGFloat(cos(a * M_PI / 6.0)) * 10, CGContextGetPathCurrentPoint(ctx).y + CGFloat(sin(a * M_PI / 6.0)) * 10)
        }
        for a in [-4.5, -3.6666, -3.3333, -2.6666, -2.3333, -1.5] {
            CGContextMoveToPoint(ctx, CGFloat(cos(a * M_PI / 6.0)) * (indicatorWidth / 2), CGFloat(sin(a * M_PI / 6.0)) * (indicatorWidth / 2))
            CGContextAddLineToPoint(ctx, CGContextGetPathCurrentPoint(ctx).x + CGFloat(cos(a * M_PI / 6.0)) * 6, CGContextGetPathCurrentPoint(ctx).y + CGFloat(sin(a * M_PI / 6.0)) * 6)
        }
        CGContextMoveToPoint(ctx, 0, -indicatorWidth / 2)
        
        let topRollMarkHalfWidth = 15 * CGFloat(cos(M_PI / 2.7))
        CGContextAddLineToPoint(ctx, CGContextGetPathCurrentPoint(ctx).x + topRollMarkHalfWidth, CGContextGetPathCurrentPoint(ctx).y - topRollMarkHeight)
        CGContextAddLineToPoint(ctx, CGContextGetPathCurrentPoint(ctx).x - topRollMarkHalfWidth * 2, CGContextGetPathCurrentPoint(ctx).y)
        CGContextAddLineToPoint(ctx, CGContextGetPathCurrentPoint(ctx).x + topRollMarkHalfWidth, CGContextGetPathCurrentPoint(ctx).y + topRollMarkHeight)
        
        CGContextStrokePath(ctx)
        
        CGContextRotateCTM(ctx, CGFloat(roll))
        CGContextTranslateCTM(ctx, -bounds.midX, CGFloat(-horizonY))
        
        // Yellow roll reference
        let cornerRadius: CGFloat = 2

        CGContextSetStrokeColorWithColor(ctx, UIColor.yellowColor().CGColor)
        CGContextSetLineWidth(ctx, 3)
        CGContextMoveToPoint(ctx, bounds.midX, CGFloat(horizonY - Double(indicatorWidth) / 2 + 3))
        let dx = 15 * CGFloat(cos(M_PI / 2.7))
        let dy = 15 * sin(M_PI / 2.7)
        CGContextAddLineToPoint(ctx, bounds.midX + dx, CGFloat(horizonY - Double(indicatorWidth) / 2 + 3 + dy))
        CGContextAddLineToPoint(ctx, bounds.midX - dx, CGFloat(horizonY - Double(indicatorWidth) / 2 + 3 + dy))
        CGContextClosePath(ctx)
        CGContextStrokePath(ctx)
        
        // Yellow horizon reference
        CGContextSetLineWidth(ctx, 1)
        CGContextSetFillColorWithColor(ctx, UIColor.yellowColor().CGColor)
        CGContextMoveToPoint(ctx, bounds.midX - indicatorWidth / 2 + cornerRadius, CGFloat(horizonY) - cornerRadius)
        CGContextAddLineToPoint(ctx, bounds.midX - 30 - cornerRadius, CGFloat(horizonY) - cornerRadius)
        CGContextAddArc(ctx, bounds.midX - 30 - cornerRadius, CGFloat(horizonY), cornerRadius, CGFloat(-M_PI / 2), CGFloat(M_PI / 2), 0)
        CGContextAddLineToPoint(ctx, bounds.midX - indicatorWidth / 2 + cornerRadius, CGFloat(horizonY) + cornerRadius)
        CGContextAddArc(ctx, bounds.midX - indicatorWidth / 2 + cornerRadius, CGFloat(horizonY), cornerRadius, CGFloat(M_PI / 2), CGFloat(-M_PI / 2), 0)
        CGContextFillPath(ctx)
        
        CGContextMoveToPoint(ctx, bounds.midX + indicatorWidth / 2 - cornerRadius, CGFloat(horizonY) - cornerRadius)
        CGContextAddLineToPoint(ctx, bounds.midX + 30 + cornerRadius, CGFloat(horizonY) - cornerRadius)
        CGContextAddArc(ctx, bounds.midX + 30 + cornerRadius, CGFloat(horizonY), cornerRadius, CGFloat(-M_PI / 2), CGFloat(M_PI / 2), 1)
        CGContextAddLineToPoint(ctx, bounds.midX + indicatorWidth / 2 - cornerRadius, CGFloat(horizonY) + cornerRadius)
        CGContextAddArc(ctx, bounds.midX + indicatorWidth / 2 - cornerRadius, CGFloat(horizonY), cornerRadius, CGFloat(M_PI / 2), CGFloat(-M_PI / 2), 1)
        CGContextFillPath(ctx)
        
        CGContextFillEllipseInRect(ctx, CGRect(x: bounds.midX - cornerRadius, y: CGFloat(horizonY) - cornerRadius, width: cornerRadius * 2, height: cornerRadius * 2))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let originY = self.horizonY * Double(bounds.height) + Double(bounds.minY)
        for v in subviews {
            if var view = v as? NeedsOrigin {
                view.origin = originY - Double(v.frame.minY)
            }
        }

    }
}

protocol NeedsOrigin {
    var origin: Double { get set }
}
