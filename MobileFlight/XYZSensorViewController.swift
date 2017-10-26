//
//  XYZSensorViewController.swift
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

class XYZSensorViewController: BaseSensorViewController {

    var xSensor = [Double](), ySensor = [Double](), zSensor = [Double]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let leftAxis = chartView.leftAxis;
        leftAxis.setLabelCount(5, force: false)
    }
    
    fileprivate func updateChartData() {
        var yValsX = [ChartDataEntry]()
        var yValsY = [ChartDataEntry]()
        var yValsZ = [ChartDataEntry]()
        let initialOffset = xSensor.count - MaxSampleCount
        
        for i in 0 ..< xSensor.count {
            yValsX.append(ChartDataEntry(x: Double(i - initialOffset), y: xSensor[i]))
            yValsY.append(ChartDataEntry(x: Double(i - initialOffset), y: ySensor[i]))
            yValsZ.append(ChartDataEntry(x: Double(i - initialOffset), y: zSensor[i]))
        }
        
        let dataSetX = makeDataSet(yValsX, label: "X", color: UIColor.blue);
        let dataSetY = makeDataSet(yValsY, label: "Y", color: UIColor.green);
        let dataSetZ = makeDataSet(yValsZ, label: "Z", color: UIColor.red);
        
        let data = LineChartData(dataSets: [dataSetX, dataSetY, dataSetZ])
        
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
        msp.sendMessage(.msp_RAW_IMU, data: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        eventHandler = msp.rawIMUDataEvent.addHandler(self, handler: XYZSensorViewController.receivedRawIMUData)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        xSensor.removeAll()
        ySensor.removeAll()
        zSensor.removeAll()
    }
    
    func updateSensorData() {
        // Subclasses must override
    }
}
