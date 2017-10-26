//
//  BarometerViewController.swift
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

class BarometerViewController: BaseSensorViewController {
    @IBOutlet weak var titleLabel: UILabel!

    var samples = [Double]()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let leftAxis = chartView.leftAxis
        leftAxis.setLabelCount(5, force: false)

        if selectedUnitSystem() != .metric {
            leftAxis.axisMaximum = 10.0
            leftAxis.axisMinimum = 0.0
        } else {
            leftAxis.axisMaximum = 2.0
            leftAxis.axisMinimum = 0.0
        }
        
        let nf = NumberFormatter()
        nf.locale = Locale.current
        nf.maximumFractionDigits = 1
        chartView.leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: nf)
        
        NotificationCenter.default.addObserver(self, selector: #selector(BarometerViewController.userDefaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BarometerViewController.userDefaultsDidChange(_:)), name: NSNotification.Name(rawValue: kIASKAppSettingChanged), object: nil)
        userDefaultsDidChange(self)
    }

    func makeDataSet(_ yVals: [ChartDataEntry]) -> ChartDataSet {
        return makeDataSet(yVals, label: "Altitude", color: UIColor.blue)
    }
    
    func updateChartData() {
        var yVals = [ChartDataEntry]()
        let initialOffset = samples.count - MaxSampleCount
        
        for i in 0 ..< samples.count {
            yVals.append(ChartDataEntry(x: Double(i - initialOffset), y: samples[i]))
        }
        
        let dataSet = makeDataSet(yVals)

        let data = LineChartData(dataSet: dataSet)
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        if eventHandler == nil {
            eventHandler = msp.altitudeEvent.addHandler(self, handler: BarometerViewController.receivedAltitudeData)
        }
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        eventHandler?.dispose()
        eventHandler = nil
        samples.removeAll()
    }
    
    func updateSensorData() {
        let sensorData = SensorData.theSensorData
        
        let value = selectedUnitSystem() != .metric ? sensorData.altitude * 100 / 2.54 / 12 : sensorData.altitude
        samples.append(value)
        
        let leftAxis = chartView.leftAxis
        if value > leftAxis.axisMaximum {
            leftAxis.resetCustomAxisMax()
        }
        if value < leftAxis.axisMinimum {
            leftAxis.resetCustomAxisMin()
        }
    }
    
    func userDefaultsDidChange(_ sender: Any) {
        titleLabel.text = selectedUnitSystem() != .metric ? "Barometer - feet" : "Barometer - meters"
    }
}
