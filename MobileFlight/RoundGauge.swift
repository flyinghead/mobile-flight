//
//  RoundGauge.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 21/01/16.
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
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!

        let squareBounds: CGRect
        if bounds.width > bounds.height {
            squareBounds = bounds.insetBy(dx: (bounds.width - bounds.height) / 2, dy: 0)
        } else {
            squareBounds = bounds.insetBy(dx: 0, dy: (bounds.height - bounds.width) / 2)
        }
        
        let minAngle = 2 * Double.pi / 3
        let maxAngle = 2 * Double.pi
        ctx.addArc(center: CGPoint(x: squareBounds.midX, y: squareBounds.midY), radius: squareBounds.height / 2 - 1, startAngle: CGFloat(minAngle), endAngle: CGFloat(maxAngle), clockwise: false)
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(2)
        ctx.strokePath()
        
        for (rangeMin, rangeMax, color) in ranges {
            ctx.addArc(center: CGPoint(x: squareBounds.midX, y: squareBounds.midY), radius: squareBounds.height / 2 - 2.5, startAngle: CGFloat(minAngle + (rangeMin - minimum) * (maxAngle - minAngle) / (maximum - minimum)), endAngle: CGFloat(minAngle + (rangeMax - minimum) * (maxAngle - minAngle) / (maximum - minimum)), clockwise: false)
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(5)
            ctx.strokePath()
        }
        
        ctx.translateBy(x: squareBounds.midX, y: squareBounds.midY)
        ctx.rotate(by: CGFloat(minAngle + (constrain(value, min: minimum, max: maximum) - minimum) * (maxAngle - minAngle) / (maximum - minimum) + .pi / 2))
        let radius: CGFloat = squareBounds.height / 20
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2).offsetBy(dx: -radius, dy: -radius))
        
        let dy = radius * radius / 2 / squareBounds.height / 2
        let dx = sqrt(radius * radius - dy * dy)
        
        ctx.move(to: CGPoint(x: 0, y: -squareBounds.height / 2))
        ctx.addLine(to: CGPoint(x: -dx, y: -dy))
        ctx.addLine(to: CGPoint(x: dx, y: -dy))
        ctx.closePath()
        ctx.fillPath()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        value = minimum + (maximum - minimum) * 0.5
        ranges.removeAll()
        ranges.append((min: minimum, max: minimum + (maximum - minimum) * 0.6, color: UIColor.green))
        ranges.append((min: minimum + (maximum - minimum) * 0.6, max: minimum + (maximum - minimum) * 0.8, color: UIColor.yellow))
        ranges.append((min: minimum + (maximum - minimum) * 0.8, max: maximum, color: UIColor.red))
    }
}
