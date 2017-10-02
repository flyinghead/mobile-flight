//
//  RCStick.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 22/01/16.
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
class RCStick: UIView {

    private var refX: CGFloat = 0, refY: CGFloat = 0
    var horizontalValue = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    var verticalValue = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }

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
            let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(RCStick.panAction(_:)))
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
