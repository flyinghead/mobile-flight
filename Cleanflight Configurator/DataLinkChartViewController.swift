//
//  DataLinkChartViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 06/04/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import Charts

class DataLinkChartViewController: UIViewController {

    let MaxSampleCount = 300
    
    var latencies = [Double]()
    var dataRates = [Double]()
    
    var timerInterval = 0.25
    var timer: NSTimer?
    
    @IBOutlet weak var chartView: LineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chartView.rightAxis.enabled = false;
        
        chartView.xAxis.enabled = false
        
        chartView.descriptionText = ""
        
        let leftAxis = chartView.leftAxis
        leftAxis.startAtZeroEnabled = false
        
        leftAxis.customAxisMax = 500
        leftAxis.customAxisMin = 0
        
        let nf = NSNumberFormatter()
        nf.locale = NSLocale.currentLocale()
        nf.maximumFractionDigits = 0
        chartView.leftAxis.valueFormatter = nf
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (timer == nil) {
            timer = NSTimer(timeInterval: timerInterval, target: self, selector: #selector(DataLinkChartViewController.timerDidFire(_:)), userInfo: nil, repeats: true)
            NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer?.invalidate()
        timer = nil
    }
    
    func makeDataSet(data: [ChartDataEntry], label: String, color: UIColor?) -> LineChartDataSet {
        let dataSet = LineChartDataSet(yVals: data, label: label)
        if (color != nil) {
            dataSet.setColor(color!)
        }
        dataSet.drawCirclesEnabled = false
        dataSet.drawCubicEnabled = false
        dataSet.drawCircleHoleEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.setDrawHighlightIndicators(false)
        dataSet.lineWidth = 2
        
        return dataSet;
    }
    
    func updateChartData() {
        var yVals1 = [ChartDataEntry]()
        var yVals2 = [ChartDataEntry]()
        let initialOffset = max(latencies.count, dataRates.count) - MaxSampleCount
        
        for i in 0 ..< latencies.count {
            yVals1.append(ChartDataEntry(value: latencies[i], xIndex: i - initialOffset))
        }
        for i in 0 ..< dataRates.count {
            yVals2.append(ChartDataEntry(value: dataRates[i], xIndex: i - initialOffset))
        }
        
        var dataSets = [IChartDataSet]()
        if latencies.count > 0 {
            let dataSet1 = makeDataSet(yVals1, label: "Latency (ms)", color: UIColor.blueColor())
            dataSets.append(dataSet1)
        }
        
        let dataSet2 = makeDataSet(yVals2, label: "Data rate (byte/s)", color: UIColor.redColor())
        dataSets.append(dataSet2)
        
        let data = LineChartData(xVals: [String?](count: MaxSampleCount, repeatedValue: nil), dataSets: dataSets)
        
        chartView.data = data
        view.setNeedsDisplay()
    }
    
    func timerDidFire(sender: AnyObject) {
        updateSensorData()
        while latencies.count > MaxSampleCount {
            latencies.removeFirst()
        }
        while dataRates.count > MaxSampleCount {
            dataRates.removeFirst()
        }
        updateChartData()
    }
    
    func updateSensorData() {
        let leftAxis = chartView.leftAxis
        
        if vehicle is MSPVehicle {
            let value = msp.latency * 1000
            latencies.append(value)
            if value > leftAxis.customAxisMax {
                leftAxis.resetCustomAxisMax()
            }
        }
        let dataRate = Double(CommSpeedMeter.instance.bytesPerSecond)
        dataRates.append(dataRate)
        
        if dataRate > leftAxis.customAxisMax {
            leftAxis.resetCustomAxisMax()
        }
    }
    
    
}
