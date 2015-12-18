//
//  SonarViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 06/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import Charts

class SonarViewController: BarometerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let leftAxis = chartView.leftAxis
        leftAxis.customAxisMax = 100.0
        leftAxis.customAxisMin =  0.0

    }

    override func makeDataSet(yVals: [ChartDataEntry]) -> ChartDataSet {
        return makeDataSet(yVals, label: "Sonar", color: UIColor.blueColor())
    }

    override func updateSensorData() {
        let sonar = Double(SensorData.theSensorData.sonar)
        
        samples.append(sonar)
        
        let leftAxis = chartView.leftAxis
        if sonar > leftAxis.customAxisMax {
            leftAxis.resetCustomAxisMax()
        }
        if sonar < leftAxis.customAxisMin {
            leftAxis.resetCustomAxisMin()
        }
    }

    override func timerDidFire(sender: AnyObject) {
        msp.sendMessage(.MSP_SONAR, data: nil)
    }

}
