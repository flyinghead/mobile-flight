//
//  BaseSensorViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 04/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import Charts

class BaseSensorViewController: UIViewController, FlightDataListener {

    let MaxSampleCount = 300
    
    var timerInterval = 0.05     // 50ms by default
    var timer: NSTimer?
    var sensorCount = 0
    
    var chartView: LineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        msp.addDataListener(self)
        
        chartView.rightAxis.enabled = false;
        
        chartView.xAxis.enabled = false
        //chartView.xAxis.drawLabelsEnabled = false
        
        //chartView.leftAxis.drawTopYLabelEntryEnabled = true
        
        chartView.descriptionText = ""
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (timer == nil) {
            // Cleanflight/chrome uses configurable interval (default 50ms)
            timer = NSTimer.scheduledTimerWithTimeInterval(timerInterval, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        timer?.invalidate()
        timer = nil
        
        sensorCount = 0
    }
    
    func makeDataSet(data: [ChartDataEntry], label: String, color: UIColor?) -> LineChartDataSet {
        let dataSet = LineChartDataSet(yVals: data)
        dataSet.label = label
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
}
