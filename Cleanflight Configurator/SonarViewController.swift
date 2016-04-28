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
        leftAxis.customAxisMax = selectedUnitSystem() != .Metric ? 50.0 : 100.0
        leftAxis.customAxisMin =  0.0

        let nf = NSNumberFormatter()
        nf.locale = NSLocale.currentLocale()
        nf.maximumFractionDigits = 0
        leftAxis.valueFormatter = nf
    }

    override func makeDataSet(yVals: [ChartDataEntry]) -> ChartDataSet {
        return makeDataSet(yVals, label: "Sonar", color: UIColor.blueColor())
    }

    override func updateSensorData() {
        let sonar = Double(mspvehicle.sensorData.sonar)
        let value = selectedUnitSystem() != .Metric ? sonar / 2.54 : sonar
        
        samples.append(value)
        
        let leftAxis = chartView.leftAxis
        if value > leftAxis.customAxisMax {
            leftAxis.resetCustomAxisMax()
        }
        if value < leftAxis.customAxisMin {
            leftAxis.resetCustomAxisMin()
        }
    }

    override func sendMSPCommands() {
        msp.sendMessage(.MSP_SONAR, data: nil)
    }

    override func userDefaultsDidChange(sender: AnyObject) {
        titleLabel.text = selectedUnitSystem() != .Metric ? "Sonar - inches" : "Sonar - cm"
    }
    
    // MARK: FlightDataListener
    
    func receivedSonarData() {
        updateSensorData()
        while samples.count > MaxSampleCount {
            samples.removeFirst()
        }
        updateChartData()
    }

    override func receivedAltitudeData() {
        
    }
}
