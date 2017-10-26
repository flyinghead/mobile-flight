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
import QuartzCore

@IBDesignable
class RangeSlider: UIControl {
    let trackLayer = RangeSliderTrackLayer()
    let lowerThumbLayer = RangeSliderThumbLayer()
    let upperThumbLayer = RangeSliderThumbLayer()
    var previousLocation = CGPoint()
    let referenceThumbLayer = RangeSliderReferenceThumbLayer()

    @IBInspectable
    var minimumValue: Double = 0.0 {
        didSet {
            updateLayerFrames()
        }
    }

    @IBInspectable
    var maximumValue: Double = 1.0 {
        didSet {
            updateLayerFrames()
        }
    }

    @IBInspectable
    var lowerValue: Double = 0.2 {
        didSet {
            updateLayerFrames()
        }
    }

    @IBInspectable
    var upperValue: Double = 0.8 {
        didSet {
            updateLayerFrames()
        }
    }

    @IBInspectable
    var trackTintColor: UIColor = UIColor(white: 0.9, alpha: 1.0) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }

    @IBInspectable
    var trackHighlightTintColor: UIColor = UIColor(red: 0.0, green: 0.45, blue: 0.94, alpha: 1.0) {
        didSet {
            trackLayer.setNeedsDisplay()
            referenceThumbLayer.setNeedsDisplay()
        }
    }

    @IBInspectable
    var thumbTintColor: UIColor = UIColor.white {
        didSet {
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
        }
    }

    @IBInspectable
    var curvaceousness: CGFloat = 1.0 {
        didSet {
            trackLayer.setNeedsDisplay()
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
            referenceThumbLayer.setNeedsDisplay()
        }
    }

    @IBInspectable
    var interval: Double = 0.0 {
        didSet {
            updateLayerFrames()
        }
    }
    
    @IBInspectable
    var referenceValue: Double = 0.5 {
        didSet {
            updateLayerFrames()
        }
    }
    
    var thumbWidth: CGFloat {
        return CGFloat(bounds.height)
    }

    override var frame: CGRect {
        didSet {
            updateLayerFrames()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        trackLayer.rangeSlider = self
        trackLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(trackLayer)

        referenceThumbLayer.rangeSlider = self
        referenceThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(referenceThumbLayer)
        
        lowerThumbLayer.rangeSlider = self
        lowerThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(lowerThumbLayer)

        upperThumbLayer.rangeSlider = self
        upperThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(upperThumbLayer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        trackLayer.rangeSlider = self
        trackLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(trackLayer)
        
        referenceThumbLayer.rangeSlider = self
        referenceThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(referenceThumbLayer)
        
        lowerThumbLayer.rangeSlider = self
        lowerThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(lowerThumbLayer)
        
        upperThumbLayer.rangeSlider = self
        upperThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(upperThumbLayer)
    }

    func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        trackLayer.frame = bounds.insetBy(dx: 0.0, dy: bounds.height / 3)
        trackLayer.setNeedsDisplay()

        let lowerThumbCenter = positionForValue(lowerValue)

        lowerThumbLayer.frame = CGRect(x: lowerThumbCenter - thumbWidth / 2.0, y: 0.0, width: thumbWidth, height: thumbWidth)
        lowerThumbLayer.setNeedsDisplay()

        let upperThumbCenter = positionForValue(upperValue)
        upperThumbLayer.frame = CGRect(x: upperThumbCenter - thumbWidth / 2.0, y: 0.0,
            width: thumbWidth, height: thumbWidth)
        upperThumbLayer.setNeedsDisplay()

        let refThumbCenter = positionForValue(referenceValue)
        referenceThumbLayer.frame = CGRect(x: refThumbCenter - thumbWidth / 2.0, y: 0.0, width: thumbWidth, height: thumbWidth)
        referenceThumbLayer.setNeedsDisplay()
        
        CATransaction.commit()
    }

    func positionForValue(_ value: Double) -> CGFloat {
        return CGFloat(Double(bounds.width - thumbWidth) * (value - minimumValue) /
            (maximumValue - minimumValue) + Double(thumbWidth / 2.0))
    }

    // Touch handlers
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previousLocation = touch.location(in: self)

        // Hit test the thumb layers
        if lowerThumbLayer.frame.contains(previousLocation) {
            lowerThumbLayer.highlighted = true
        } else if upperThumbLayer.frame.contains(previousLocation) {
            upperThumbLayer.highlighted = true
        }

        return lowerThumbLayer.highlighted || upperThumbLayer.highlighted
    }

    func boundValue(_ value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double {
        var boundValue = min(max(value, lowerValue), upperValue)
        if interval != 0 && boundValue != maximumValue {
            let lowerMark = Double(Int64((boundValue - minimumValue) / interval)) * interval + minimumValue
            if boundValue - lowerMark >= interval / 2 {
                boundValue = lowerMark + interval
            } else {
                boundValue = lowerMark
            }
        }
        return boundValue
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)

        // 1. Determine by how much the user has dragged
        let deltaLocation = Double(location.x - previousLocation.x)
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - bounds.height)

        // 2. Update the values
        if lowerThumbLayer.highlighted {
            lowerValue += deltaValue
            lowerValue = boundValue(lowerValue, toLowerValue: minimumValue, upperValue: upperValue)
            previousLocation = CGPoint(x: positionForValue(lowerValue), y: location.y)
        } else if upperThumbLayer.highlighted {
            upperValue += deltaValue
            upperValue = boundValue(upperValue, toLowerValue: lowerValue, upperValue: maximumValue)
            previousLocation = CGPoint(x: positionForValue(upperValue), y: location.y)
        } else {
            previousLocation = location
        }
        sendActions(for: .valueChanged)

        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        lowerThumbLayer.highlighted = false
        upperThumbLayer.highlighted = false
    }
}
