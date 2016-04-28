//
//  XYZSensorViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 05/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import Charts

class XYZSensorViewController: BaseSensorViewController {

    var xSensor = [Double](), ySensor = [Double](), zSensor = [Double]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let leftAxis = chartView.leftAxis;
        leftAxis.startAtZeroEnabled = false;
        leftAxis.setLabelCount(5, force: false)
    }
    
    private func updateChartData() {
        var yValsX = [ChartDataEntry]()
        var yValsY = [ChartDataEntry]()
        var yValsZ = [ChartDataEntry]()
        let initialOffset = xSensor.count - MaxSampleCount
        
        for i in 0..<xSensor.count {
            yValsX.append(ChartDataEntry(value: xSensor[i], xIndex: i - initialOffset))
            yValsY.append(ChartDataEntry(value: ySensor[i], xIndex: i - initialOffset))
            yValsZ.append(ChartDataEntry(value: zSensor[i], xIndex: i - initialOffset))
        }
        
        let dataSetX = makeDataSet(yValsX, label: "X", color: UIColor.blueColor());
        let dataSetY = makeDataSet(yValsY, label: "Y", color: UIColor.greenColor());
        let dataSetZ = makeDataSet(yValsZ, label: "Z", color: UIColor.redColor());
        
        let data = LineChartData(xVals: [String?](count: MaxSampleCount, repeatedValue: nil), dataSets: [dataSetX, dataSetY, dataSetZ])
        
        chartView.data = data
        view.setNeedsDisplay()
    }
    
    func receivedRawIMUData() {
        updateSensorData()
        while xSensor.count > MaxSampleCount {
            xSensor.removeFirst()
            ySensor.removeFirst()
            zSensor.removeFirst()
        }
        updateChartData()
    }

    override func sendMSPCommands() {
        msp.sendMessage(.MSP_RAW_IMU, data: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        xSensor.removeAll()
        ySensor.removeAll()
        zSensor.removeAll()
    }
    
    func updateSensorData() {
        // Subclasses must override
    }
}
