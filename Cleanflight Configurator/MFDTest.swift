//
//  MFDTest.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 15/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MFDTest: UIView, FlightDataListener {
    let lightFont = UIFont(name: "Verdana", size: 14)!
    let font = UIFont(name: "Verdana-Bold", size: 15)!
    
    //var timer: NSTimer?
    var registered = false
    var origin = 0.0
    var roll: Double = 0.0
    var pitch: Double = 0.0
    
    func receivedAltitudeData() {
        setNeedsDisplay()
    }
    
    func receivedGpsData() {
        setNeedsDisplay()
    }
    
    func receivedSensorData() {
        setNeedsDisplay()
    }

    override func drawRect(rect: CGRect) {
        if !registered {
            registered = true
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.msp.addDataListener(self)
        }
        //if timer == nil {
        //    timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        //}
//        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!

        
//        UIGraphicsPushContext(context)
        
        //let attributes: [String : AnyObject]? = [ NSFontAttributeName : UIFont(name: "Verdana-Bold", size: 12)!, NSForegroundColorAttributeName : UIColor.whiteColor()]
        //("340.7°" as NSString).drawAtPoint(CGPoint(x: rect.midX, y: rect.midY), withAttributes: attributes)
        
//        UIGraphicsPopContext()

//        UIGraphicsEndImageContext()
        //UIColor.whiteColor().set()

        //UIColor.darkGrayColor().setFill()
        //CGContextFillRect(context, rect)
        let sensorData = SensorData.theSensorData
        let gpsData = GPSData.theGPSData
        
        let (compassRect, remainderRect) = rect.divide(40, fromEdge: .MinYEdge)
        
        drawAttitudeIndicator(context, rect: rect, horizonY: rect.midY + compassRect.height / 2, pitch: sensorData.pitchAngle, roll: sensorData.rollAngle)
        
        let black = UIColor(white: 0, alpha: 0.5)
        
        black.setFill()
        CGContextFillRect(context, compassRect)
        
        drawCompassScale(context, rect: compassRect, scale: 2, midPoint: sensorData.heading, mainTicksInterval: 30, subTicksInterval: 10)
        
        let triRect = compassRect.divide(8, fromEdge: .MinYEdge).slice.offsetBy(dx: 0, dy: 3)
        drawTurnRateIndicator(context, rect: triRect, value: sensorData.turnRate, scale: 0.5)
        
        var (speedRect, rightRect) = remainderRect.divide(55, fromEdge: .MinXEdge)
        
        speedRect.insetInPlace(dx: 0.5, dy: 0.5)
        black.setFill()
        CGContextFillRect(context, speedRect)
        CGContextSetStrokeColorWithColor(context, UIColor.lightGrayColor().CGColor)
        CGContextStrokeRect(context, speedRect)
        
        speedRect.insetInPlace(dx: 0.5, dy: 0.5)
        drawVerticalScale(context, rect: speedRect, rightAligned: true, scale: 50, midPoint: gpsData.speed, mainTicksInterval: 1, subTicksInterval: 0.5, subSubTicksInterval: 0)
        //drawVerticalScaleMarker(context, rect: speedRect, rightAligned: true, scale: 100, midPoint: origin, value: 10, color: UIColor.cyanColor())
        
        drawRollingDigitCounter(context, rect: CGRect(x: speedRect.minX + 1, y: speedRect.midY - 15, width: speedRect.width - 5, height: 30), value: gpsData.speed, precision: 0, leftMark: false)
        
        var altiRect = rightRect.divide(55, fromEdge: .MaxXEdge).slice
        
        altiRect.insetInPlace(dx: 0.5, dy: 0.5)
        CGContextFillRect(context, altiRect)
        CGContextSetStrokeColorWithColor(context, UIColor.lightGrayColor().CGColor)
        CGContextStrokeRect(context, altiRect)
        
        altiRect.insetInPlace(dx: 0.5, dy: 0.5)
        drawVerticalScale(context, rect: altiRect, rightAligned: false, scale: 40, midPoint: sensorData.altitude, mainTicksInterval: 1, subTicksInterval: 0.5, subSubTicksInterval: 0)
        //drawVerticalScaleMarker(context, rect: altiRect, rightAligned: false, scale: 100, midPoint: origin, value: 10, color: UIColor.cyanColor())
        
        drawRollingDigitCounter(context, rect: CGRect(x: altiRect.minX + 4, y: altiRect.midY - 15, width: altiRect.width - 5, height: 30), value: sensorData.altitude, precision: 0, leftMark: true)
    }
    
    private func drawVerticalScale(context: CGContext, rect: CGRect, rightAligned: Bool, scale: Double, midPoint: Double, mainTicksInterval: Double, subTicksInterval: Double, subSubTicksInterval: Double) {
        CGContextSaveGState(context)
        CGContextClipToRect(context, rect)
        
        var top = Double(rect.height) / 2.0 / scale + midPoint

        if subSubTicksInterval != 0 {
            top = ceil(top / subSubTicksInterval) * subSubTicksInterval
        } else if subTicksInterval != 0 {
            top = ceil(top / subTicksInterval) * subTicksInterval
        } else {
            top = ceil(top / mainTicksInterval) * mainTicksInterval
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = rightAligned ? .Right : .Left

        let textAttributes: [String : AnyObject]? = [ NSFontAttributeName : lightFont, NSForegroundColorAttributeName : UIColor.whiteColor(), NSParagraphStyleAttributeName : paragraphStyle]
        let fontSize = ("0" as NSString).sizeWithAttributes(textAttributes)
        
        // Vertical axis line. This should be done elsewhere
        //CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
        //CGContextFillRect(context, CGRect(x: rect.minX, y: rect.minY, width: 2, height: rect.height))
        
        while true {
            let y = CGFloat(Double(rect.height) / 2.0 - (top - midPoint) * scale) + rect.minY
            let graduationTextTop = y - fontSize.height / 2 - 0.5
            if graduationTextTop > rect.maxY {
                break
            }
            var width: CGFloat
            var length: CGFloat
            if top == round(top / mainTicksInterval) * mainTicksInterval {
                width = 2
                length = fontSize.width
                
                let string = String(format:"%.0f", top)             // FIXME how many decimals??
                string.drawInRect(CGRect(x: rightAligned ? rect.minX : rect.minX + fontSize.width * 1.5, y: graduationTextTop, width: rect.width - fontSize.width * 1.5, height: fontSize.height), withAttributes: textAttributes)
            } else if subTicksInterval != 0 && top == round(top / subTicksInterval) * subTicksInterval {
                width = 2
                length = fontSize.width * 0.75
            } else {
                width = 1
                length = fontSize.width * 0.5
            }
            
            CGContextFillRect(context, CGRect(x: rightAligned ? rect.maxX - length : rect.minX, y: y - width / 2, width: length, height: width))
            
            if subSubTicksInterval != 0 {
                let next = (top - subSubTicksInterval) / subSubTicksInterval
                top = round(next) * subSubTicksInterval
            } else if subTicksInterval != 0 {
                top = round((top - subTicksInterval) / subTicksInterval) * subTicksInterval
            } else {
                top = round((top - mainTicksInterval) / mainTicksInterval) * mainTicksInterval
            }
        }
        
        CGContextRestoreGState(context)
    }
    
    // Bottom aligned
    private func drawCompassScale(context: CGContext, rect: CGRect, scale: Double, midPoint: Double, mainTicksInterval: Double, subTicksInterval: Double) {
        CGContextSaveGState(context)
        CGContextClipToRect(context, rect)
        
        var left = Double(rect.width) / 2.0 / scale + midPoint
        
        if subTicksInterval != 0 {
            left = ceil(left / subTicksInterval) * subTicksInterval
        } else {
            left = ceil(left / mainTicksInterval) * mainTicksInterval
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Center
        
        let textAttributes: [String : AnyObject]? = [ NSFontAttributeName : lightFont, NSForegroundColorAttributeName : UIColor.whiteColor(), NSParagraphStyleAttributeName : paragraphStyle]
        let fontSize = ("0" as NSString).sizeWithAttributes(textAttributes)
        
        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
        
        while true {
            let x = CGFloat(Double(rect.width) / 2.0 - (left - midPoint) * scale) + rect.minX

            var width: CGFloat
            var length: CGFloat
            if left == round(left / mainTicksInterval) * mainTicksInterval {
                width = 2
                length = fontSize.width

                var degrees = round(left) % 360
                if degrees < 0 {
                    degrees += 360
                }
                let string: String
                switch degrees {
                case 0:
                    string = "N"
                case 90:
                    string = "E"
                case 180:
                    string = "S"
                case 270:
                    string = "W"
                default:
                    string = String(format:"%.0f", degrees)
                }
                let textSize = (string as NSString).sizeWithAttributes(textAttributes)
                if x - textSize.width/2 > rect.maxX {
                    break
                }
                string.drawInRect(CGRect(x: x - textSize.width/2, y: rect.maxY - fontSize.width  - fontSize.height, width: textSize.width, height: textSize.height), withAttributes: textAttributes)
            } else {
                width = 2
                length = fontSize.width * 0.75
            }
            
            if x > rect.maxX {
                break
            }
            CGContextFillRect(context, CGRect(x: x, y: rect.maxY - length, width: width, height: length))
            
            if subTicksInterval != 0 {
                left = round((left - subTicksInterval) / subTicksInterval) * subTicksInterval
            } else {
                left = round((left - mainTicksInterval) / mainTicksInterval) * mainTicksInterval
            }
        }
        
        CGContextMoveToPoint(context, rect.midX, rect.maxY - fontSize.width)
        CGContextAddLineToPoint(context, rect.midX - fontSize.width / 2 / CGFloat(sin(M_PI / 3)), rect.maxY)
        CGContextAddLineToPoint(context, rect.midX + fontSize.width / 2 / CGFloat(sin(M_PI / 3)), rect.maxY)
        CGContextClosePath(context)
        CGContextFillPath(context)
        
        CGContextRestoreGState(context)
    }
    
    private func drawTurnRateIndicator(ctx: CGContext, rect: CGRect, value: Double, scale: Double) {
        CGContextSetFillColorWithColor(ctx, UIColor.magentaColor().CGColor)
        if value < 0 {
            CGContextFillRect(ctx, CGRect(x: rect.midX + CGFloat(value * scale), y: rect.minY, width: -CGFloat(value * scale), height: rect.height))
        } else {
            CGContextFillRect(ctx, CGRect(x: rect.midX, y: rect.minY, width: CGFloat(value * scale), height: rect.height))
        }
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextFillRect(ctx, CGRect(x: rect.midX - 0.5, y: rect.minY + 1, width: 1, height: rect.height - 2))
    }
    
    private func drawRollingDigitCounter(ctx: CGContext, rect: CGRect, value: Double, precision precisionTen: Int, leftMark: Bool) {
        CGContextSaveGState(ctx)

        let precision = pow(10.0, Double(precisionTen))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Right
        let textAttributes: [String : AnyObject]? = [ NSFontAttributeName : font, NSForegroundColorAttributeName : UIColor.whiteColor(), NSParagraphStyleAttributeName : paragraphStyle]
        let fontSize = ("0" as NSString).sizeWithAttributes(textAttributes)
        
        let cornerRadius: CGFloat = fontSize.width / 3
        let markWidth = fontSize.height / 2 * 0.8660        // sin(60°)
        
        let minX = leftMark ? rect.minX + markWidth : rect.minX
        let maxX = leftMark ? rect.maxX : rect.maxX - markWidth
        
        let rollerWidth = fontSize.width * CGFloat(precisionTen + 1) + 8
        
        let path = CGPathCreateMutable()
        
/*
        CGPathMoveToPoint(path, nil, minX + cornerRadius, rect.minY)
        // Top
        CGPathAddLineToPoint(path, nil, maxX - cornerRadius, rect.minY)
        CGPathAddArcToPoint(path, nil, maxX, rect.minY, maxX, rect.minY + cornerRadius, cornerRadius)
        // Right
        if !leftMark {
            CGPathAddLineToPoint(path, nil, maxX, rect.midY - fontSize.height / 4)
            CGPathAddLineToPoint(path, nil, rect.maxX, rect.midY)
            CGPathAddLineToPoint(path, nil, maxX, rect.midY + fontSize.height / 4)
        }
        CGPathAddLineToPoint(path, nil, maxX, rect.maxY - cornerRadius)
        CGPathAddArcToPoint(path, nil, maxX, rect.maxY, maxX - cornerRadius, rect.maxY, cornerRadius)
        // Bottom
        CGPathAddLineToPoint(path, nil, minX + cornerRadius, rect.maxY)
        CGPathAddArcToPoint(path, nil, minX, rect.maxY, minX, rect.maxY - cornerRadius, cornerRadius)
        // Left
        if leftMark {
            CGPathAddLineToPoint(path, nil, minX, rect.midY + fontSize.height / 4)
            CGPathAddLineToPoint(path, nil, rect.minX, rect.midY)
            CGPathAddLineToPoint(path, nil, minX, rect.midY - fontSize.height / 4)
        }
        CGPathAddLineToPoint(path, nil, minX, rect.minY + cornerRadius)
        CGPathAddArcToPoint(path, nil, minX, rect.minY, minX + cornerRadius, rect.minY, cornerRadius)
*/
        let commonHalfHeight = fontSize.height / 2
        CGPathMoveToPoint(path, nil, minX + cornerRadius, rect.midY - commonHalfHeight)
        // Top
        CGPathAddLineToPoint(path, nil, maxX - rollerWidth, rect.midY - commonHalfHeight)
        CGPathAddLineToPoint(path, nil, maxX - rollerWidth, rect.minY + cornerRadius)
        CGPathAddArcToPoint(path, nil, maxX - rollerWidth, rect.minY, maxX - rollerWidth + cornerRadius, rect.minY, cornerRadius)
        CGPathAddLineToPoint(path, nil, maxX - cornerRadius, rect.minY)
        CGPathAddArcToPoint(path, nil, maxX, rect.minY, maxX, rect.minY + cornerRadius, cornerRadius)
        // Right
        if !leftMark {
            CGPathAddLineToPoint(path, nil, maxX, rect.midY - commonHalfHeight / 2)
            CGPathAddLineToPoint(path, nil, rect.maxX, rect.midY)
            CGPathAddLineToPoint(path, nil, maxX, rect.midY + commonHalfHeight / 2)
        }
        CGPathAddLineToPoint(path, nil, maxX, rect.maxY - cornerRadius)
        CGPathAddArcToPoint(path, nil, maxX, rect.maxY, maxX - cornerRadius, rect.maxY, cornerRadius)
        // Bottom
        CGPathAddLineToPoint(path, nil, maxX - rollerWidth + cornerRadius, rect.maxY)
        CGPathAddArcToPoint(path, nil, maxX - rollerWidth, rect.maxY, maxX - rollerWidth, rect.maxY - cornerRadius, cornerRadius)
        CGPathAddLineToPoint(path, nil, maxX - rollerWidth, rect.midY + commonHalfHeight)
        CGPathAddLineToPoint(path, nil, minX + cornerRadius, rect.midY + commonHalfHeight)
        CGPathAddArcToPoint(path, nil, minX, rect.midY + commonHalfHeight, minX, rect.midY + commonHalfHeight - cornerRadius, cornerRadius)
        // Left
        if leftMark {
            CGPathAddLineToPoint(path, nil, minX, rect.midY + commonHalfHeight / 2)
            CGPathAddLineToPoint(path, nil, rect.minX, rect.midY)
            CGPathAddLineToPoint(path, nil, minX, rect.midY - commonHalfHeight / 2)
        }
        CGPathAddLineToPoint(path, nil, minX, rect.midY - commonHalfHeight + cornerRadius)
        CGPathAddArcToPoint(path, nil, minX, rect.midY - commonHalfHeight, minX + cornerRadius, rect.midY - commonHalfHeight, cornerRadius)
    
        // Draw fill and stroke
        CGContextAddPath(ctx, path)
        CGContextSetFillColorWithColor(ctx, UIColor.blackColor().CGColor)
        CGContextSetStrokeColorWithColor(ctx, UIColor.lightGrayColor().CGColor)
        CGContextDrawPath(ctx, .FillStroke)
        
        CGContextAddPath(ctx, path)
        CGContextClip(ctx)
        
        let stringFormat: String
        if precisionTen < 0 {
            stringFormat = String(format:"%%.0%df", -precisionTen)
        } else {
            stringFormat = "%.0f"
        }
        
        let roundedValue = round(value / precision) * precision
        let delta = (value - roundedValue) / precision
        let textLeading = fontSize.height * 0.8
        
        // FIXME Check for negative values (if not allowed) and replace by empty string
        let stringValues: [String] = [String(format: stringFormat, roundedValue + precision), String(format: stringFormat, roundedValue), String(format: stringFormat, roundedValue - precision)]

        let commonPrefixString = commonPrefix([String](delta > 0 ? stringValues.prefix(2) : stringValues.suffix(2))) as NSString
        
        var suffix = uniqueSuffix(stringValues[0], refString: stringValues[1]) as NSString
        
        // FIXME: Not sure why we need the -2.5 offset to have the text perfectly centered in the control
        var textRect = CGRect(x: rect.minX, y: rect.midY - 2.5 + textLeading * CGFloat(-1.5 + delta), width: rect.width - 4 - (leftMark ? 0.0 : markWidth), height: fontSize.height)
        suffix.drawInRect(textRect, withAttributes: textAttributes)
        
        textRect = textRect.offsetBy(dx: 0, dy: textLeading)
        suffix = uniqueSuffix(stringValues[1], refString: delta <= 0 ? stringValues[2] : stringValues[0]) as NSString

        let suffixWidth = suffix.sizeWithAttributes(textAttributes).width
        suffix.drawInRect(textRect, withAttributes: textAttributes)
        commonPrefixString.drawInRect(CGRect(x: textRect.minX, y: rect.midY - 2.5 - textLeading / 2, width: rect.width - 4 - (leftMark ? 0.0 : markWidth) - suffixWidth, height: fontSize.height), withAttributes: textAttributes)
        
        textRect = textRect.offsetBy(dx: 0, dy: textLeading)
        suffix = uniqueSuffix(stringValues[2], refString: stringValues[1]) as NSString
        
        suffix.drawInRect(textRect, withAttributes: textAttributes)
        
        CGContextClipToRect(ctx, CGRect(x: maxX - rollerWidth + 4, y: rect.minY, width: rollerWidth + 4 - 1, height: rect.height))
        let locations: [CGFloat] = [ 0.0, 0.25, 0.75, 1 ]
        let colors: CFArray = [UIColor.blackColor().CGColor, UIColor.clearColor().CGColor, UIColor.clearColor().CGColor, UIColor.blackColor().CGColor]
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradientCreateWithColors(colorspace, colors, locations)
        CGContextDrawLinearGradient(ctx, gradient, CGPoint(x: maxX, y: rect.minY), CGPoint(x: maxX, y: rect.maxY), CGGradientDrawingOptions(rawValue: 0))
        
        CGContextRestoreGState(ctx)
     }
    
    private func commonPrefix(strings: [String]) -> String {
        var length = -1
        for s in strings {
            if length == -1 {
                length = s.characters.count
            } else if s.characters.count != length {
                return ""
            }
        }
        var commonPrefix = ""
        var index = 0
        while true {
            if index >= length {
                break
            }
            var char: Character?
            for s in strings {
                let c = s.characters[s.characters.startIndex.advancedBy(index)]
                if char == nil {
                    char = c
                } else if char != c {
                    char = nil
                    break
                }
            }
            if char == nil {
                break
            }
            commonPrefix.append(char!)
            index++
        }
        
        return commonPrefix
    }
    
    private func uniqueSuffix(string: String, refString: String) -> String {
        let chars = string.characters
        let refChars = refString.characters
        let length = chars.count
        if length != refChars.count {
            return string
        }
        for var index = 0; index < length; index++ {
            let charIndex = chars.startIndex.advancedBy(index)
            if chars[charIndex] != refChars[refChars.startIndex.advancedBy(index)] {
                return string.substringFromIndex(charIndex)
            }
        }
        return ""
    }
    
    func timerDidFire(timer: NSTimer) {
        origin += 0.05
        setNeedsDisplay()
    }
    
    func drawVerticalScaleMarker(ctx: CGContext, rect: CGRect, rightAligned: Bool, scale: Double, midPoint: Double, value: Double, color: UIColor) {
        let textAttributes: [String : AnyObject] = [ NSFontAttributeName : font ]
        let fontSize = ("0" as NSString).sizeWithAttributes(textAttributes)

        let markerHeight = fontSize.height * 2
        
        let top = rect.midY - CGFloat((value - midPoint) * scale) - markerHeight / 2
        if top > rect.maxY {
            return
        }
        let bottom = top + markerHeight
        if bottom < rect.minY {
            return
        }
        let markerWidth = fontSize.height / 2 * 0.8660 + 4        // sin(60°)
        let right: CGFloat
        
        if rightAligned {
            right = rect.maxX
        } else {
            right = rect.minX + markerWidth
        }
        let left = right - markerWidth

        CGContextMoveToPoint(ctx, left, top)
        CGContextAddLineToPoint(ctx, right, top)
        if !rightAligned {
            CGContextAddLineToPoint(ctx, right, top + markerHeight / 2 - fontSize.height / 4)
            CGContextAddLineToPoint(ctx, right - markerWidth + 4, top + markerHeight / 2)
            CGContextAddLineToPoint(ctx, right, top + markerHeight / 2 + fontSize.height / 4)
        }
        CGContextAddLineToPoint(ctx, right, bottom)
        CGContextAddLineToPoint(ctx, left, bottom)
        if rightAligned {
            CGContextAddLineToPoint(ctx, left, top + markerHeight / 2 + fontSize.height / 4)
            CGContextAddLineToPoint(ctx, left + markerWidth - 4, top + markerHeight / 2)
            CGContextAddLineToPoint(ctx, left, top + markerHeight / 2 - fontSize.height / 4)
        }
        CGContextClosePath(ctx)

        CGContextSetFillColorWithColor(ctx, color.CGColor)
        CGContextSetStrokeColorWithColor(ctx, UIColor.darkGrayColor().CGColor)
        CGContextDrawPath(ctx, .FillStroke)
    }
    
    func drawAttitudeIndicator(ctx: CGContext, rect: CGRect, horizonY: CGFloat, pitch: Double, var roll: Double) {
        CGContextSaveGState(ctx)
        CGContextClipToRect(ctx, rect)
        
        roll = roll * M_PI / 180
        //let hRoll = Double(rect.width) / 2 * tan(roll)
        let indicatorWidth: CGFloat = 190.0           // FIXME Set this outside
        let cornerRadius: CGFloat = 2
        let pitchScale = indicatorWidth / 100         // pixels per degree
        
        CGContextTranslateCTM(ctx, rect.midX, horizonY - CGFloat(pitch) * pitchScale)
        CGContextRotateCTM(ctx, CGFloat(-roll))
        
        // Sky
        CGContextSetFillColorWithColor(ctx, UIColor(colorLiteralRed: Float(0x33) / 255, green: Float(0x99) / 255, blue: Float(0xFF) / 255, alpha: 1).CGColor)
        CGContextFillRect(ctx, CGRect(x: -rect.width * 1.5, y: -rect.height * 1.5, width: rect.width * 3, height: rect.height * 1.5))

        // Ground
        CGContextSetFillColorWithColor(ctx, UIColor.brownColor().CGColor)
        CGContextFillRect(ctx, CGRect(x: -rect.width * 1.5, y: 0, width: rect.width * 3, height: rect.height * 1.5))

        // Horizon
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextFillRect(ctx, CGRect(x: -rect.width * 1.5, y: -0.5, width: rect.width * 3, height: 1))

        // Pitch angle scale
        CGContextSetStrokeColorWithColor(ctx, UIColor.whiteColor().CGColor)
        let scaleFont = UIFont(name: "Verdana", size: 11)!
        let attributes: [String : AnyObject]? = [ NSFontAttributeName : scaleFont, NSForegroundColorAttributeName : UIColor.whiteColor()]
        for pitch in [-20, -10, 10, 20] {
            let y = CGFloat(pitch) * pitchScale
            CGContextMoveToPoint(ctx, -20, y)
            CGContextAddLineToPoint(ctx, 20, y)
            
            let legend = String(format: "%d", abs(pitch)) as NSString
            let legendSize = legend.sizeWithAttributes(attributes)
            legend.drawInRect(CGRect(origin: CGPoint(x: -24 - legendSize.width, y: y - legendSize.height / 2), size: legendSize), withAttributes: attributes)
            legend.drawInRect(CGRect(origin: CGPoint(x: 24, y: y - legendSize.height / 2), size: legendSize), withAttributes: attributes)
        }
        for pitch in [-25, -15, -5, 5, 15, 25] {
            let y = CGFloat(pitch) * pitchScale
            CGContextMoveToPoint(ctx, -10, y)
            CGContextAddLineToPoint(ctx, 10, y)
        }
        CGContextStrokePath(ctx)
        
        // Roll angle scale
        CGContextRotateCTM(ctx, CGFloat(roll))
        CGContextTranslateCTM(ctx, 0, CGFloat(pitch) * pitchScale)
        CGContextRotateCTM(ctx, CGFloat(-roll))
        
        CGContextSetStrokeColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextAddArc(ctx, 0, 0, indicatorWidth / 2, CGFloat(-5 * M_PI / 6.0), CGFloat(-M_PI / 6.0), 0)
        
        for a in [-5.0, -4.0, -2.0, -1.0] {
            CGContextMoveToPoint(ctx, CGFloat(cos(a * M_PI / 6.0)) * (indicatorWidth / 2), CGFloat(sin(a * M_PI / 6.0)) * (indicatorWidth / 2))
            CGContextAddLineToPoint(ctx, CGContextGetPathCurrentPoint(ctx).x + CGFloat(cos(a * M_PI / 6.0)) * 10, CGContextGetPathCurrentPoint(ctx).y + CGFloat(sin(a * M_PI / 6.0)) * 10)
        }
        for a in [-4.5, -3.6666, -3.3333, -2.6666, -2.3333, -1.5] {
            CGContextMoveToPoint(ctx, CGFloat(cos(a * M_PI / 6.0)) * (indicatorWidth / 2), CGFloat(sin(a * M_PI / 6.0)) * (indicatorWidth / 2))
            CGContextAddLineToPoint(ctx, CGContextGetPathCurrentPoint(ctx).x + CGFloat(cos(a * M_PI / 6.0)) * 6, CGContextGetPathCurrentPoint(ctx).y + CGFloat(sin(a * M_PI / 6.0)) * 6)
        }
        CGContextMoveToPoint(ctx, 0, -indicatorWidth / 2)
        
        CGContextAddLineToPoint(ctx, CGContextGetPathCurrentPoint(ctx).x + 15 * CGFloat(cos(M_PI / 2.7)), CGContextGetPathCurrentPoint(ctx).y - 15 * CGFloat(sin(M_PI / 2.7)))
        CGContextAddLineToPoint(ctx, CGContextGetPathCurrentPoint(ctx).x - 30 * CGFloat(cos(M_PI / 2.7)), CGContextGetPathCurrentPoint(ctx).y)
        CGContextAddLineToPoint(ctx, CGContextGetPathCurrentPoint(ctx).x + 15 * CGFloat(cos(M_PI / 2.7)), CGContextGetPathCurrentPoint(ctx).y + 15 * CGFloat(sin(M_PI / 2.7)))
        
        CGContextStrokePath(ctx)
        
        CGContextRotateCTM(ctx, CGFloat(roll))
        CGContextTranslateCTM(ctx, -rect.midX, -horizonY)
        
        // Yellow roll reference
        CGContextSetStrokeColorWithColor(ctx, UIColor.yellowColor().CGColor)
        CGContextSetLineWidth(ctx, 3)
        CGContextMoveToPoint(ctx, rect.midX, horizonY - indicatorWidth / 2 + 3)
        CGContextAddLineToPoint(ctx, rect.midX + 15 * CGFloat(cos(M_PI / 2.7)), horizonY - indicatorWidth / 2 + 3 + 15 * CGFloat(sin(M_PI / 2.7)))
        CGContextAddLineToPoint(ctx, rect.midX - 15 * CGFloat(cos(M_PI / 2.7)), horizonY - indicatorWidth / 2 + 3 + 15 * CGFloat(sin(M_PI / 2.7)))
        CGContextClosePath(ctx)
        CGContextStrokePath(ctx)
        
        // Yellow horizon reference
        CGContextSetLineWidth(ctx, 1)
        CGContextSetFillColorWithColor(ctx, UIColor.yellowColor().CGColor)
        CGContextMoveToPoint(ctx, rect.midX - indicatorWidth / 2 + cornerRadius, horizonY - cornerRadius)
        CGContextAddLineToPoint(ctx, rect.midX - 30 - cornerRadius, horizonY - cornerRadius)
        CGContextAddArc(ctx, rect.midX - 30 - cornerRadius, horizonY, cornerRadius, CGFloat(-M_PI / 2), CGFloat(M_PI / 2), 0)
        CGContextAddLineToPoint(ctx, rect.midX - indicatorWidth / 2 + cornerRadius, horizonY + cornerRadius)
        CGContextAddArc(ctx, rect.midX - indicatorWidth / 2 + cornerRadius, horizonY, cornerRadius, CGFloat(M_PI / 2), CGFloat(-M_PI / 2), 0)
        CGContextFillPath(ctx)

        CGContextMoveToPoint(ctx, rect.midX + indicatorWidth / 2 - cornerRadius, horizonY - cornerRadius)
        CGContextAddLineToPoint(ctx, rect.midX + 30 + cornerRadius, horizonY - cornerRadius)
        CGContextAddArc(ctx, rect.midX + 30 + cornerRadius, horizonY, cornerRadius, CGFloat(-M_PI / 2), CGFloat(M_PI / 2), 1)
        CGContextAddLineToPoint(ctx, rect.midX + indicatorWidth / 2 - cornerRadius, horizonY + cornerRadius)
        CGContextAddArc(ctx, rect.midX + indicatorWidth / 2 - cornerRadius, horizonY, cornerRadius, CGFloat(M_PI / 2), CGFloat(-M_PI / 2), 1)
        CGContextFillPath(ctx)
        
        CGContextFillEllipseInRect(ctx, CGRect(x: rect.midX - cornerRadius, y: horizonY - cornerRadius, width: cornerRadius * 2, height: cornerRadius * 2))
        
        CGContextRestoreGState(ctx)
    }
}
