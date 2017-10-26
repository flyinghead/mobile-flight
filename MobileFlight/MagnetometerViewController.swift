//
//  MagnetometerViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 05/12/15.
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
import Charts

class MagnetometerViewController: XYZSensorViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let leftAxis = chartView.leftAxis;
        leftAxis.axisMaximum = 1.0;
        leftAxis.axisMinimum = -1.0;
        
        let nf = NumberFormatter()
        nf.locale = Locale.current
        nf.maximumFractionDigits = 1
        chartView.leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: nf)
    }
    
    override func updateSensorData() {
        let sensorData = SensorData.theSensorData
        
        xSensor.append(sensorData.magnetometerX);
        ySensor.append(sensorData.magnetometerY);
        zSensor.append(sensorData.magnetometerZ);
    }
}
