//
//  MotorsViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 07/12/15.
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
import Firebase

class MotorsViewController: UIViewController, MSPCommandSender {
    var motorEventHandler: Disposable?

    @IBOutlet weak var modelView: UIImageView!
    @IBOutlet weak var enableMotorView: UIView!
    
    @IBOutlet weak var enableMotorSwitch: UISwitch!
    @IBOutlet weak var masterSlider: UISlider!
    @IBOutlet weak var slider1: UISlider!
    @IBOutlet weak var slider2: UISlider!
    @IBOutlet weak var slider3: UISlider!
    @IBOutlet weak var slider4: UISlider!
    @IBOutlet weak var slider5: UISlider!
    @IBOutlet weak var slider6: UISlider!
    @IBOutlet weak var slider7: UISlider!
    @IBOutlet weak var slider8: UISlider!
    
    @IBOutlet weak var value1: UILabel!
    @IBOutlet weak var value2: UILabel!
    @IBOutlet weak var value3: UILabel!
    @IBOutlet weak var value4: UILabel!
    @IBOutlet weak var value5: UILabel!
    @IBOutlet weak var value6: UILabel!
    @IBOutlet weak var value7: UILabel!
    @IBOutlet weak var value8: UILabel!
    
    @IBAction func enableMotorChanged(sender: AnyObject) {
        let enable = (sender as? UISwitch)!.on
        
        if enable {
            let alertController = UIAlertController(title: "WARNING", message: "To avoid injury, be sure to remove the propellers from the motors before proceeding", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { alertController in
                self.enableMotorSwitch.on = false
            }))
            alertController.addAction(UIAlertAction(title: "Arm Motors", style: UIAlertActionStyle.Destructive, handler: { alertController in
                Analytics.logEvent("motors_armed", parameters: nil)
                self.enableSliders(true)
            }))
            alertController.popoverPresentationController?.sourceView = sender as? UIView
            presentViewController(alertController, animated: true, completion: nil)
        } else  {
            let settings = Settings.theSettings
            masterSlider.value = Float(settings.minCommand)
            slider1.value = Float(settings.minCommand)
            slider2.value = Float(settings.minCommand)
            slider3.value = Float(settings.minCommand)
            slider4.value = Float(settings.minCommand)
            slider5.value = Float(settings.minCommand)
            slider6.value = Float(settings.minCommand)
            slider7.value = Float(settings.minCommand)
            slider8.value = Float(settings.minCommand)
            sendMotorData()
            
            enableSliders(false)
        }
    }
    
    private func enableSliders(enable: Bool) {
        masterSlider.enabled = enable
        
        let motorData = MotorData.theMotorData
        if (motorData.nMotors >= 1) {
            slider1.enabled = enable
        }
        if (motorData.nMotors >= 2) {
            slider2.enabled = enable
        }
        if (motorData.nMotors >= 3) {
            slider3.enabled = enable
        }
        if (motorData.nMotors >= 4) {
            slider4.enabled = enable
        }
        if (motorData.nMotors >= 5) {
            slider5.enabled = enable
        }
        if (motorData.nMotors >= 6) {
            slider6.enabled = enable
        }
        if (motorData.nMotors >= 7) {
            slider7.enabled = enable
        }
        if (motorData.nMotors >= 8) {
            slider8.enabled = enable
        }
    }
    
    @IBAction func masterSliderChanged(sender: AnyObject) {
        let motorData = MotorData.theMotorData
        if (motorData.nMotors >= 1) {
            slider1.value = masterSlider.value
        }
        if (motorData.nMotors >= 2) {
            slider2.value = masterSlider.value
        }
        if (motorData.nMotors >= 3) {
            slider3.value = masterSlider.value
        }
        if (motorData.nMotors >= 4) {
            slider4.value = masterSlider.value
        }
        if (motorData.nMotors >= 5) {
            slider5.value = masterSlider.value
        }
        if (motorData.nMotors >= 6) {
            slider6.value = masterSlider.value
        }
        if (motorData.nMotors >= 7) {
            slider7.value = masterSlider.value
        }
        if (motorData.nMotors >= 8) {
            slider8.value = masterSlider.value
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 9.0, *) {
            value1.font = UIFont.monospacedDigitSystemFontOfSize(value1.font.pointSize, weight: UIFontWeightRegular)
            value2.font = UIFont.monospacedDigitSystemFontOfSize(value2.font.pointSize, weight: UIFontWeightRegular)
            value3.font = UIFont.monospacedDigitSystemFontOfSize(value3.font.pointSize, weight: UIFontWeightRegular)
            value4.font = UIFont.monospacedDigitSystemFontOfSize(value4.font.pointSize, weight: UIFontWeightRegular)
            value5.font = UIFont.monospacedDigitSystemFontOfSize(value5.font.pointSize, weight: UIFontWeightRegular)
            value6.font = UIFont.monospacedDigitSystemFontOfSize(value6.font.pointSize, weight: UIFontWeightRegular)
            value7.font = UIFont.monospacedDigitSystemFontOfSize(value7.font.pointSize, weight: UIFontWeightRegular)
            value8.font = UIFont.monospacedDigitSystemFontOfSize(value8.font.pointSize, weight: UIFontWeightRegular)
        }
        
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        motorEventHandler = msp.motorEvent.addHandler(self, handler: MotorsViewController.receivedMotorData)
        
        appDelegate.addMSPCommandSender(self)
        
        self.msp.sendMessage(.MSP_MIXER_CONFIG, data: nil, retry: 2, callback: { success in
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    self.modelView.image = MultiTypes.getImage(Settings.theSettings.mixerConfiguration)
                })
                // For minCommand and maxThrottle
                let callback: (Bool) -> Void = { success in
                    let settings = Settings.theSettings
                    self.masterSlider.minimumValue = Float(settings.minCommand)
                    self.masterSlider.maximumValue = Float(settings.maxThrottle)
                    self.slider1.minimumValue = Float(settings.minCommand)
                    self.slider1.maximumValue = Float(settings.maxThrottle)
                    self.slider2.minimumValue = Float(settings.minCommand)
                    self.slider2.maximumValue = Float(settings.maxThrottle)
                    self.slider3.minimumValue = Float(settings.minCommand)
                    self.slider3.maximumValue = Float(settings.maxThrottle)
                    self.slider4.minimumValue = Float(settings.minCommand)
                    self.slider4.maximumValue = Float(settings.maxThrottle)
                    self.slider5.minimumValue = Float(settings.minCommand)
                    self.slider5.maximumValue = Float(settings.maxThrottle)
                    self.slider6.minimumValue = Float(settings.minCommand)
                    self.slider6.maximumValue = Float(settings.maxThrottle)
                    self.slider7.minimumValue = Float(settings.minCommand)
                    self.slider7.maximumValue = Float(settings.maxThrottle)
                    self.slider8.minimumValue = Float(settings.minCommand)
                    self.slider8.maximumValue = Float(settings.maxThrottle)
                }
                let config = Configuration.theConfig
                if config.isApiVersionAtLeast("1.35") && !config.isINav {
                    self.msp.sendMessage(.MSP_MOTOR_CONFIG, data: nil, retry: 2, callback: callback)
                } else {
                    self.msp.sendMessage(.MSP_MISC, data: nil, retry: 2, callback: callback)
                }
            }
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        motorEventHandler?.dispose()
        
        appDelegate.removeMSPCommandSender(self)
    }
    
    func sendMSPCommands() {
        msp.sendMessage(.MSP_MOTOR, data: nil)
        if enableMotorSwitch.on {
            sendMotorData()
        }
    }

    func receivedMotorData() {
        let motorData = MotorData.theMotorData
        value1.text = String(format: "%d", motorData.throttle[0])
        value2.text = String(format: "%d", motorData.throttle[1])
        value3.text = String(format: "%d", motorData.throttle[2])
        value4.text = String(format: "%d", motorData.throttle[3])
        value5.text = String(format: "%d", motorData.throttle[4])
        value6.text = String(format: "%d", motorData.throttle[5])
        value7.text = String(format: "%d", motorData.throttle[6])
        value8.text = String(format: "%d", motorData.throttle[7])
    }
    
    func sendMotorData() {
        var buffer = [UInt8]()
        
        buffer.append(UInt8(Int(slider1.value) % 256))
        buffer.append(UInt8(Int(slider1.value) / 256))
        buffer.append(UInt8(Int(slider2.value) % 256))
        buffer.append(UInt8(Int(slider2.value) / 256))
        buffer.append(UInt8(Int(slider3.value) % 256))
        buffer.append(UInt8(Int(slider3.value) / 256))
        buffer.append(UInt8(Int(slider4.value) % 256))
        buffer.append(UInt8(Int(slider4.value) / 256))
        buffer.append(UInt8(Int(slider5.value) % 256))
        buffer.append(UInt8(Int(slider5.value) / 256))
        buffer.append(UInt8(Int(slider6.value) % 256))
        buffer.append(UInt8(Int(slider6.value) / 256))
        buffer.append(UInt8(Int(slider7.value) % 256))
        buffer.append(UInt8(Int(slider7.value) / 256))
        buffer.append(UInt8(Int(slider8.value) % 256))
        buffer.append(UInt8(Int(slider8.value) / 256))
        
        msp.sendMessage(.MSP_SET_MOTOR, data: buffer)
    }
}
