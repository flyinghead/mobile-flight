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

    fileprivate var refX: CGFloat = 0, refY: CGFloat = 0
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

    fileprivate var verticalOrigin = 0.0
    
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
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        let borderRect = bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
        let radius = centerRadius - borderWidth / 2
        ctx.move(to: CGPoint(x: borderRect.minX + radius, y: borderRect.minY))
        ctx.addLine(to: CGPoint(x: borderRect.maxX - radius, y: borderRect.minY))
        ctx.addArc(tangent1End: CGPoint(x: borderRect.maxX, y: borderRect.minY), tangent2End: CGPoint(x: borderRect.maxX, y: borderRect.minY + radius), radius: radius)
        ctx.addLine(to: CGPoint(x: borderRect.maxX, y: borderRect.maxY - radius))
        ctx.addArc(tangent1End: CGPoint(x: borderRect.maxX, y: borderRect.maxY), tangent2End: CGPoint(x: borderRect.maxX - radius, y: borderRect.maxY), radius: radius)
        ctx.addLine(to: CGPoint(x: borderRect.minX + radius, y: borderRect.maxY))
        ctx.addArc(tangent1End: CGPoint(x: borderRect.minX, y: borderRect.maxY), tangent2End: CGPoint(x: borderRect.minX, y: borderRect.maxY - radius), radius: radius)
        ctx.addLine(to: CGPoint(x: borderRect.minX, y: borderRect.minY + radius))
        ctx.addArc(tangent1End: CGPoint(x: borderRect.minX, y: borderRect.minY), tangent2End: CGPoint(x: borderRect.minX + radius, y: borderRect.minY), radius: radius)
        
        ctx.setStrokeColor(tintColor.cgColor)
        ctx.setLineWidth(borderWidth)
        ctx.strokePath()
        
        ctx.setFillColor(tintColor.cgColor)
        ctx.fillEllipse(in: CGRect(x: bounds.midX - centerRadius, y: bounds.midY - centerRadius, width: centerRadius * 2, height: centerRadius * 2).offsetBy(dx: CGFloat(horizontalValue) * (bounds.width / 2 - centerRadius), dy: CGFloat(-verticalValue) * (bounds.height / 2 - centerRadius)))
    }
    
    func panAction(_ sender: UIPanGestureRecognizer) {
        let point = sender.translation(in: self)
        if sender.state == .began {
            refX = point.x
            refY = point.y
            horizontalValue = 0
            if verticalSpring {
                verticalValue = 0
            } else {
                verticalOrigin = verticalValue
            }
        } else if sender.state == .changed {
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
