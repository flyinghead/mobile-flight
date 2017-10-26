//
//  DataLinkChartViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 06/04/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
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

class DataLinkChartViewController: UIViewController {

    let MaxSampleCount = 300
    
    var latencies = [Double]()
    var dataRates = [Double]()
    
    var timerInterval = 0.25
    var timer: Timer?
    
    @IBOutlet weak var chartView: LineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chartView.rightAxis.enabled = false;
        
        chartView.xAxis.enabled = false
        
        chartView.chartDescription?.text = ""
        
        let leftAxis = chartView.leftAxis
        
        leftAxis.axisMaximum = 500
        leftAxis.axisMinimum = 0
        
        let nf = NumberFormatter()
        nf.locale = Locale.current
        nf.maximumFractionDigits = 0
        chartView.leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: nf)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (timer == nil) {
            timer = Timer(timeInterval: timerInterval, target: self, selector: #selector(DataLinkChartViewController.timerDidFire(_:)), userInfo: nil, repeats: true)
            RunLoop.main.add(timer!, forMode: RunLoopMode.commonModes)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer?.invalidate()
        timer = nil
    }
    
    func makeDataSet(_ data: [ChartDataEntry], label: String, color: UIColor?) -> LineChartDataSet {
        let dataSet = LineChartDataSet(values: data, label: label)
        if (color != nil) {
            dataSet.setColor(color!)
        }
        dataSet.drawCirclesEnabled = false
        dataSet.mode = .cubicBezier
        dataSet.drawCircleHoleEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.setDrawHighlightIndicators(false)
        dataSet.lineWidth = 2
        
        return dataSet;
    }
    
    func updateChartData() {
        var yVals1 = [ChartDataEntry]()
        var yVals2 = [ChartDataEntry]()
        let initialOffset = latencies.count - MaxSampleCount
        
        for i in 0 ..< latencies.count {
            yVals1.append(ChartDataEntry(x: latencies[i], y: Double(i - initialOffset)))
            yVals2.append(ChartDataEntry(x: dataRates[i], y: Double(i - initialOffset)))
        }
        
        let dataSet1 = makeDataSet(yVals1, label: "Latency (ms)", color: UIColor.blue)
        let dataSet2 = makeDataSet(yVals2, label: "Data rate (byte/s)", color: UIColor.red)
        
        let data = LineChartData(dataSets: [ dataSet1, dataSet2 ])
        
        chartView.data = data
        view.setNeedsDisplay()
    }
    
    func timerDidFire(_ sender: Any) {
        updateSensorData()
        while latencies.count > MaxSampleCount {
            latencies.removeFirst()
            dataRates.removeFirst()
        }
        updateChartData()
    }
    
    func updateSensorData() {
        let value = msp.latency * 1000
        latencies.append(value)
        let dataRate = Double(msp.incomingBytesPerSecond)
        dataRates.append(dataRate)
        
        
        let leftAxis = chartView.leftAxis
        if value > leftAxis.axisMaximum || dataRate > leftAxis.axisMaximum {
            leftAxis.resetCustomAxisMax()
        }
    }
    
    
}
