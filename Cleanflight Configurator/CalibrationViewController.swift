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

class CalibrationViewController: StaticDataTableViewController, FlightDataListener {
    @IBOutlet weak var calAccButton: UIButton!
    @IBOutlet weak var calMagButton: UIButton!
    @IBOutlet weak var calAccImgButton: UIButton!
    @IBOutlet weak var calMagImgButton: UIButton!
    @IBOutlet weak var accTrimPitchStepper: UIStepper!
    @IBOutlet weak var accTrimRollStepper: UIStepper!
    @IBOutlet weak var accTrimPitchField: UITextField!
    @IBOutlet weak var accTrimRollField: UITextField!

    @IBOutlet weak var calAccView: UIView!
    @IBOutlet weak var calMagView: UIView!
    @IBOutlet weak var accTrimSaveButton: UIButton!
    
    @IBOutlet weak var metarTableCell: UITableViewCell!
    @IBOutlet weak var metarDateLabel: UILabel!
    @IBOutlet weak var metarSiteLabel: UILabel!
    @IBOutlet weak var metarSiteDescription: UILabel!
    @IBOutlet weak var metarWind: UILabel!
    @IBOutlet weak var metarTemperature: UILabel!
    @IBOutlet weak var metarVisibility: UILabel!
    @IBOutlet weak var metarDescription: UILabel!
    @IBOutlet weak var metarWeatherImage: UIImageView!
    
    @IBOutlet weak var accTrimCell: UITableViewCell!
    
    var metarTimer: NSTimer?
    var reportIndex = 0
    
    let AccelerationCalibDuration = 2.0
    let MagnetometerCalibDuration = 30.0
    
    var calibrationStart: NSDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hideSectionsWithHiddenRows = true
        let config = Configuration.theConfig
        
        if config.isINav {
            cell(accTrimCell, setHidden: true)
            reloadDataAnimated(true)
        } else {
            accTrimSaveButton.layer.borderColor = accTrimSaveButton.tintColor.CGColor
        
            accTrimPitchStepper.minimumValue = -100
            accTrimRollStepper.minimumValue = -100
        }
        calAccView.layer.borderColor = calAccView.tintColor.CGColor
        calMagView.layer.borderColor = calMagView.tintColor.CGColor
        enableAccCalibration(config.isGyroAndAccActive())
        enableMagCalibration(config.isMagnetometerActive())
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if !Configuration.theConfig.isINav {
            msp.sendMessage(.MSP_ACC_TRIM, data: nil, retry: 2) { success in
                dispatch_async(dispatch_get_main_queue()) {
                    let misc = Misc.theMisc
                    self.accTrimPitchStepper.value = Double(misc.accelerometerTrimPitch)
                    self.accTrimPitchChanged(self.accTrimPitchStepper)
                    self.accTrimRollStepper.value = Double(misc.accelerometerTrimRoll)
                    self.accTrimRollChanged(self.accTrimRollStepper)
                }
            }
        }
        
        msp.addDataListener(self)
        
        MetarManager.instance.addObserver(self, selector: #selector(metarUpdated))
        
        metarUpdated()
        
        metarTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(metarTimerFired), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        msp.removeDataListener(self)
        
        MetarManager.instance.removeObserver(self)
        
        metarTimer?.invalidate()
        metarTimer = nil
    }
    
    func receivedData() {
        let config = Configuration.theConfig
        
        let armed = Settings.theSettings.armed
        self.enableAccCalibration(!armed && config.isGyroAndAccActive())
        self.enableMagCalibration(!armed && config.isMagnetometerActive())
    }
    
    func enableAccCalibration(enabled: Bool) {
        calAccButton.enabled = enabled
        calAccImgButton.enabled = calAccButton.enabled
    }

    func enableMagCalibration(enabled: Bool) {
        calMagButton.enabled = enabled
        calMagImgButton.enabled = calMagButton.enabled
    }
    
