//
//  MotorStopConfigViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 08/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MotorStopConfigViewController: UITableViewController, ConfigChildViewController {
    @IBOutlet weak var stopMotorSwitch: UISwitch!
    @IBOutlet weak var disarmDelayLabel: UILabel!
    @IBOutlet weak var disarmDelayStepper: UIStepper!

    var configViewController: ConfigurationViewController?
    var settings: Settings?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    @IBAction func motorSwitchChanged(sender: AnyObject) {
        tableView.reloadData()
        if (stopMotorSwitch.on) {
            settings!.features!.insert(BaseFlightFeature.MotorStop)
        } else {
            settings!.features!.remove(BaseFlightFeature.MotorStop)
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && !stopMotorSwitch.on {
            return 0.0
        }
        return UITableViewAutomaticDimension
    }
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 1 && !stopMotorSwitch.on {
            return 0.0
        }
        return UITableViewAutomaticDimension
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 && !stopMotorSwitch.on {
            return 0.0
        }
        return UITableViewAutomaticDimension
    }
    @IBAction func disarmDelayStep(sender: AnyObject) {
        settings!.autoDisarmDelay = Int(disarmDelayStepper.value)
        disarmDelayLabel.text = String(format: "Disarm motors after %d seconds", settings!.autoDisarmDelay ?? 5)
    }
    
    func setReference(configViewController: ConfigurationViewController, newSettings: Settings, newMisc: Misc) {
        self.configViewController = configViewController
        self.settings = newSettings
    }
    override func viewWillDisappear(animated: Bool) {
        configViewController?.refreshData()
    }
    override func viewWillAppear(animated: Bool) {
        stopMotorSwitch.on = settings!.features?.contains(BaseFlightFeature.MotorStop) ?? false
        disarmDelayStepper.value = Double(settings!.autoDisarmDelay ?? 5)
        disarmDelayStep(disarmDelayStepper)
    }
}
