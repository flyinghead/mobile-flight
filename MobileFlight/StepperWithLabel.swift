//
//  StepperWithLabel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 17/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

@IBDesignable
class StepperWithLabel : UIView {
    var contentView: UIView?
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var label: UILabel!

    @IBInspectable var minimumValue: Double {
        get {
            return stepper?.minimumValue ?? 0.00
        }
        set(newValue) {
            stepper?.minimumValue = newValue
        }
    }
    @IBInspectable var maximumValue: Double {
        get {
            return stepper?.maximumValue ?? 0.00
        }
        set(newValue) {
            stepper?.maximumValue = newValue
        }
    }
    @IBInspectable var value: Double {
        get {
            return stepper?.value ?? 0.00
        }
        set(newValue) {
            stepper?.value = newValue
            label?.text = labelFormatter(stepper.value)
        }
    }
    @IBInspectable var stepValue: Double {
        get {
            return stepper?.stepValue ?? 0.00
        }
        set(newValue) {
            stepper?.stepValue = newValue
        }
    }
    
    var labelFormatter: (Double) -> String = { value in
        return String(value)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func xibSetup() {
        guard let view = loadViewFromNib() else { return }
        label.text = labelFormatter(stepper.value)
        view.frame = bounds
        addSubview(view)
        addConstraint(NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: view, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0.0))
        contentView = view
    }
    
    func loadViewFromNib() -> UIView? {
        let bundle = NSBundle.mainBundle()
        let nib = UINib(nibName: "StepperWithLabel", bundle: bundle)
        return nib.instantiateWithOwner(self, options: nil).first as? UIView
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        xibSetup()
        contentView?.prepareForInterfaceBuilder()
    }

    @IBAction func stepperChanged(sender: AnyObject) {
        label.text = labelFormatter(stepper.value)
    }
}
