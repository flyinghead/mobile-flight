//
//  SonarViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 06/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import Charts

class SonarViewController: BarometerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let leftAxis = chartView.leftAxis;
        leftAxis.customAxisMax = 2.0;       // FIXME shouldn't use fixed min and max, or should monitor values
        leftAxis.customAxisMin = -1.0;

    }

    override func makeDataSet(yVals: [ChartDataEntry]) -> ChartDataSet {
        return makeDataSet(yVals, label: "Sonar", color: UIColor.blueColor());
    }

}
