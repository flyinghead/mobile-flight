//
//  SpeedUnitLabel.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 16/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
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
