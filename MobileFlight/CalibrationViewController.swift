//
//  CalibrationViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 13/12/15.
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
import SVProgressHUD
import MapKit
import Firebase

class CalibrationViewController: StaticDataTableViewController, MSPCommandSender {
    static let VTXSmartAudioPowers = [ "25 mW", "200 mW", "500 mW", "800 mW" ]
    static let VTXTrampPowers = [ "25 mW", "100 mW", "200 mW", "400 mW", "600 mW" ]
    
    let CfGreen = UIColor(hex6: 0x52AE06)
    let checkmark = UIImage(named: "checkmark")
    let crossmark = UIImage(named: "crossmark")
    
    @IBOutlet weak var sensorGyroImg: UIImageView!
    @IBOutlet weak var sensorAccImg: UIImageView!
    @IBOutlet weak var sensorMagImg: UIImageView!
    @IBOutlet weak var sensorBaroImg: UIImageView!
    @IBOutlet weak var sensorGpsImg: UIImageView!
    @IBOutlet weak var sensorSonarImg: UIImageView!
    @IBOutlet weak var sensorPitotImg: UIImageView!
    @IBOutlet weak var sensorFlowImg: UIImageView!
    @IBOutlet var inavSensorCells: [UITableViewCell]!
    
    @IBOutlet weak var cycleTimeLabel: UILabel!
    @IBOutlet weak var cpuLoadLabel: UILabel!
    
    @IBOutlet weak var uavLevelledImg: UIImageView!
    @IBOutlet weak var runtimeCalibImg: UIImageView!
    @IBOutlet weak var cpuLoadImg: UIImageView!
    @IBOutlet weak var navigationSafeImg: UIImageView!
    @IBOutlet weak var compassCalibImg: UIImageView!
    @IBOutlet weak var accCalibImg: UIImageView!
    @IBOutlet weak var hardwareHealthImg: UIImageView!
    
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
    
    var metarTimer: Timer?
    var reportIndex = 0
    
    let AccelerationCalibDuration = 2.0
    let MagnetometerCalibDuration = 30.0
    
    var calibrationStart: Date?
    
    var flightModeEventHandler: Disposable?
    var sensorStatusEventHandler: Disposable?
    var statusEventHandler: Disposable?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hideSectionsWithHiddenRows = true
        let config = Configuration.theConfig
        
        if config.isINav {
            cell(accTrimCell, setHidden: true)
            reloadData(animated: false)
        } else {
            cells(inavSensorCells, setHidden: true)
            accTrimSaveButton.layer.borderColor = accTrimSaveButton.tintColor.cgColor
        
            accTrimPitchStepper.minimumValue = -100
            accTrimRollStepper.minimumValue = -100
        }
        calAccView.layer.borderColor = calAccView.tintColor.cgColor
        calMagView.layer.borderColor = calMagView.tintColor.cgColor
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !Configuration.theConfig.isINav {
            msp.sendMessage(.msp_ACC_TRIM, data: nil, retry: 2) { success in
                DispatchQueue.main.async {
                    let misc = Misc.theMisc
                    self.accTrimPitchStepper.value = Double(misc.accelerometerTrimPitch)
                    self.accTrimPitchChanged(self.accTrimPitchStepper)
                    self.accTrimRollStepper.value = Double(misc.accelerometerTrimRoll)
                    self.accTrimRollChanged(self.accTrimRollStepper)
                }
            }
        }
        
        statusEventHandler = msp.statusEvent.addHandler(self, handler: CalibrationViewController.statusEventChanged)
        
        sensorStatusEventHandler = msp.sensorStatusEvent.addHandler(self, handler: CalibrationViewController.sensorStatusChanged)
        sensorStatusChanged()
        appDelegate.addMSPCommandSender(self)
       
        flightModeEventHandler = msp.flightModeEvent.addHandler(self, handler: CalibrationViewController.flightModeChanged)
        flightModeChanged()
        
