//
//  SonarViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 06/12/15.
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

class SonarViewController: BarometerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let leftAxis = chartView.leftAxis
        leftAxis.axisMaximum = selectedUnitSystem() != .metric ? 50.0 : 100.0
        leftAxis.axisMinimum =  0.0

        let nf = NumberFormatter()
        nf.locale = Locale.current
        nf.maximumFractionDigits = 0
        leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: nf)
    }

    override func makeDataSet(_ yVals: [ChartDataEntry]) -> ChartDataSet {
        return makeDataSet(yVals, label: "Sonar", color: UIColor.blue)
    }

    override func updateSensorData() {
        let sonar = Double(SensorData.theSensorData.sonar)
        let value = selectedUnitSystem() != .metric ? sonar / 2.54 : sonar
        
        samples.append(value)
        
        let leftAxis = chartView.leftAxis
        if value > leftAxis.axisMaximum {
            leftAxis.resetCustomAxisMax()
        }
        if value < leftAxis.axisMinimum {
            leftAxis.resetCustomAxisMin()
        }
    }

    override func sendMSPCommands() {
        msp.sendMessage(.msp_SONAR, data: nil)
    }

    override func userDefaultsDidChange(_ sender: Any) {
        titleLabel.text = selectedUnitSystem() != .metric ? "Sonar - inches" : "Sonar - cm"
    }
    
    // MARK: Event Handlers
    
    func receivedSonarData() {
        updateSensorData()
        while samples.count > MaxSampleCount {
            samples.removeFirst()
        }
        updateChartData()
    }

    // MARK: 
    
    override func viewWillAppear(_ animated: Bool) {
        eventHandler = msp.sonarEvent.addHandler(self, handler: SonarViewController.receivedSonarData)
        super.viewWillAppear(animated)
    }
}
