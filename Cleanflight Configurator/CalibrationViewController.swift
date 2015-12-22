//
//  CalibrationViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 13/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import SVProgressHUD
import MapKit

class CalibrationViewController: UIViewController {
    @IBOutlet weak var calAccButton: UIButton!
    @IBOutlet weak var calMagButton: UIButton!
    @IBOutlet weak var calAccImgButton: UIButton!
    @IBOutlet weak var calMagImgButton: UIButton!
    @IBOutlet weak var accTrimPitchStepper: UIStepper!
    @IBOutlet weak var accTrimRollStepper: UIStepper!
    @IBOutlet weak var accTrimPitchField: UITextField!
    @IBOutlet weak var accTrimRollField: UITextField!

    let AccelerationCalibDuration = 2.0
    let MagnetometerCalibDuration = 30.0
    
    var calibrationStart: NSDate?
    
    var timer: NSTimer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        let config = Configuration.theConfig
        enableAccCalibration(config.isGyroAndAccActive())
        
        enableMagCalibration(config.isMagnetometerActive())
        
        accTrimPitchStepper.minimumValue = -100
        accTrimRollStepper.minimumValue = -100
        
        accTrimPitchStepper.value = Double(config.accelerometerTrimPitch)
        accTrimPitchChanged(accTrimPitchStepper)
        accTrimRollStepper.value = Double(config.accelerometerTrimRoll)
        accTrimRollChanged(accTrimRollStepper)
        
        // TODO Refresh config? We MUST stop data polling during Acc calibration (not sure about Mag)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        startTimer()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startTimer() {
        if (timer == nil) {
            timer = NSTimer.scheduledTimerWithTimeInterval(0.6, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopTimer()
    }
    
    func timerDidFire(timer: NSTimer) {
        msp.sendMessage(.MSP_STATUS, data: nil, retry: 0, callback: { success in
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    let config = Configuration.theConfig
                    
                    let armed = Settings.theSettings.isModeOn(.ARM, forStatus: config.mode)
                    self.enableAccCalibration(!armed && config.isGyroAndAccActive())
                    self.enableMagCalibration(!armed && config.isMagnetometerActive())
                })
            }
        })
    }
    
    func enableAccCalibration(enabled: Bool) {
        calAccButton.enabled = enabled
        calAccImgButton.enabled = calAccButton.enabled
    }

    func enableMagCalibration(enabled: Bool) {
        calMagButton.enabled = enabled
        calMagImgButton.enabled = calMagButton.enabled
    }
    
    @IBAction func calibrateAccelerometer(sender: AnyObject) {
        stopTimer()
        enableAccCalibration(false)
        msp.sendMessage(.MSP_ACC_CALIBRATION, data: nil, retry: 2, callback: { success in
            dispatch_async(dispatch_get_main_queue(), {
                if success {
                    self.calibrationStart = NSDate()
                    self.calibrateAccProgress(nil)   // To show the progressHUD
                    NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "calibrateAccProgress:", userInfo: nil, repeats: true)
                } else {
                    SVProgressHUD.showErrorWithStatus("Cannot start calibration")
                    self.enableAccCalibration(true)
                    self.startTimer()
                }
            })
        })
    }
    
    func calibrateAccProgress(timer: NSTimer?) {
        let elapsed = -calibrationStart!.timeIntervalSinceNow
        if elapsed >= AccelerationCalibDuration {
            SVProgressHUD.dismiss()
            enableAccCalibration(true)
            timer!.invalidate()
            self.startTimer()
        }
        else {
            SVProgressHUD.showProgress(Float(elapsed / AccelerationCalibDuration), status: "Calibrating Accelerometer", maskType: .Clear)
        }
    }
    
    @IBAction func calibrateMagnetometer(sender: AnyObject) {
        stopTimer()
        enableMagCalibration(false)
        msp.sendMessage(.MSP_MAG_CALIBRATION, data: nil, retry: 2, callback: { success in
            dispatch_async(dispatch_get_main_queue(), {
                if success {
                    self.calibrationStart = NSDate()
                    self.calibrateMagProgress(nil)   // To show the progressHUD
                    NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "calibrateMagProgress:", userInfo: nil, repeats: true)
                } else {
                    SVProgressHUD.showErrorWithStatus("Cannot start calibration")
                    self.enableMagCalibration(true)
                    self.startTimer()
                }
            })
        })
    }
    
    func calibrateMagProgress(timer: NSTimer?) {
        let elapsed = -calibrationStart!.timeIntervalSinceNow
        if elapsed >= MagnetometerCalibDuration {
            SVProgressHUD.dismiss()
            enableMagCalibration(true)
            timer!.invalidate()
            self.startTimer()
        }
        else {
            SVProgressHUD.showProgress(Float(elapsed / MagnetometerCalibDuration), status: "Calibrating Magnetometer", maskType: .Clear)
        }
    }
    @IBAction func accTrimPitchChanged(sender: AnyObject) {
        accTrimPitchField.text = String(format: "%.0f", locale: NSLocale.currentLocale(), accTrimPitchStepper.value)
    }
    
    @IBAction func accTrimRollChanged(sender: AnyObject) {
        accTrimRollField.text = String(format: "%.0f", locale: NSLocale.currentLocale(), accTrimRollStepper.value)
    }
    
    @IBAction func accTrimSaveAction(sender: AnyObject) {
        let config = Configuration.theConfig
        config.accelerometerTrimPitch = Int(accTrimPitchStepper.value)
        config.accelerometerTrimRoll = Int(accTrimRollStepper.value)
        let msp = self.msp
        msp.sendSetAccTrim(config, callback: { success in
            if success {
                msp.sendMessage(.MSP_EEPROM_WRITE, data: nil, retry: 2, callback: nil)
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    SVProgressHUD.showErrorWithStatus("Save failed")
                })
            }
        })
    }
    
    @IBAction func findMe(sender: AnyObject) {
        let gpsData = GPSData.theGPSData
        if gpsData.lastKnownGoodTimestamp != nil {
            let coordinates = CLLocationCoordinate2D(latitude: gpsData.lastKnownGoodLatitude, longitude: gpsData.lastKnownGoodLongitude)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinates, addressDictionary: nil))
            let df = NSDateFormatter()
            df.timeStyle = .MediumStyle
            df.dateStyle = .NoStyle
            mapItem.name = String(format:"Aircraft at %@", df.stringFromDate(gpsData.lastKnownGoodTimestamp!))
            mapItem.openInMapsWithLaunchOptions(nil)
        } else {
            SVProgressHUD.showErrorWithStatus("No known GPS location")
        }
    }
}
