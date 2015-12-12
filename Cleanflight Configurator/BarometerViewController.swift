//
//  BarometerViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 05/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import Charts

class BarometerViewController: BaseSensorViewController {

    var samples = [Double]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        timerInterval = 0.1     // 100ms
        
        let leftAxis = chartView.leftAxis;
        leftAxis.startAtZeroEnabled = false;
        leftAxis.setLabelCount(5, force: false)

        leftAxis.customAxisMax = 2.0;       // FIXME shouldn't use fixed min and max, or should monitor values
        leftAxis.customAxisMin = -1.0;
        
        chartView.leftAxis.valueFormatter = NSNumberFormatter()
        chartView.leftAxis.valueFormatter?.maximumFractionDigits = 1
    }

    func makeDataSet(yVals: [ChartDataEntry]) -> ChartDataSet {
        return makeDataSet(yVals, label: "Altitude", color: UIColor.blueColor());
    }
    
    private func updateChartData() {
        var yVals = [ChartDataEntry]()
        let initialOffset = samples.count - MaxSampleCount
        
        for (var i = 0; i < samples.count; i++) {
            yVals.append(ChartDataEntry(value: samples[i], xIndex: i - initialOffset))
        }
        
        let dataSet = makeDataSet(yVals);
        
        let data = LineChartData(xVals: [String?](count: MaxSampleCount, repeatedValue: nil), dataSet: dataSet)
        
        chartView.data = data
        view.setNeedsDisplay()
    }
    
    func receivedSensorData() {
        if (timer != nil) {
            // Don't update the chart if we're not visible
            sensorCount++;
            updateSensorData()
            if (samples.count > MaxSampleCount) {
                samples.removeFirst()
            }
            updateChartData()
        }
    }
    
    func timerDidFire(sender: AnyObject) {
        msp.sendMessage(.MSP_ALTITUDE, data: nil)
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        samples.removeAll()
        updateChartData()
    }
    
    func updateSensorData() {
        let sensorData = SensorData.theSensorData
        
        samples.append(sensorData.altitude);

    }
}