        MetarManager.instance.addObserver(self, selector: #selector(metarUpdated))
        metarUpdated()
        
        metarTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(metarTimerFired), userInfo: nil, repeats: true)
        
        if VTXConfig.theVTXConfig.deviceType <= 0 {
            cells(vtxCells, setHidden: true)
            reloadData(animated: false)
        }
        fetchVtxConfig()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
      
        statusEventHandler?.dispose()
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
    
    fileprivate func setINavSensorStatus(_ img: UIImageView, sensor: INavSensorStatus) {
        let color: UIColor?
        switch sensor {
        case .known(let intern ):
            switch intern {
            case .healthy:
                color = CfGreen
            case .unhealthy, .unavailable:
                color = UIColor.red
            case .none:
                color = UIColor.lightGray
            }
        case .unknown:
            color = UIColor.orange
        }
        img.tintColor = color
    }
    
    func statusEventChanged() {
        let config = Configuration.theConfig
        cycleTimeLabel.text = String(config.cycleTime)
        cpuLoadLabel.text = String(format:"%d%%", config.systemLoad)
    }
    
    func sensorStatusChanged() {
        let config = Configuration.theConfig
        if config.isINav {
            let inavState = INavState.theINavState
            setINavSensorStatus(sensorGyroImg, sensor: inavState.gyroStatus)
            setINavSensorStatus(sensorAccImg, sensor: inavState.accStatus)
            setINavSensorStatus(sensorBaroImg, sensor: inavState.baroStatus)
            setINavSensorStatus(sensorMagImg, sensor: inavState.magStatus)
            setINavSensorStatus(sensorGpsImg, sensor: inavState.gpsStatus)
            setINavSensorStatus(sensorSonarImg, sensor: inavState.sonarStatus)
            setINavSensorStatus(sensorPitotImg, sensor: inavState.pitotStatus)
            setINavSensorStatus(sensorFlowImg, sensor: inavState.flowStatus)

            uavLevelledImg.image = inavState.armingFlags.contains(.NotLevel) ? crossmark : checkmark
            runtimeCalibImg.image = inavState.armingFlags.contains(.SensorsCalibrating) ? crossmark : checkmark
            cpuLoadImg.image = inavState.armingFlags.contains(.SystemOverloaded) ? crossmark : checkmark
            navigationSafeImg.image = inavState.armingFlags.contains(.NavigationSafety) ? crossmark : checkmark
            compassCalibImg.image = inavState.armingFlags.contains(.CompassNotCalibrated) ? crossmark : checkmark
            accCalibImg.image = inavState.armingFlags.contains(.AccNotCalibrated) ? crossmark : checkmark
            hardwareHealthImg.image = inavState.armingFlags.contains(.HardwareFailure) ? crossmark : checkmark
            
            if let tabItems = tabBarController?.tabBar.items {
                if tabBarController?.selectedViewController === self {
                    tabItems[tabBarController!.selectedIndex].badgeValue = (inavState.hardwareHealthy && !inavState.armingFlags.contains(.PreventArming)) ? nil : "!"
                }
            }
        } else {
            sensorGyroImg.tintColor = config.isGyroActive() ? CfGreen : UIColor.lightGray
            sensorAccImg.tintColor = config.isAccelerometerActive() ? CfGreen : UIColor.lightGray
            sensorBaroImg.tintColor = config.isBarometerActive() ? CfGreen : UIColor.lightGray
            sensorMagImg.tintColor = config.isMagnetometerActive() ? CfGreen : UIColor.lightGray
            sensorGpsImg.tintColor = config.isGPSActive() ? CfGreen : UIColor.lightGray
            sensorSonarImg.tintColor = config.isSonarActive() ? CfGreen : UIColor.lightGray
        }
    }

    func sendMSPCommands() {
        let config = Configuration.theConfig
        if config.isINav {
            msp.sendMessage(.msp_SENSOR_STATUS, data: nil)
        }
    }

