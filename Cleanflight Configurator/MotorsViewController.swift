//
//  MotorsViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 07/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MotorsViewController: UIViewController {

    @IBOutlet weak var modelView: UIImageView!
    @IBOutlet weak var enableMotorView: UIView!
    
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
        
        if (!enable && vehicle is MSPVehicle) {
            let miscData = mspvehicle.misc
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
        }
        masterSlider.enabled = enable
        if let nMotors = vehicle.motors.value?.count {
            if nMotors >= 1 {
                slider1.enabled = enable
            }
            if nMotors >= 2 {
                slider2.enabled = enable
            }
            if nMotors >= 3 {
                slider3.enabled = enable
            }
            if nMotors >= 4 {
                slider4.enabled = enable
            }
            if nMotors >= 5 {
                slider5.enabled = enable
            }
            if nMotors >= 6 {
                slider6.enabled = enable
            }
            if nMotors >= 7 {
                slider7.enabled = enable
            }
            if nMotors >= 8 {
                slider8.enabled = enable
            }
        }
    }
    @IBAction func masterSliderChanged(sender: AnyObject) {
        if let nMotors = vehicle.motors.value?.count {
            if nMotors >= 1 {
                slider1.value = masterSlider.value
            }
            if nMotors >= 2 {
                slider2.value = masterSlider.value
            }
            if nMotors >= 3 {
                slider3.value = masterSlider.value
            }
            if nMotors >= 4 {
                slider4.value = masterSlider.value
            }
            if nMotors >= 5 {
                slider5.value = masterSlider.value
            }
            if nMotors >= 6 {
                slider6.value = masterSlider.value
            }
            if nMotors >= 7 {
                slider7.value = masterSlider.value
            }
            if nMotors >= 8 {
                slider8.value = masterSlider.value
            }
            sendMotorData()
        }
    }
    @IBAction func slider1Changed(sender: AnyObject) {
        sendMotorData()
    }
    @IBAction func slider2Changed(sender: AnyObject) {
        sendMotorData()
    }
    @IBAction func slider3Changed(sender: AnyObject) {
        sendMotorData()
    }
    @IBAction func slider4Changed(sender: AnyObject) {
        sendMotorData()
    }
    @IBAction func slider5Changed(sender: AnyObject) {
        sendMotorData()
    }
    @IBAction func slider6Changed(sender: AnyObject) {
        sendMotorData()
    }
    @IBAction func slider7Changed(sender: AnyObject) {
        sendMotorData()
    }
    @IBAction func slider8Changed(sender: AnyObject) {
        sendMotorData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //
        // FIXME MultiTypes.getImage(mspvehicle.config.multiType)
        //
        modelView.image = MultiTypes.getImage(3)

        if vehicle is MSPVehicle {
            let miscData = mspvehicle.misc
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
        } else {
            masterSlider.minimumValue = 1000
            masterSlider.maximumValue = 2000
            slider1.minimumValue = 1000
            slider1.maximumValue = 2000
            slider2.minimumValue = 1000
            slider2.maximumValue = 2000
            slider3.minimumValue = 1000
            slider3.maximumValue = 2000
            slider4.minimumValue = 1000
            slider4.maximumValue = 2000
            slider5.minimumValue = 1000
            slider5.maximumValue = 2000
            slider6.minimumValue = 1000
            slider6.maximumValue = 2000
            slider7.minimumValue = 1000
            slider7.maximumValue = 2000
            slider8.minimumValue = 1000
            slider8.maximumValue = 2000
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        vehicle.motors.addObserver(self) {_ in
            self.receivedMotorData()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        vehicle.motors.removeObserver(self)
    }

    private func receivedMotorData() {
        if vehicle.motors.value != nil {
            let motorData = vehicle.motors.value!
            value1.text = String(format: "%d", locale: NSLocale.currentLocale(), motorData[0])
            slider1.value = Float(motorData[0])
            value2.text = String(format: "%d", locale: NSLocale.currentLocale(), motorData[1])
            slider2.value = Float(motorData[1])
            value3.text = String(format: "%d", locale: NSLocale.currentLocale(), motorData[2])
            slider3.value = Float(motorData[2])
            value4.text = String(format: "%d", locale: NSLocale.currentLocale(), motorData[3])
            slider4.value = Float(motorData[3])
            value5.text = String(format: "%d", locale: NSLocale.currentLocale(), motorData[4])
            slider5.value = Float(motorData[4])
            value6.text = String(format: "%d", locale: NSLocale.currentLocale(), motorData[5])
            slider6.value = Float(motorData[5])
            value7.text = String(format: "%d", locale: NSLocale.currentLocale(), motorData[6])
            slider7.value = Float(motorData[6])
            value8.text = String(format: "%d", locale: NSLocale.currentLocale(), motorData[7])
            slider8.value = Float(motorData[7])
        }
    }
    
    private func sendMotorData() {
        if vehicle is MSPVehicle {
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
}
