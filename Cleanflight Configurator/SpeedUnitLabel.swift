//
//  SpeedUnitLabel.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 16/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

@IBDesignable
class SpeedUnitLabel: UILabel {

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
    
    private func commonInit() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SpeedUnitLabel.userDefaultsDidChange(_:)), name: NSUserDefaultsDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SpeedUnitLabel.userDefaultsDidChange(_:)), name: kIASKAppSettingChanged, object: nil)
        userDefaultsDidChange(self)
    }
    
    func userDefaultsDidChange(sender: AnyObject) {
        self.text = speedUnit()
    }

}
