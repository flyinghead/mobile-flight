//
//  MSPTelemetry.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 13/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MSPTelemetry: UIViewController, UseMSPVehicle {
    @IBOutlet weak var accroModeLabel: UILabel!
    @IBOutlet weak var altModeLabel: UILabel!
    @IBOutlet weak var headingModeLabel: UILabel!
    @IBOutlet weak var posModeLabel: UILabel!
    @IBOutlet weak var airModeLabel: UILabel!
    @IBOutlet weak var rxFailView: UIView!

    @IBOutlet weak var camStabMode: UIButton!
    @IBOutlet weak var calibrateMode: UIButton!
    @IBOutlet weak var telemetryMode: UIButton!
    @IBOutlet weak var sonarMode: UIButton!
    @IBOutlet weak var blackboxMode: UIButton!
    @IBOutlet weak var autotuneMode: UIButton!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        mspVehicle.angleMode.addObserver(self, listener: { newValue in
            self.setMspAccroMode()
        })
        mspVehicle.horizonMode.addObserver(self, listener: { newValue in
            self.setMspAccroMode()
        })
        mspVehicle.baroMode.addObserver(self, listener: { newValue in
            if newValue {
                self.altModeLabel.hidden = false
            } else if !self.mspVehicle.sonarMode.value {
                self.altModeLabel.hidden = true
            }
        })
        mspVehicle.sonarMode.addObserver(self, listener: { newValue in
            self.sonarMode.tintColor = newValue ? UIColor.greenColor() : UIColor.blackColor()
            if newValue {
                self.altModeLabel.hidden = false
            } else if !self.mspVehicle.baroMode.value {
                self.altModeLabel.hidden = true
            }
        })
        mspVehicle.magMode.addObserver(self, listener: { newValue in
            self.headingModeLabel.hidden = !newValue
        })
        mspVehicle.airMode.addObserver(self, listener: { newValue in
            self.airModeLabel.hidden = !newValue
        })
        mspVehicle.failsafeMode.addObserver(self, listener: { newValue in
            self.rxFailView.hidden = !newValue
        })
        mspVehicle.gpsHomeMode.addObserver(self, listener: { newValue in
            self.setMspGpsMode()
        })
        mspVehicle.gpsHoldMode.addObserver(self, listener: { newValue in
            self.setMspGpsMode()
        })
        
        mspVehicle.camStabMode.addObserver(self, listener: { newValue in
            self.camStabMode.tintColor = newValue ? UIColor.greenColor() : UIColor.blackColor()
        })
        mspVehicle.calibrateMode.addObserver(self, listener: { newValue in
            self.calibrateMode.tintColor = newValue ? UIColor.greenColor() : UIColor.blackColor()
        })
        mspVehicle.telemetryMode.addObserver(self, listener: { newValue in
            self.telemetryMode.tintColor = newValue ? UIColor.greenColor() : UIColor.blackColor()
        })
        mspVehicle.blackboxMode.addObserver(self, listener: { newValue in
            self.blackboxMode.tintColor = newValue ? UIColor.greenColor() : UIColor.blackColor()
        })
        mspVehicle.autotuneMode.addObserver(self, listener: { newValue in
            self.autotuneMode.tintColor = newValue ? UIColor.greenColor() : UIColor.blackColor()
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        mspVehicle.angleMode.removeObserver(self)
        mspVehicle.baroMode.removeObserver(self)
        mspVehicle.sonarMode.removeObserver(self)
        mspVehicle.magMode.removeObserver(self)
        mspVehicle.airMode.removeObserver(self)
        mspVehicle.failsafeMode.removeObserver(self)
        mspVehicle.gpsHomeMode.removeObserver(self)
        mspVehicle.gpsHoldMode.removeObserver(self)
        
        mspVehicle.camStabMode.removeObserver(self)
        mspVehicle.calibrateMode.removeObserver(self)
        mspVehicle.telemetryMode.removeObserver(self)
        mspVehicle.blackboxMode.removeObserver(self)
        mspVehicle.autotuneMode.removeObserver(self)
    }

    private func setMspAccroMode() {
        if let mspVehicle = vehicle as? MSPVehicle {
            if mspVehicle.angleMode.value {
                accroModeLabel.text = "ANGL"
                accroModeLabel.hidden = false
            } else if mspVehicle.horizonMode.value {
                accroModeLabel.text = "HOZN"
                accroModeLabel.hidden = false
            } else {
                accroModeLabel.hidden = true
            }
        }
    }
    
    private func setMspGpsMode() {
        if let mspVehicle = vehicle as? MSPVehicle {
            if mspVehicle.gpsHomeMode.value {
                posModeLabel.text = "RTH"
                posModeLabel.hidden = false
            } else if mspVehicle.gpsHoldMode.value {
                posModeLabel.text = "POS"
                posModeLabel.hidden = false
            } else {
                posModeLabel.hidden = true
            }
        }
    }
}
