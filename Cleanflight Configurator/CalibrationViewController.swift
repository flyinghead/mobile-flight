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
import Firebase

class CalibrationViewController: StaticDataTableViewController, MSPCommandSender {
    static let VTXSmartAudioPowers = [ "25 mW", "200 mW", "500 mW", "800 mW" ]
    static let VTXTrampPowers = [ "25 mW", "100 mW", "200 mW", "400 mW", "600 mW" ]
    
    let CfGreen = UIColor(hex6: 0x52AE06)
    
    @IBOutlet weak var sensorGyroImg: UIImageView!
    @IBOutlet weak var sensorAccImg: UIImageView!
    @IBOutlet weak var sensorMagImg: UIImageView!
    @IBOutlet weak var sensorBaroImg: UIImageView!
    @IBOutlet weak var sensorGpsImg: UIImageView!
    @IBOutlet weak var sensorSonarImg: UIImageView!
    @IBOutlet weak var sensorPitotImg: UIImageView!
    @IBOutlet weak var sensorFlowImg: UIImageView!
    @IBOutlet var inavSensorCells: [UITableViewCell]!
    
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
    
    @IBOutlet var vtxCells: [UITableViewCell]!
    @IBOutlet weak var vtxBandPicker: StepperPicker!
    @IBOutlet weak var vtxChannelStepper: StepperWithLabel!
    @IBOutlet weak var vtxPowerPicker: StepperPicker!
    @IBOutlet weak var vtxPitModeSwitch: UISwitch!
    
    var metarTimer: NSTimer?
    var reportIndex = 0
    
    let AccelerationCalibDuration = 2.0
    let MagnetometerCalibDuration = 30.0
    
    var calibrationStart: NSDate?
    
    var flightModeEventHandler: Disposable?
    var sensorStatusEventHandler: Disposable?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hideSectionsWithHiddenRows = true
        let config = Configuration.theConfig
        
        if config.isINav {
            cell(accTrimCell, setHidden: true)
            reloadDataAnimated(false)
        } else {
            cells(inavSensorCells, setHidden: true)
            accTrimSaveButton.layer.borderColor = accTrimSaveButton.tintColor.CGColor
        
            accTrimPitchStepper.minimumValue = -100
            accTrimRollStepper.minimumValue = -100
        }
        calAccView.layer.borderColor = calAccView.tintColor.CGColor
        calMagView.layer.borderColor = calMagView.tintColor.CGColor
        enableAccCalibration(config.isAccelerometerActive())
        enableMagCalibration(config.isMagnetometerActive())
        
        vtxBandPicker.labels =  [ "Boscam A", "Boscam B", "Boscam E", "FatShark", "RaceBand" ]
        vtxChannelStepper.minimumValue = 0
        vtxChannelStepper.maximumValue = 7
        vtxChannelStepper.labelFormatter = { value in
            return String(Int(value) + 1)
        }
        vtxPowerPicker.labels = CalibrationViewController.VTXTrampPowers
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
        
        sensorStatusEventHandler = msp.sensorStatusEvent.addHandler(self, handler: CalibrationViewController.sensorStatusChanged)
        sensorStatusChanged()
        appDelegate.addMSPCommandSender(self)
       
        flightModeEventHandler = msp.flightModeEvent.addHandler(self, handler: CalibrationViewController.flightModeChanged)
        flightModeChanged()
        
        MetarManager.instance.addObserver(self, selector: #selector(metarUpdated))
        metarUpdated()
        
        metarTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(metarTimerFired), userInfo: nil, repeats: true)
        
        if VTXConfig.theVTXConfig.deviceType <= 0 {
            cells(vtxCells, setHidden: true)
            reloadDataAnimated(false)
        }
        fetchVtxConfig()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
      
        sensorStatusEventHandler?.dispose()
        appDelegate.removeMSPCommandSender(self)
        flightModeEventHandler?.dispose()
        
        MetarManager.instance.removeObserver(self)
        
