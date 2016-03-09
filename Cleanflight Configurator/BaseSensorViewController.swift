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
    
    var timerInterval = 0.1     // 100ms by default
    var timer: NSTimer?
    
    var chartView: LineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        chartView.rightAxis.enabled = false;
        
        chartView.xAxis.enabled = false
        
        chartView.descriptionText = ""
    }

    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        msp.addDataListener(self)
        
        if (timer == nil) {
            // Cleanflight/chrome uses configurable interval (default 50ms)
            timer = NSTimer(timeInterval: timerInterval, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
            NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        msp.removeDataListener(self)
        
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
}
