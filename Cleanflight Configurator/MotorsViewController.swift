//
//  MotorsViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 07/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MotorsViewController: UIViewController, FlightDataListener, MSPCommandSender {

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
                self.enableSliders(true)
            }))
            alertController.popoverPresentationController?.sourceView = sender as? UIView
            presentViewController(alertController, animated: true, completion: nil)
        } else  {
            let miscData = Misc.theMisc
            masterSlider.value = Float(miscData.minCommand)
            slider1.value = Float(miscData.minCommand)
            slider2.value = Float(miscData.minCommand)
            slider3.value = Float(miscData.minCommand)
            slider4.value = Float(miscData.minCommand)
            slider5.value = Float(miscData.minCommand)
            slider6.value = Float(miscData.minCommand)
            slider7.value = Float(miscData.minCommand)
            slider8.value = Float(miscData.minCommand)
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

        value1.font = value1.font.monospacedDigitFont
        value2.font = value2.font.monospacedDigitFont
        value3.font = value3.font.monospacedDigitFont
        value4.font = value4.font.monospacedDigitFont
        value5.font = value5.font.monospacedDigitFont
        value6.font = value6.font.monospacedDigitFont
        value7.font = value7.font.monospacedDigitFont
        value8.font = value8.font.monospacedDigitFont
        
        modelView.image = MultiTypes.getImage(Configuration.theConfig.multiType)
        
        msp.sendMessage(.MSP_MISC, data: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        msp.addDataListener(self)
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.addMSPCommandSender(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        msp.removeDataListener(self)
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
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

    func receivedData() {
        let miscData = Misc.theMisc
        masterSlider.minimumValue = Float(miscData.minCommand)
        masterSlider.maximumValue = Float(miscData.maxThrottle)
        slider1.minimumValue = Float(miscData.minCommand)
        slider1.maximumValue = Float(miscData.maxThrottle)
        slider2.minimumValue = Float(miscData.minCommand)
        slider2.maximumValue = Float(miscData.maxThrottle)
        slider3.minimumValue = Float(miscData.minCommand)
        slider3.maximumValue = Float(miscData.maxThrottle)
        slider4.minimumValue = Float(miscData.minCommand)
        slider4.maximumValue = Float(miscData.maxThrottle)
        slider5.minimumValue = Float(miscData.minCommand)
        slider5.maximumValue = Float(miscData.maxThrottle)
        slider6.minimumValue = Float(miscData.minCommand)
        slider6.maximumValue = Float(miscData.maxThrottle)
        slider7.minimumValue = Float(miscData.minCommand)
        slider7.maximumValue = Float(miscData.maxThrottle)
        slider8.minimumValue = Float(miscData.minCommand)
        slider8.maximumValue = Float(miscData.maxThrottle)
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
