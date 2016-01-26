//
//  RCStick.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 22/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

@IBDesignable
class RCStick: UIView {

    private var refX: CGFloat = 0, refY: CGFloat = 0
    var horizontalValue = 0.0
    var verticalValue = 0.0
    private var verticalOrigin = 0.0
    
    @IBInspectable
    var verticalSpring: Bool = true {
        didSet {
            if verticalSpring {
                verticalValue = 0.0
            } else {
                verticalValue = -1.0
            }
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var centerRadius: CGFloat = 20 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat = 5 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if gestureRecognizers?.isEmpty ?? true {
            let panRecognizer = UIPanGestureRecognizer(target: self, action: "panAction:")
            panRecognizer.minimumNumberOfTouches = 1
            panRecognizer.maximumNumberOfTouches = 1
            addGestureRecognizer(panRecognizer)
        }
    }
    
    override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        let borderRect = bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
        let radius = centerRadius - borderWidth / 2
        CGContextMoveToPoint(ctx, borderRect.minX + radius, borderRect.minY)
        CGContextAddLineToPoint(ctx, borderRect.maxX - radius, borderRect.minY)
        CGContextAddArcToPoint(ctx, borderRect.maxX, borderRect.minY, borderRect.maxX, borderRect.minY + radius, radius)
        CGContextAddLineToPoint(ctx, borderRect.maxX, borderRect.maxY - radius)
        CGContextAddArcToPoint(ctx, borderRect.maxX, borderRect.maxY, borderRect.maxX - radius, borderRect.maxY, radius)
        CGContextAddLineToPoint(ctx, borderRect.minX + radius, borderRect.maxY)
        CGContextAddArcToPoint(ctx, borderRect.minX, borderRect.maxY, borderRect.minX, borderRect.maxY - radius, radius)
        CGContextAddLineToPoint(ctx, borderRect.minX, borderRect.minY + radius)
        CGContextAddArcToPoint(ctx, borderRect.minX, borderRect.minY, borderRect.minX + radius, borderRect.minY, radius)
        
        CGContextSetStrokeColorWithColor(ctx, tintColor.CGColor)
        CGContextSetLineWidth(ctx, borderWidth)
        CGContextStrokePath(ctx)
        
        CGContextSetFillColorWithColor(ctx, tintColor.CGColor)
        CGContextFillEllipseInRect(ctx, CGRect(x: bounds.midX - centerRadius, y: bounds.midY - centerRadius, width: centerRadius * 2, height: centerRadius * 2).offsetBy(dx: CGFloat(horizontalValue) * (bounds.width / 2 - centerRadius), dy: CGFloat(-verticalValue) * (bounds.height / 2 - centerRadius)))
    }
    
    func panAction(sender: UIPanGestureRecognizer) {
        let point = sender.translationInView(self)
        if sender.state == .Began {
            refX = point.x
            refY = point.y
            horizontalValue = 0
            if verticalSpring {
                verticalValue = 0
            } else {
                verticalOrigin = verticalValue
            }
        } else if sender.state == .Changed {
            horizontalValue = constrain(Double((point.x - refX) / (bounds.width / 2 - centerRadius)), min: -1, max: 1)
            verticalValue = constrain(verticalOrigin - Double((point.y - refY) / (bounds.height / 2 - centerRadius)), min: -1, max: 1)
            setNeedsDisplay()
        } else {
            horizontalValue = 0
            if verticalSpring {
                verticalValue = 0
            }
            setNeedsDisplay()
        }
    }

}
