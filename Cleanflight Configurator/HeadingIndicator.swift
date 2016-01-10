//
//  HeadingIndicator.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 10/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

@IBDesignable
class HeadingIndicator: UIView {

    var heading = 0.0 {
        willSet(value) {
            if value != heading {
                setNeedsDisplay()
            }
        }
    }

    var fi_circle: UIImage?
    var heading_yaw: UIImage?
    var heading_mechanics: UIImage?

    private func loadImages() {
        let bundle = NSBundle(forClass: self.dynamicType)
        fi_circle = UIImage(named: "fi_circle", inBundle: bundle, compatibleWithTraitCollection: self.traitCollection)
        heading_yaw = UIImage(named: "heading_yaw", inBundle: bundle, compatibleWithTraitCollection: self.traitCollection)
        heading_mechanics = UIImage(named: "heading_mechanics", inBundle: bundle, compatibleWithTraitCollection: self.traitCollection)
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
        CGContextRotateCTM(context, CGFloat(-heading * M_PI / 180.0))
        
        let newRect = CGRect(x: -rect.width / 2, y: -rect.height / 2, width: rect.width, height: rect.height)
        heading_yaw?.drawInRect(newRect)
        
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()
        rotatedImage.drawInRect(rect)
        
        heading_mechanics?.drawInRect(rect)
        fi_circle?.drawInRect(rect)
    }

}