    func enableAccCalibration(_ enabled: Bool) {
        calAccButton.isEnabled = enabled
        calAccImgButton.isEnabled = calAccButton.isEnabled
    }

    func enableMagCalibration(_ enabled: Bool) {
        calMagButton.isEnabled = enabled
        calMagImgButton.isEnabled = calMagButton.isEnabled
    }
    
    fileprivate func startTimer() {
        appDelegate.startTimer()
    }
    
    fileprivate func stopTimer() {
        appDelegate.stopTimer()
    }
    
    @IBAction func calibrateAccelerometer(_ sender: Any) {
        let alertController = UIAlertController(title: "Accelerometer Calibration", message: "Place the aircraft on a flat leveled surface and do not move it", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Start", style: UIAlertActionStyle.default, handler: { alertController in
            self.stopTimer()
            Analytics.logEvent("calibrate_acc", parameters: nil)

            self.enableAccCalibration(false)
            self.msp.sendMessage(.msp_ACC_CALIBRATION, data: nil, retry: 2, callback: { success in
                DispatchQueue.main.async(execute: {
                    if success {
                        self.calibrationStart = Date()
                        self.calibrateAccProgress(nil)   // To show the progressHUD
                        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(CalibrationViewController.calibrateAccProgress(_:)), userInfo: nil, repeats: true)
                    } else {
                        SVProgressHUD.showError(withStatus: "Cannot start calibration")
                        self.enableAccCalibration(true)
                        self.startTimer()
                        
                    }
                })
            })
        }))
        alertController.popoverPresentationController?.sourceView = sender as? UIView
        present(alertController, animated: true, completion: nil)

    }
    
    func calibrateAccProgress(_ timer: Timer?) {
        let elapsed = -calibrationStart!.timeIntervalSinceNow
        if elapsed >= AccelerationCalibDuration {
            SVProgressHUD.dismiss()
            enableAccCalibration(true)
            timer!.invalidate()
            self.startTimer()
        }
        else {
            SVProgressHUD.showProgress(Float(elapsed / AccelerationCalibDuration), status: "Calibrating Accelerometer", maskType: .black)
        }
    }
    
    @IBAction func calibrateMagnetometer(_ sender: Any) {
        let alertController = UIAlertController(title: "Compass Calibration", message: "You have 30 seconds to rotate the aircraft around all axes: yaw, pitch and roll", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Start", style: UIAlertActionStyle.default, handler: { alertController in
            self.stopTimer()
            Analytics.logEvent("calibrate_mag", parameters: nil)
            
            self.enableMagCalibration(false)
            self.msp.sendMessage(.msp_MAG_CALIBRATION, data: nil, retry: 2, callback: { success in
                DispatchQueue.main.async(execute: {
                    if success {
                        self.calibrationStart = Date()
                        self.calibrateMagProgress(nil)   // To show the progressHUD
                        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(CalibrationViewController.calibrateMagProgress(_:)), userInfo: nil, repeats: true)
                    } else {
                        SVProgressHUD.showError(withStatus: "Cannot start calibration")
                        self.enableMagCalibration(true)
                        self.startTimer()
                        
                    }
                })
            })
        }))
        alertController.popoverPresentationController?.sourceView = sender as? UIView
        present(alertController, animated: true, completion: nil)
    }
    
    func calibrateMagProgress(_ timer: Timer?) {
        let elapsed = -calibrationStart!.timeIntervalSinceNow
        if elapsed >= MagnetometerCalibDuration {
            SVProgressHUD.dismiss()
            enableMagCalibration(true)
            timer!.invalidate()
            self.startTimer()
        }
        else {
            SVProgressHUD.showProgress(Float(elapsed / MagnetometerCalibDuration), status: "Calibrating Magnetometer", maskType: .black)
        }
    }
    @IBAction func accTrimPitchChanged(_ sender: Any) {
        accTrimPitchField.text = formatNumber(accTrimPitchStepper.value, precision: 0)
    }
    
    @IBAction func accTrimRollChanged(_ sender: Any) {
        accTrimRollField.text = formatNumber(accTrimRollStepper.value, precision: 0)
    }
    
    @IBAction func accTrimSaveAction(_ sender: Any) {
        let misc = Misc.theMisc
        misc.accelerometerTrimPitch = Int(accTrimPitchStepper.value)
        misc.accelerometerTrimRoll = Int(accTrimRollStepper.value)
        let msp = self.msp
        Analytics.logEvent("acc_trim_saved", parameters: nil)
        msp.sendSetAccTrim(misc) { success in
            if success {
                msp.sendMessage(.msp_EEPROM_WRITE, data: nil, retry: 2) { success in
                    if success {
                        DispatchQueue.main.async(execute: {
                            SVProgressHUD.showSuccess(withStatus: "Settings saved")
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
    
    fileprivate func saveFailedError() {
        DispatchQueue.main.async(execute: {
            SVProgressHUD.showError(withStatus: "Save failed")
        })
    }
    
    @objc
    fileprivate func metarUpdated() {
        if let reports = MetarManager.instance.reports, reports.count > 0 {
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
            case .overcast:
                metarWeatherImage.image = UIImage(named: "cloud")
            case .clear:
                metarWeatherImage.image = UIImage(named: "sun")
            case .partlyCloudy:
                metarWeatherImage.image = UIImage(named: "partlycloudy")
            case .rain:
                metarWeatherImage.image = UIImage(named: "rain")
            case .snow:
                metarWeatherImage.image = UIImage(named: "snow")
            case .thunderstorm:
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
    fileprivate func metarTimerFired(_ timer: Timer?) {
        if let reports = MetarManager.instance.reports, reports.count > 1 {
            reportIndex = (reportIndex + 1) % min(MetarManager.instance.reports.count, 3)
            metarUpdated()
            update(metarTableCell)
            reloadTableViewRowAnimation = .right
            reloadData(animated: true)
        }
    }
    
    fileprivate func fetchVtxConfig() {
        // FIXME Not sure that data can be read from the VTX in most cases. It seems that band/channel/power are reset to default
        // every time. Check how the OSD "CMS" menu works.
        let config = Configuration.theConfig
        if config.isApiVersionAtLeast("1.31") && !config.isINav {
            msp.sendMessage(.msp_VTX_CONFIG, data: nil, retry: 2) { success in
                DispatchQueue.main.async {
                    if success {
                        Analytics.logEvent("load_vtx_config", parameters: nil)
                        self.cells(self.vtxCells, setHidden: false)
                        let vtxConfig = VTXConfig.theVTXConfig
                        self.vtxPowerPicker.labels = vtxConfig.deviceType == 3 ? CalibrationViewController.VTXSmartAudioPowers : CalibrationViewController.VTXTrampPowers
                        self.vtxBandPicker.selectedIndex = vtxConfig.band
                        self.vtxChannelStepper.value = Double(vtxConfig.channel)
                        self.vtxPowerPicker.selectedIndex = vtxConfig.powerIdx
                        self.vtxPitModeSwitch.isOn = vtxConfig.pitMode
                        self.reloadData(animated: false)
                    } else {
                        Analytics.logEvent("load_vtx_config_failed", parameters: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func vtxSaveAction(_ sender: Any) {
        Analytics.logEvent("save_vtx_config", parameters: nil)
        let vtxConfig = VTXConfig.theVTXConfig
        vtxConfig.band = vtxBandPicker.selectedIndex
        vtxConfig.channel = Int(vtxChannelStepper.value)
        vtxConfig.powerIdx = vtxPowerPicker.selectedIndex
        vtxConfig.pitMode = vtxPitModeSwitch.isOn
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
    @IBAction func findMe(sender: Any) {
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