        metarTimer?.invalidate()
        metarTimer = nil
    }
    
    func flightModeChanged() {
        let config = Configuration.theConfig
        
        let armed = Settings.theSettings.armed
        self.enableAccCalibration(!armed && config.isAccelerometerActive())
        self.enableMagCalibration(!armed && config.isMagnetometerActive())
    }
    
    private func setINavSensorStatus(img: UIImageView, sensor: INavSensorStatus) {
        let color: UIColor?
        switch sensor {
        case .Known(let intern ):
            switch intern {
            case .Healthy:
                color = CfGreen
            case .Unhealthy, .Unavailable:
                color = UIColor.redColor()
            case .None:
                color = UIColor.lightGrayColor()
            }
        case .Unknown:
            color = UIColor.orangeColor()
        }
        img.tintColor = color
    }
    
    func sensorStatusChanged() {
        let config = Configuration.theConfig
        if config.isINav {
            let inavConfig = INavConfig.theINavConfig
            setINavSensorStatus(sensorGyroImg, sensor: inavConfig.gyroStatus)
            setINavSensorStatus(sensorAccImg, sensor: inavConfig.accStatus)
            setINavSensorStatus(sensorBaroImg, sensor: inavConfig.baroStatus)
            setINavSensorStatus(sensorMagImg, sensor: inavConfig.magStatus)
            setINavSensorStatus(sensorGpsImg, sensor: inavConfig.gpsStatus)
            setINavSensorStatus(sensorSonarImg, sensor: inavConfig.sonarStatus)
            setINavSensorStatus(sensorPitotImg, sensor: inavConfig.pitotStatus)
            setINavSensorStatus(sensorFlowImg, sensor: inavConfig.flowStatus)
            if let tabItems = tabBarController?.tabBar.items {
                if tabBarController?.selectedViewController === self {
                    tabItems[tabBarController!.selectedIndex].badgeValue = inavConfig.hardwareHealthy ? "" : "!"
                }
            }
        } else {
            sensorGyroImg.tintColor = CfGreen
            sensorAccImg.tintColor = config.activeSensors & 1 != 0 ? CfGreen : UIColor.lightGrayColor()
            sensorBaroImg.tintColor = config.activeSensors & 2 != 0 ? CfGreen : UIColor.lightGrayColor()
            sensorMagImg.tintColor = config.activeSensors & 4 != 0 ? CfGreen : UIColor.lightGrayColor()
            sensorGpsImg.tintColor = config.activeSensors & 8 != 0 ? CfGreen : UIColor.lightGrayColor()
            sensorSonarImg.tintColor = config.activeSensors & 16 != 0 ? CfGreen : UIColor.lightGrayColor()
        }
    }

    func sendMSPCommands() {
        let config = Configuration.theConfig
        if config.isINav {
            msp.sendMessage(.MSP_SENSOR_STATUS, data: nil)
        }
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
        appDelegate.startTimer()
    }
    
    private func stopTimer() {
        appDelegate.stopTimer()
    }
    
    @IBAction func calibrateAccelerometer(sender: AnyObject) {
        let alertController = UIAlertController(title: "Accelerometer Calibration", message: "Place the aircraft on a flat leveled surface and do not move it", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Start", style: UIAlertActionStyle.Default, handler: { alertController in
            self.stopTimer()
            Analytics.logEvent("calibrate_acc", parameters: nil)

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
            Analytics.logEvent("calibrate_mag", parameters: nil)
            
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
        Analytics.logEvent("acc_trim_saved", parameters: nil)
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
    
    private func fetchVtxConfig() {
        // FIXME Not sure that data can be read from the VTX in most cases. It seems that band/channel/power are reset to default
        // every time. Check how the OSD "CMS" menu works.
        if Configuration.theConfig.isApiVersionAtLeast("1.31") {
            msp.sendMessage(.MSP_VTX_CONFIG, data: nil, retry: 2) { success in
                dispatch_async(dispatch_get_main_queue()) {
                    if success {
                        Analytics.logEvent("load_vtx_config", parameters: nil)
                        self.cells(self.vtxCells, setHidden: false)
                        let vtxConfig = VTXConfig.theVTXConfig
                        self.vtxPowerPicker.labels = vtxConfig.deviceType == 3 ? CalibrationViewController.VTXSmartAudioPowers : CalibrationViewController.VTXTrampPowers
                        self.vtxBandPicker.selectedIndex = vtxConfig.band
                        self.vtxChannelStepper.value = Double(vtxConfig.channel)
                        self.vtxPowerPicker.selectedIndex = vtxConfig.powerIdx
                        self.vtxPitModeSwitch.on = vtxConfig.pitMode
                        self.reloadDataAnimated(false)
                    } else {
                        Analytics.logEvent("load_vtx_config_failed", parameters: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func vtxSaveAction(sender: AnyObject) {
        Analytics.logEvent("save_vtx_config", parameters: nil)
        let vtxConfig = VTXConfig.theVTXConfig
        vtxConfig.band = vtxBandPicker.selectedIndex
        vtxConfig.channel = Int(vtxChannelStepper.value)
        vtxConfig.powerIdx = vtxPowerPicker.selectedIndex
        vtxConfig.pitMode = vtxPitModeSwitch.on
        msp.sendVtxConfig(vtxConfig) { success in
            if success {
                self.fetchVtxConfig()
            } else {
                Analytics.logEvent("save_vtx_config_failed", parameters: nil)
                self.saveFailedError()
            }
            
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
