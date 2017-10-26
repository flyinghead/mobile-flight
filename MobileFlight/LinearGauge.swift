//
//  LinearGauge.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 11/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
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
class LinearGauge: UIView {
    fileprivate var _value = 0.0
    fileprivate var _minimumValue = 0.0
    fileprivate var _maximumValue = 1.0
    fileprivate var _color = UIColor.green

    @IBInspectable var value: Double {
        get {
            return _value
        }
        set(value) {
            if value != _value {
                setNeedsDisplay()
            }
            _value = value
        }
    }
    @IBInspectable var minimumValue: Double {
        get {
            return _minimumValue
        }
        set(value) {
            if value != _minimumValue {
                setNeedsDisplay()
            }
            _minimumValue = value
        }
    }
    @IBInspectable var maximumValue: Double {
        get {
            return _maximumValue
        }
        set(value) {
            if value != _maximumValue {
                setNeedsDisplay()
            }
            _maximumValue = value
        }
    }
    @IBInspectable var color: UIColor {
        get {
            return _color
        }
        set(value) {
            if value != _color {
                setNeedsDisplay()
            }
            _color = value
        }
    }
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set(value) {
            layer.cornerRadius = value
        }
    }
    @IBInspectable var printValue: Bool = false

    convenience init() {
        self.init(frame:CGRect(x: 0, y: 0, width: 0, height: 0))
        clipsToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
        clipsToBounds = true
    }
    
    override func draw(_ rect: CGRect) {
        _color.setFill()
        
        let normalizedValue = (min(max(_value, _minimumValue), _maximumValue) - _minimumValue) / abs(_maximumValue - _minimumValue)

        UIRectFill(CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width * CGFloat(normalizedValue), height: rect.height))
        if printValue {
            // FIXME Set font name and size externally. Find a way to have text always visible regardless of fore/background color
            let label = NSString(format: "%.0f", value)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = NSTextAlignment.center
            
            let font = UIFont(name: "Helvetica Neue", size: 14)
            let textRect = CGRect(x: rect.origin.x, y: rect.origin.y + rect.height / 2 - font!.pointSize / 2, width: rect.width, height: font!.pointSize)
            
            label.draw(in: textRect, withAttributes: [NSParagraphStyleAttributeName : paragraphStyle, NSFontAttributeName : font!])
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return size
    }
}
