//
//  AttitudeIndicator2.swift
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
    
    @IBInspectable var groundColor: UIColor =  UIColor.brown {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        
        ctx.clip(to: rect)
        
        let horizonY = self.horizonY * Double(bounds.height) + Double(bounds.minY)
        let roll = self.roll * .pi / 180

        let topRollMarkHeight = 15 * CGFloat(sin(.pi / 2.7))
        
        var indicatorWidth = min(bounds.midX - bounds.minX - layoutMargins.left, bounds.maxX - layoutMargins.right - bounds.midX)
        indicatorWidth = min(indicatorWidth, CGFloat(horizonY) - bounds.minY - layoutMargins.top - topRollMarkHeight)
        indicatorWidth = min(indicatorWidth, bounds.maxY - layoutMargins.bottom - bounds.midY) * 2

        let pitchScale = Double(indicatorWidth) / 100.0 as Double         // pixels per degree
        
        ctx.translateBy(x: bounds.midX, y: CGFloat(horizonY - pitch * pitchScale))
        ctx.rotate(by: CGFloat(-roll))
        
        // Sky
        ctx.setFillColor(skyColor.cgColor)
        ctx.fill(CGRect(x: -bounds.width * 1.5, y: -bounds.height * 1.5, width: bounds.width * 3, height: bounds.height * 1.5))
        
        // Ground
        ctx.setFillColor(groundColor.cgColor)
        ctx.fill(CGRect(x: -bounds.width * 1.5, y: 0, width: bounds.width * 3, height: bounds.height * 1.5))
        
        // Horizon
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(CGRect(x: -bounds.width * 1.5, y: -0.5, width: bounds.width * 3, height: 1))
        
        // Pitch angle scale
        ctx.setStrokeColor(UIColor.white.cgColor)
        let scaleFont = UIFont(name: "Verdana", size: fontSize)!
        let attributes: [String : Any]? = [ NSFontAttributeName : scaleFont, NSForegroundColorAttributeName : UIColor.white]
        for pitch in [-20, -10, 10, 20] {
            let y = CGFloat(Double(pitch) * pitchScale)
            ctx.move(to: CGPoint(x: -20, y: y))
            ctx.addLine(to: CGPoint(x: 20, y: y))
            
            let legend = String(format: "%d", abs(pitch)) as NSString
            let legendSize = legend.size(attributes: attributes)
            legend.draw(in: CGRect(origin: CGPoint(x: -24 - legendSize.width, y: y - legendSize.height / 2), size: legendSize), withAttributes: attributes)
            legend.draw(in: CGRect(origin: CGPoint(x: 24, y: y - legendSize.height / 2), size: legendSize), withAttributes: attributes)
        }
        for pitch in [-25, -15, -5, 5, 15, 25] {
            let y = CGFloat(Double(pitch) * pitchScale)
            ctx.move(to: CGPoint(x: -10, y: y))
            ctx.addLine(to: CGPoint(x: 10, y: y))
        }
        ctx.strokePath()
        
        // Roll angle scale
        ctx.rotate(by: CGFloat(roll))
        ctx.translateBy(x: 0, y: CGFloat(pitch * pitchScale))
        ctx.rotate(by: CGFloat(-roll))
        
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.addArc(center: CGPoint(x: 0, y: indicatorWidth / 2), radius: 0, startAngle: CGFloat(-5 * .pi / 6.0), endAngle: CGFloat(-.pi / 6.0), clockwise: false)
        
        for a in [-5.0, -4.0, -2.0, -1.0] {
            ctx.move(to: CGPoint(x: CGFloat(cos(a * .pi / 6.0)) * (indicatorWidth / 2), y: CGFloat(sin(a * .pi / 6.0)) * (indicatorWidth / 2)))
            ctx.addLine(to: CGPoint(x: ctx.currentPointOfPath.x + CGFloat(cos(a * .pi / 6.0)) * 10, y: ctx.currentPointOfPath.y + CGFloat(sin(a * .pi / 6.0)) * 10))
        }
        for a in [-4.5, -3.6666, -3.3333, -2.6666, -2.3333, -1.5] {
            ctx.move(to: CGPoint(x: CGFloat(cos(a * .pi / 6.0)) * (indicatorWidth / 2), y: CGFloat(sin(a * .pi / 6.0)) * (indicatorWidth / 2)))
            ctx.addLine(to: CGPoint(x: ctx.currentPointOfPath.x + CGFloat(cos(a * .pi / 6.0)) * 6, y: ctx.currentPointOfPath.y + CGFloat(sin(a * .pi / 6.0)) * 6))
        }
        ctx.move(to: CGPoint(x: 0, y: -indicatorWidth / 2))
        
        let topRollMarkHalfWidth = 15 * CGFloat(cos(.pi / 2.7))
        ctx.addLine(to: CGPoint(x: ctx.currentPointOfPath.x + topRollMarkHalfWidth, y: ctx.currentPointOfPath.y - topRollMarkHeight))
        ctx.addLine(to: CGPoint(x: ctx.currentPointOfPath.x - topRollMarkHalfWidth * 2, y: ctx.currentPointOfPath.y))
        ctx.addLine(to: CGPoint(x: ctx.currentPointOfPath.x + topRollMarkHalfWidth, y: ctx.currentPointOfPath.y + topRollMarkHeight))
        
        ctx.strokePath()
        
        ctx.rotate(by: CGFloat(roll))
        ctx.translateBy(x: -bounds.midX, y: CGFloat(-horizonY))
        
        // Yellow roll reference
        let cornerRadius: CGFloat = 2

        ctx.setStrokeColor(UIColor.yellow.cgColor)
        ctx.setLineWidth(3)
        ctx.move(to: CGPoint(x: bounds.midX, y: CGFloat(horizonY - Double(indicatorWidth) / 2 + 3)))
        let dx = 15 * CGFloat(cos(.pi / 2.7))
        let dy = 15 * sin(.pi / 2.7)
        ctx.addLine(to: CGPoint(x: bounds.midX + dx, y: CGFloat(horizonY - Double(indicatorWidth) / 2 + 3 + dy)))
        ctx.addLine(to: CGPoint(x: bounds.midX - dx, y: CGFloat(horizonY - Double(indicatorWidth) / 2 + 3 + dy)))
        ctx.closePath()
        ctx.strokePath()
        
        // Yellow horizon reference
        ctx.setLineWidth(1)
        ctx.setFillColor(UIColor.yellow.cgColor)
        ctx.move(to: CGPoint(x: bounds.midX - indicatorWidth / 2 + cornerRadius, y: CGFloat(horizonY) - cornerRadius))
        ctx.addLine(to: CGPoint(x: bounds.midX - 30 - cornerRadius, y: CGFloat(horizonY) - cornerRadius))
        ctx.addArc(center: CGPoint(x: bounds.midX - 30 - cornerRadius, y: CGFloat(horizonY)), radius: cornerRadius, startAngle: CGFloat(-Float.pi / 2), endAngle: CGFloat(Float.pi / 2), clockwise: false)
        ctx.addLine(to: CGPoint(x: bounds.midX - indicatorWidth / 2 + cornerRadius, y: CGFloat(horizonY) + cornerRadius))
        ctx.addArc(center: CGPoint(x: bounds.midX - indicatorWidth / 2 + cornerRadius, y: CGFloat(horizonY)), radius: cornerRadius, startAngle: CGFloat(Float.pi / 2), endAngle: CGFloat(-Float.pi / 2), clockwise: false)
        ctx.fillPath()
        
        ctx.move(to: CGPoint(x: bounds.midX + indicatorWidth / 2 - cornerRadius, y: CGFloat(horizonY) - cornerRadius))
        ctx.addLine(to: CGPoint(x: bounds.midX + 30 + cornerRadius, y: CGFloat(horizonY) - cornerRadius))
        ctx.addArc(center: CGPoint(x: bounds.midX + 30 + cornerRadius, y: CGFloat(horizonY)), radius: cornerRadius, startAngle: CGFloat(-Float.pi / 2), endAngle: CGFloat(Float.pi / 2), clockwise: true)
        ctx.addLine(to: CGPoint(x: bounds.midX + indicatorWidth / 2 - cornerRadius, y: CGFloat(horizonY) + cornerRadius))
        ctx.addArc(center: CGPoint(x: bounds.midX + indicatorWidth / 2 - cornerRadius, y: CGFloat(horizonY)), radius: cornerRadius, startAngle: CGFloat(Float.pi / 2), endAngle: CGFloat(-Float.pi / 2), clockwise: true)
        ctx.fillPath()
        
        ctx.fillEllipse(in: CGRect(x: bounds.midX - cornerRadius, y: CGFloat(horizonY) - cornerRadius, width: cornerRadius * 2, height: cornerRadius * 2))
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