    private func startTimer() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.startTimer()
    }
    
    private func stopTimer() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.stopTimer()
    }
    
    @IBAction func calibrateAccelerometer(sender: AnyObject) {
        let alertController = UIAlertController(title: "Accelerometer Calibration", message: "Place the aircraft on a flat leveled surface and do not move it", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Start", style: UIAlertActionStyle.Default, handler: { alertController in
            self.stopTimer()
            
            self.enableAccCalibration(false)
            self.msp.sendMessage(.MSP_ACC_CALIBRATION, data: nil, retry: 2, callback: { success in
                dispatch_async(dispatch_get_main_queue(), {
                    if success {
                        self.calibrationStart = NSDate()
                        self.calibrateAccProgress(nil)   // To show the progressHUD
                        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(CalibrationViewController.calibrateAccProgress(_:)), userInfo: nil, repeats: true)
                    } else {
                        SVProgressHUD.showErrorWithStatus("Cannot start calibration")
                        self.enableAccCalibration(true)
                        self.startTimer()
                        
                    }
                })
            })
        }))
        alertController.popoverPresentationController?.sourceView = sender as? UIView
        presentViewController(alertController, animated: true, completion: nil)

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
            SVProgressHUD.showProgress(Float(elapsed / AccelerationCalibDuration), status: "Calibrating Accelerometer", maskType: .Black)
        }
    }
    
    @IBAction func calibrateMagnetometer(sender: AnyObject) {
        let alertController = UIAlertController(title: "Compass Calibration", message: "You have 30 seconds to rotate the aircraft around all axes: yaw, pitch and roll", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Start", style: UIAlertActionStyle.Default, handler: { alertController in
            self.stopTimer()
            self.enableMagCalibration(false)
            self.msp.sendMessage(.MSP_MAG_CALIBRATION, data: nil, retry: 2, callback: { success in
                dispatch_async(dispatch_get_main_queue(), {
                    if success {
                        self.calibrationStart = NSDate()
                        self.calibrateMagProgress(nil)   // To show the progressHUD
                        NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(CalibrationViewController.calibrateMagProgress(_:)), userInfo: nil, repeats: true)
                    } else {
                        SVProgressHUD.showErrorWithStatus("Cannot start calibration")
                        self.enableMagCalibration(true)
                        self.startTimer()
                        
                    }
                })
            })
        }))
        alertController.popoverPresentationController?.sourceView = sender as? UIView
        presentViewController(alertController, animated: true, completion: nil)
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
            SVProgressHUD.showProgress(Float(elapsed / MagnetometerCalibDuration), status: "Calibrating Magnetometer", maskType: .Black)
        }
    }
    @IBAction func accTrimPitchChanged(sender: AnyObject) {
        accTrimPitchField.text = formatNumber(accTrimPitchStepper.value, precision: 0)
    }
    
    @IBAction func accTrimRollChanged(sender: AnyObject) {
        accTrimRollField.text = formatNumber(accTrimRollStepper.value, precision: 0)
    }
    
    @IBAction func accTrimSaveAction(sender: AnyObject) {
        let misc = Misc.theMisc
        misc.accelerometerTrimPitch = Int(accTrimPitchStepper.value)
        misc.accelerometerTrimRoll = Int(accTrimRollStepper.value)
        let msp = self.msp
        msp.sendSetAccTrim(misc) { success in
            if success {
                msp.sendMessage(.MSP_EEPROM_WRITE, data: nil, retry: 2) { success in
                    if success {
                        dispatch_async(dispatch_get_main_queue(), {
                            SVProgressHUD.showSuccessWithStatus("Settings saved")
                        })
                    } else {
                        self.saveFailedError()
                    }
                }
            } else {
                self.saveFailedError()
            }
        }
    }
    
    private func saveFailedError() {
        dispatch_async(dispatch_get_main_queue(), {
            SVProgressHUD.showErrorWithStatus("Save failed")
        })
    }
    
    @objc
    private func metarUpdated() {
        if let reports = MetarManager.instance.reports where reports.count > 0 {
            if reportIndex >= reports.count {
                reportIndex = 0
            }
            let report = reports[reportIndex]
            metarDateLabel.text = String(format: "Updated %@", report.observationTimeFromNow)
            metarSiteLabel.text = report.site
            metarSiteDescription.text = String(format: "%@ %@", formatDistance(report.distance), compassPoint(report.heading))
            if report.windSpeed != nil && report.windDirection != nil {
                metarWind.text = String(format: "%@ %@ %@", compassPoint(report.windDirection!), formatSpeed(report.windSpeed! * 1.852), report.windGust != nil ? String(format: " gusts %@", formatSpeed(report.windGust! * 1.852)) : "")
            } else {
                metarWind.text = ""
            }
            metarTemperature.text = report.temperature != nil ? formatTemperature(report.temperature!) : ""
            metarVisibility.text = report.visibility != nil ? formatDistance(report.visibility! * 1852) : ""
            metarDescription.text = report.description
            switch report.weatherLevel {
            case .Overcast:
                metarWeatherImage.image = UIImage(named: "cloud")
            case .Clear:
                metarWeatherImage.image = UIImage(named: "sun")
            case .PartlyCloudy:
                metarWeatherImage.image = UIImage(named: "partlycloudy")
            case .Rain:
                metarWeatherImage.image = UIImage(named: "rain")
            case .Snow:
                metarWeatherImage.image = UIImage(named: "snow")
            case .Thunderstorm:
                metarWeatherImage.image = UIImage(named: "storm")
            }
        } else {
            metarDateLabel.text = ""
            metarSiteLabel.text = "No information available"
            metarSiteDescription.text = ""
            metarWind.text = ""
            metarTemperature.text = ""
            metarVisibility.text = ""
            metarDescription.text = ""
            metarWeatherImage.image = UIImage(named: "sun")
        }
    }
    
    @objc
    private func metarTimerFired(timer: NSTimer?) {
        if let reports = MetarManager.instance.reports where reports.count > 1 {
            reportIndex = (reportIndex + 1) % min(MetarManager.instance.reports.count, 3)
            metarUpdated()
            updateCell(metarTableCell)
            reloadTableViewRowAnimation = .Right
            reloadDataAnimated(true)
        }
    }
    
    /*
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
    */
}
