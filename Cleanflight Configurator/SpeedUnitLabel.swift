//
//  SpeedUnitLabel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 16/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class UnitLabel : UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func commonInit() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SpeedUnitLabel.userDefaultsDidChange(_:)), name: NSUserDefaultsDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SpeedUnitLabel.userDefaultsDidChange(_:)), name: kIASKAppSettingChanged, object: nil)
        userDefaultsDidChange(self)
    }
    
    func userDefaultsDidChange(sender: AnyObject) {
        self.text = self.unit
    }

    var unit: String {
        return ""
    }
    
}

@IBDesignable
class SpeedUnitLabel: UnitLabel {
    override var unit: String {
        return speedUnit()
    }
}

@IBDesignable
class VerticalSpeedLabel: UnitLabel {
    override var unit: String {
        return verticalSpeedUnit()
    }
}

@IBDesignable
class DistanceUnitLabel: UnitLabel {
    override var unit: String {
        return distanceUnit()
    }
}
