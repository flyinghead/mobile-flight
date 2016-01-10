//
//  ReceiverChannel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 03/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

@IBDesignable
class ReceiverChannel: UIView {

    @IBInspectable var label: String = "Channel" {
        didSet {
            labelControl?.text = label
        }
    }
    @IBInspectable var color: UIColor? {
        didSet {
            if color != nil {
                slider?.color = color!
            }
        }
    }
    @IBInspectable var fontSize: CGFloat = UIFont.systemFontSize() {
        didSet {
            labelControl?.font = UIFont.systemFontOfSize(fontSize)
            valueLabel?.font = UIFont.systemFontOfSize(fontSize)
        }
    }
    
    var labelControl: UILabel?
    var slider: LinearGauge?
    var valueLabel: UILabel?

    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        if (labelControl == nil) {
            labelControl = UILabel()
            labelControl!.text = label
            labelControl?.font = UIFont.systemFontOfSize(fontSize)
            labelControl?.translatesAutoresizingMaskIntoConstraints = false
            addSubview(labelControl!)
        }
        if (slider == nil) {
            slider = LinearGauge();
            slider?.minimumValue = 900
            slider?.maximumValue = 2100
            slider?.value = 1500
            slider?.cornerRadius = 6
            slider?.translatesAutoresizingMaskIntoConstraints = false
            if color != nil {
                slider?.color = color!
            }
            slider?.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
            addSubview(slider!)
        }
        if (valueLabel == nil) {
            valueLabel = UILabel()
            valueLabel?.text = String(format: "%d", locale: NSLocale.currentLocale(), 2000)
            valueLabel?.textAlignment = .Right
            valueLabel?.font = UIFont.systemFontOfSize(fontSize)
            valueLabel?.translatesAutoresizingMaskIntoConstraints = false
            addSubview(valueLabel!)

            let v1 = NSLayoutConstraint(item: labelControl!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
            addConstraint(v1)
            
            labelControl!.text = "Throttle"
            let w1 = NSLayoutConstraint(item: labelControl!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: labelControl?.intrinsicContentSize().width ?? 65)
            labelControl!.text = label
            
            addConstraint(w1)
            let left1 = NSLayoutConstraint(item: labelControl!, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0)
            addConstraint(left1)

            let v2 = NSLayoutConstraint(item: slider!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
            addConstraint(v2)
            let left2 = NSLayoutConstraint(item: slider!, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: labelControl, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: 8)
            addConstraint(left2)
            let height2 = NSLayoutConstraint(item: slider!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: labelControl, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 6)
            addConstraint(height2)
            
            let v3 = NSLayoutConstraint(item: valueLabel!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
            addConstraint(v3)
            let w3 = NSLayoutConstraint(item: valueLabel!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: valueLabel?.intrinsicContentSize().width ?? 45)
            addConstraint(w3)
            let right3 = NSLayoutConstraint(item: valueLabel!, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: 0)
            addConstraint(right3)
            let left3 = NSLayoutConstraint(item: slider!, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: valueLabel, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: -8)
            addConstraint(left3)
        }
        setValue(0)
    }
    
    func setValue(value: Int) {
        slider?.value = Double(value)
        valueLabel?.text = String(format: "%d", locale: NSLocale.currentLocale(), value)
    }
}
