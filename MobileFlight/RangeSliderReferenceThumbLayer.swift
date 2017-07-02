//
//  RangeSliderReferenceThumbLayer.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 14/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class RangeSliderReferenceThumbLayer: CALayer {
    weak var rangeSlider: RangeSlider?
    
    override func drawInContext(ctx: CGContext) {
        if let slider = rangeSlider {
            let thumbFrame = bounds.insetBy(dx: 3.0, dy: 3.0)
            let cornerRadius = thumbFrame.height * slider.curvaceousness / 2.0
            let thumbPath = UIBezierPath(roundedRect: thumbFrame, cornerRadius: cornerRadius)
            
            //let shadowColor = slider.trackTintColor.CGColor
            //CGContextSetShadowWithColor(ctx, CGSize(width: 0.0, height: 1.0), 1.0, shadowColor.CGColor)
            CGContextSetFillColorWithColor(ctx, slider.trackHighlightTintColor.CGColor)
            CGContextAddPath(ctx, thumbPath.CGPath)
            CGContextFillPath(ctx)
            
            // Outline
/*            CGContextSetStrokeColorWithColor(ctx, shadowColor.CGColor)
            CGContextSetLineWidth(ctx, 0.5)
            CGContextAddPath(ctx, thumbPath.CGPath)
            CGContextStrokePath(ctx)
            
            if highlighted {
                CGContextSetFillColorWithColor(ctx, UIColor(white: 0.0, alpha: 0.1).CGColor)
                CGContextAddPath(ctx, thumbPath.CGPath)
                CGContextFillPath(ctx)
            }
*/
        }
    }

}
