//
//  TurnRateIndicator.swift
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
class TurnRateIndicator: UIView {

    var value: Double = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var scale: Double =  0.5 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var color: UIColor =  UIColor.magenta {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rectxxx: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        
        ctx.setFillColor(color.cgColor)
        if value < 0 {
            ctx.fill(CGRect(x: bounds.midX + CGFloat(value * scale), y: bounds.minY, width: -CGFloat(value * scale), height: bounds.height))
        } else {
            ctx.fill(CGRect(x: bounds.midX, y: bounds.minY, width: CGFloat(value * scale), height: bounds.height))
        }
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(CGRect(x: bounds.midX - 0.5, y: bounds.minY + 1, width: 1, height: bounds.height - 2))
    }

}
