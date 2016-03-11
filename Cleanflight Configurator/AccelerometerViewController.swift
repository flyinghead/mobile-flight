//
//  AccelerometerViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 04/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import Charts

class AccelerometerViewController: XYZSensorViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let leftAxis = chartView.leftAxis;
        leftAxis.customAxisMax = 2.0;
        leftAxis.customAxisMin = -2.0;
        
        let nf = NSNumberFormatter()
        nf.locale = NSLocale.currentLocale()
        nf.maximumFractionDigits = 1
        chartView.leftAxis.valueFormatter = nf
    }

    override func updateSensorData() {
        let sensorData = mspvehicle.sensorData
        
        xSensor.append(sensorData.accelerometerX);
        ySensor.append(sensorData.accelerometerY);
        zSensor.append(sensorData.accelerometerZ);
    }
}
