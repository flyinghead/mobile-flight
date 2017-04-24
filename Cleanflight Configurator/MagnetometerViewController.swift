//
//  MagnetometerViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 05/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MagnetometerViewController: XYZSensorViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let leftAxis = chartView.leftAxis;
        leftAxis.axisMaxValue = 1.0;
        leftAxis.axisMinValue = -1.0;
        
        let nf = NSNumberFormatter()
        nf.locale = NSLocale.currentLocale()
        nf.maximumFractionDigits = 1
        chartView.leftAxis.valueFormatter = nf
    }
    
    override func updateSensorData() {
        let sensorData = SensorData.theSensorData
        
        xSensor.append(sensorData.magnetometerX);
        ySensor.append(sensorData.magnetometerY);
        zSensor.append(sensorData.magnetometerZ);
    }
}
