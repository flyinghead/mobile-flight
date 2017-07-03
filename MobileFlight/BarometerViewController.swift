//
//  BarometerViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 05/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import Charts

class BarometerViewController: BaseSensorViewController {
    @IBOutlet weak var titleLabel: UILabel!

    var samples = [Double]()
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let leftAxis = chartView.leftAxis
        leftAxis.setLabelCount(5, force: false)

        if selectedUnitSystem() != .Metric {
            leftAxis.axisMaxValue = 10.0
            leftAxis.axisMinValue = 0.0
        } else {
            leftAxis.axisMaxValue = 2.0
            leftAxis.axisMinValue = 0.0
        }
        
        let nf = NSNumberFormatter()
        nf.locale = NSLocale.currentLocale()
        nf.maximumFractionDigits = 1
        chartView.leftAxis.valueFormatter = nf
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BarometerViewController.userDefaultsDidChange(_:)), name: NSUserDefaultsDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BarometerViewController.userDefaultsDidChange(_:)), name: kIASKAppSettingChanged, object: nil)
        userDefaultsDidChange(self)
    }

    func makeDataSet(yVals: [ChartDataEntry]) -> ChartDataSet {
        return makeDataSet(yVals, label: "Altitude", color: UIColor.blueColor())
    }
    
    func updateChartData() {
        var yVals = [ChartDataEntry]()
        let initialOffset = samples.count - MaxSampleCount
        
        for i in 0..<samples.count {
            yVals.append(ChartDataEntry(value: samples[i], xIndex: i - initialOffset))
        }
        
        let dataSet = makeDataSet(yVals)

        let data = LineChartData(xVals: [String?](count: MaxSampleCount, repeatedValue: nil), dataSet: dataSet)
        
        chartView.data = data
        view.setNeedsDisplay()
    }
    
    func receivedAltitudeData() {
        updateSensorData()
        while samples.count > MaxSampleCount {
            samples.removeFirst()
        }
        updateChartData()
    }
    
    override func viewWillAppear(animated: Bool) {
        if eventHandler == nil {
            eventHandler = msp.altitudeEvent.addHandler(self, handler: BarometerViewController.receivedAltitudeData)
        }
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        samples.removeAll()
    }
    
    func updateSensorData() {
        let sensorData = SensorData.theSensorData
        
        let value = selectedUnitSystem() != .Metric ? sensorData.altitude * 100 / 2.54 / 12 : sensorData.altitude
        samples.append(value)
        
        let leftAxis = chartView.leftAxis
        if value > leftAxis.axisMaxValue {
            leftAxis.resetCustomAxisMax()
        }
        if value < leftAxis.axisMinValue {
            leftAxis.resetCustomAxisMin()
        }
    }
    
    func userDefaultsDidChange(sender: AnyObject) {
        titleLabel.text = selectedUnitSystem() != .Metric ? "Barometer - feet" : "Barometer - meters"
    }
}
