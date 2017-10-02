//
//  AccelerometerViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 04/12/15.
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

class AccelerometerViewController: XYZSensorViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let leftAxis = chartView.leftAxis;
        leftAxis.axisMaxValue = 2.0;
        leftAxis.axisMinValue = -2.0;
        
        let nf = NSNumberFormatter()
        nf.locale = NSLocale.currentLocale()
        nf.maximumFractionDigits = 1
        chartView.leftAxis.valueFormatter = nf
    }

    override func updateSensorData() {
        let sensorData = SensorData.theSensorData
        
        xSensor.append(sensorData.accelerometerX);
        ySensor.append(sensorData.accelerometerY);
        zSensor.append(sensorData.accelerometerZ);
    }
}
