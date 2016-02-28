//
//  MotorStopConfigViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 08/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MotorStopConfigViewController: ConfigChildViewController {
    @IBOutlet weak var stopMotorSwitch: UISwitch!
    @IBOutlet weak var disarmDelayLabel: UILabel!
    @IBOutlet weak var disarmDelayStepper: UIStepper!
    @IBOutlet weak var hideableCell: UITableViewCell!

    @IBAction func motorSwitchChanged(sender: AnyObject) {
        tableView.reloadData()
        if (stopMotorSwitch.on) {
            settings!.features.insert(BaseFlightFeature.MotorStop)
            cell(hideableCell, setHidden: false)
        } else {
            settings!.features.remove(BaseFlightFeature.MotorStop)
            cell(hideableCell, setHidden: true)
        }
        reloadDataAnimated(true)
    }

    @IBAction func disarmDelayStep(sender: AnyObject) {
        settings!.autoDisarmDelay = Int(disarmDelayStepper.value)
        disarmDelayLabel.text = String(format: "Disarm motors after %d seconds", locale: NSLocale.currentLocale(), settings!.autoDisarmDelay ?? 5)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        configViewController?.refreshUI()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        stopMotorSwitch.on = settings!.features.contains(BaseFlightFeature.MotorStop) ?? false
        disarmDelayStepper.value = Double(settings!.autoDisarmDelay ?? 5)
        disarmDelayStep(disarmDelayStepper)
        cell(hideableCell, setHidden: !stopMotorSwitch.on)
        reloadDataAnimated(false)
    }
}
