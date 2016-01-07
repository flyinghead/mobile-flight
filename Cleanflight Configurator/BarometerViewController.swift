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
    @IBOutlet weak var titleLabel: UILabel!

    var samples = [Double]()
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        timerInterval = 0.1     // 100ms
        
        let leftAxis = chartView.leftAxis
        leftAxis.startAtZeroEnabled = false
        leftAxis.setLabelCount(5, force: false)

        if useImperialUnits() {
            leftAxis.customAxisMax = 10.0
            leftAxis.customAxisMin = 0.0
        } else {
            leftAxis.customAxisMax = 2.0
            leftAxis.customAxisMin = 0.0
        }
        
        let nf = NSNumberFormatter()
        nf.locale = NSLocale.currentLocale()
        nf.maximumFractionDigits = 1
        chartView.leftAxis.valueFormatter = nf
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userDefaultsDidChange:", name: NSUserDefaultsDidChangeNotification, object: nil)
        userDefaultsDidChange(self)
    }

    func makeDataSet(yVals: [ChartDataEntry]) -> ChartDataSet {
        return makeDataSet(yVals, label: "Altitude", color: UIColor.blueColor())
    }
    
    private func updateChartData() {
        var yVals = [ChartDataEntry]()
        let initialOffset = samples.count - MaxSampleCount
        
        for (var i = 0; i < samples.count; i++) {
            yVals.append(ChartDataEntry(value: samples[i], xIndex: i - initialOffset))
        }
        
        let dataSet = makeDataSet(yVals)

        let data = LineChartData(xVals: [String?](count: MaxSampleCount, repeatedValue: nil), dataSet: dataSet)
        
        chartView.data = data
        view.setNeedsDisplay()
    }
    
    func receivedSensorData() {
        if (timer != nil) {
            // Don't update the chart if we're not visible
            sensorCount++
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
        
        let value = useImperialUnits() ? sensorData.altitude * 100 / 2.54 / 12 : sensorData.altitude
        samples.append(value)
        
        let leftAxis = chartView.leftAxis
        if value > leftAxis.customAxisMax {
            leftAxis.resetCustomAxisMax()
        }
        if value < leftAxis.customAxisMin {
            leftAxis.resetCustomAxisMin()
        }
    }
    
    func userDefaultsDidChange(sender: AnyObject) {
        titleLabel.text = useImperialUnits() ? "Barometer - feet" : "Barometer - meters"
    }
}
