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
        leftAxis.customAxisMax = 1.0;
        leftAxis.customAxisMin = -1.0;
        
        chartView.leftAxis.valueFormatter = NSNumberFormatter()
        chartView.leftAxis.valueFormatter?.maximumFractionDigits = 1
    }
    
    override func updateSensorData() {
        let sensorData = SensorData.theSensorData
        
        xSensor.append(sensorData.magnetometerX);
        ySensor.append(sensorData.magnetometerY);
        zSensor.append(sensorData.magnetometerZ);
    }
}
