//
//  GeoFenceViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 28/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class GeoFenceViewController: MyStaticDataViewController, UseMAVLinkVehicle {
    @IBOutlet weak var actionField: UITextField!
    @IBOutlet weak var rtlAltitudeField: NumberField!
    @IBOutlet weak var altitudeEnabled: UISwitch!
    @IBOutlet weak var maxAltitudeField: NumberField!
    @IBOutlet weak var altitudeMarginField: NumberField!
    @IBOutlet weak var circleEnabled: UISwitch!
    @IBOutlet weak var maxRadiusField: NumberField!

    private var actionPicker: MyDownPicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        actionPicker = MyDownPicker(textField: actionField, withData: [ "Report Only", "RTL or Land" ])
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        actionPicker.selectedIndex = Int(mavlinkVehicle.parametersById["FENCE_ACTION"]!.value)
        rtlAltitudeField.value = mavlinkVehicle.parametersById["RTL_ALT"]!.value / 100
        
        let fenceEnabled = mavlinkVehicle.parametersById["FENCE_ENABLE"]!.value != 0
        let fenceType = Int(mavlinkVehicle.parametersById["FENCE_TYPE"]!.value)
        altitudeEnabled.on = fenceEnabled && (fenceType & 1 != 0)
        altitudeEnableChanged(self)
        circleEnabled.on = fenceEnabled && (fenceType & 2 != 0)
        circleEnableChanged(self)
        
        maxAltitudeField.value = mavlinkVehicle.parametersById["FENCE_ALT_MAX"]!.value
        altitudeMarginField.value = mavlinkVehicle.parametersById["FENCE_MARGIN"]!.value
        
        maxRadiusField.value = mavlinkVehicle.parametersById["FENCE_RADIUS"]!.value
    }
    
    @IBAction func circleEnableChanged(sender: AnyObject) {
        maxRadiusField.enabled = circleEnabled.on
    }
    
    @IBAction func altitudeEnableChanged(sender: AnyObject) {
        maxAltitudeField.enabled = altitudeEnabled.on
        altitudeMarginField.enabled = altitudeEnabled.on
    }
}
