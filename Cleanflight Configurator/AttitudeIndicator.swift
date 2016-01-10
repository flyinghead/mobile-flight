//
//  AttitudeIndicator.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 09/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import Darwin

@IBDesignable
class AttitudeIndicator: UIView {
    
    var pitch = 0.0 {
        willSet(value) {
            if value != pitch {
                setNeedsDisplay()
            }
        }
    }
    var roll = 0.0 {
        willSet(value) {
            if value != roll {
                setNeedsDisplay()
            }
        }
    }
    
    var fi_circle: UIImage?
    var horizon_back: UIImage?
    var horizon_ball: UIImage?
    var horizon_circle: UIImage?
    var horizon_mechanics: UIImage?

    private func loadImages() {
        let bundle = NSBundle(forClass: self.dynamicType)
        fi_circle = UIImage(named: "fi_circle", inBundle: bundle, compatibleWithTraitCollection: self.traitCollection)
        horizon_back = UIImage(named: "horizon_back", inBundle: bundle, compatibleWithTraitCollection: self.traitCollection)
        horizon_ball = UIImage(named: "horizon_ball", inBundle: bundle, compatibleWithTraitCollection: self.traitCollection)
        horizon_circle = UIImage(named: "horizon_circle", inBundle: bundle, compatibleWithTraitCollection: self.traitCollection)
        horizon_mechanics = UIImage(named: "horizon_mechanics", inBundle: bundle, compatibleWithTraitCollection: self.traitCollection)
    }
    override func drawRect(var rect: CGRect) {
        if fi_circle == nil {
            loadImages()
        }
        
        // Make rect square and center
        if rect.width > rect.height {
            rect.origin.x += (rect.width - rect.height) / 2
        } else if rect.width < rect.height {
            rect.origin.y += (rect.height - rect.width) / 2
        }
        //fi_box?.drawInRect(rect)
        
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        CGContextTranslateCTM(context, rect.width / 2, rect.height / 2)
        CGContextRotateCTM(context, CGFloat(-roll * M_PI / 180.0))
        
        let newRect = CGRect(x: -rect.width / 2, y: -rect.height / 2, width: rect.width, height: rect.height)
        horizon_back?.drawInRect(newRect)
        // Depends on the horizon_ball image. Currently, 20° pitch is at 55 units from the center, for a 400-unit total height
        horizon_ball?.drawInRect(CGRect(x: newRect.origin.x, y: newRect.origin.y + CGFloat(max(min(-pitch, 30), -30) * 55 / 20 / 400) * newRect.height, width: newRect.width, height: newRect.height))
        horizon_circle?.drawInRect(newRect)
        
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()
        rotatedImage.drawInRect(rect)
        
        horizon_mechanics?.drawInRect(rect)
        fi_circle?.drawInRect(rect)
    }
}
