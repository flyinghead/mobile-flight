//
//  TelemetryViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 07/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import CoreLocation

class TelemetryView : UIView {
    @IBOutlet weak var attitudeIndicator: AttitudeIndicator!
    @IBOutlet weak var headingIndicator: HeadingIndicator!
    @IBOutlet weak var voltLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var gpsFixImage: UIImageView!
    @IBOutlet weak var modeArmedLabel: UILabel!
    @IBOutlet weak var modeAngleLabel: UILabel!
    @IBOutlet weak var modeHorizonLabel: UILabel!
    @IBOutlet weak var modeBaroLabel: UILabel!
    @IBOutlet weak var modeGpsHoldLabel: UILabel!
    @IBOutlet weak var modeGpsHomeLabel: UILabel!
    @IBOutlet weak var modeMagLabel: UILabel!
    @IBOutlet weak var modeOsdLabel: UILabel!
    @IBOutlet weak var modeBeeperLabel: UILabel!
    
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var distanceToHomeLabel: UILabel!
    @IBOutlet weak var gyroSensor: UIImageView!
    @IBOutlet weak var accSensor: UIImageView!
    @IBOutlet weak var magSensor: UIImageView!
    @IBOutlet weak var baroSensor: UIImageView!
    @IBOutlet weak var gpsSensor: UIImageView!
    @IBOutlet weak var sonarSensor: UIImageView!
    
}

class TelemetryViewController: UIViewController, FlightDataListener, CLLocationManagerDelegate {
    let redled = UIImage(named: "redled")
    let greenled = UIImage(named: "greenled")
    
    let gyroSensorOn = UIImage(named: "sensor_gyro_on")
    let gyroSensorOff = UIImage(named: "sensor_gyro_off")
    let accSensorOn = UIImage(named: "sensor_acc_on")
    let accSensorOff = UIImage(named: "sensor_acc_off")
    let magSensorOn = UIImage(named: "sensor_mag_on")
    let magSensorOff = UIImage(named: "sensor_mag_off")
    let baroSensorOn = UIImage(named: "sensor_baro_on")
    let baroSensorOff = UIImage(named: "sensor_baro_off")
    let gpsSensorOn = UIImage(named: "sensor_sat_on")
    let gpsSensorOff = UIImage(named: "sensor_sat_off")
    let sonarSensorOn = UIImage(named: "sensor_sonar_on")
    let sonarSensorOff = UIImage(named: "sensor_sonar_off")
    
    @IBOutlet weak var landscapeView: TelemetryView!
    @IBOutlet weak var portraitView: TelemetryView!
    var theView: TelemetryView!
    
    let veryFastTimerInterval = 0.1     // 100ms by default. Latency for MSP_ATTITUDE is around 40-70 ms
    var veryFastTimer: NSTimer?
    var fastTimer: NSTimer?
    var slowTimer: NSTimer?
    
    var locationManager: CLLocationManager?
    var lastFollowMeUpdate: NSDate?
    let followMeUpdatePeriod: NSTimeInterval = 2.0      // 2s in ArduPilot MissionPlanner
    
    var isShowingLandscapeView = false
    
    func orientationChanged() {
        let orientation = UIDevice.currentDevice().orientation
        if orientation.isLandscape && !isShowingLandscapeView {
            isShowingLandscapeView = true
            theView = landscapeView
            portraitView.hidden = true
            landscapeView.hidden = false
        } else if orientation == .Portrait && isShowingLandscapeView {
            isShowingLandscapeView = false
            theView = portraitView
            portraitView.hidden = false
            landscapeView.hidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isShowingLandscapeView = false
        theView = portraitView
        orientationChanged()
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationChanged", name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        msp.addDataListener(self)
        
        theView.voltLabel.text = "?"
        theView.rssiLabel.text = "?"
        setModeLabel(theView.modeArmedLabel, on: false)
        setModeLabel(theView.modeAngleLabel, on: false)
        setModeLabel(theView.modeHorizonLabel, on: false)
        setModeLabel(theView.modeBaroLabel, on: false)
        setModeLabel(theView.modeMagLabel, on: false)
        setModeLabel(theView.modeGpsHomeLabel, on: false)
        setModeLabel(theView.modeGpsHoldLabel, on: false)
        setModeLabel(theView.modeBeeperLabel, on: false)
        setModeLabel(theView.modeOsdLabel, on: false)

        theView.altitudeLabel.text = ""
        theView.speedLabel.text = ""
        theView.distanceToHomeLabel.text = ""
        
        theView.gyroSensor.image = gyroSensorOff
        theView.accSensor.image = accSensorOff
        theView.magSensor.image = magSensorOff
        theView.gpsSensor.image = gpsSensorOff
        theView.baroSensor.image = baroSensorOff
        theView.sonarSensor.image = sonarSensorOff
        
    }

    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // For enabled features
        msp.sendMessage(.MSP_BF_CONFIG, data: nil, retry: 2, callback: { success in
            self.msp.sendMessage(.MSP_STATUS, data: nil, retry: 2, callback: { success in
                self.msp.sendMessage(.MSP_MISC, data: nil)
            })
        })
        
        if (veryFastTimer == nil) {
            veryFastTimer = NSTimer.scheduledTimerWithTimeInterval(veryFastTimerInterval, target: self, selector: "veryFastTimerDidFire:", userInfo: nil, repeats: true)
        }
        if (fastTimer == nil) {
            fastTimer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: "fastTimerDidFire:", userInfo: nil, repeats: true)
        }
        if (slowTimer == nil) {
            slowTimer = NSTimer.scheduledTimerWithTimeInterval(0.6, target: self, selector: "slowTimerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        veryFastTimer?.invalidate()
        veryFastTimer = nil
        fastTimer?.invalidate()
        fastTimer = nil
        slowTimer?.invalidate()
        slowTimer = nil
        VoiceMessage.theVoice.stopAlerts()
    }

    func veryFastTimerDidFire(sender: AnyObject) {
        if Settings.theSettings.boxNames != nil {
            msp.sendMessage(.MSP_ATTITUDE, data: nil)
        }
    }
    
    func fastTimerDidFire(sender: AnyObject) {
        if Settings.theSettings.boxNames != nil {
            msp.sendMessage(.MSP_STATUS, data: nil)
            msp.sendMessage(.MSP_ALTITUDE, data: nil)
        }
    }
    
    func slowTimerDidFire(sender: AnyObject) {
        if Settings.theSettings.boxNames != nil {
            msp.sendMessage(.MSP_RAW_GPS, data: nil)
            msp.sendMessage(.MSP_COMP_GPS, data: nil)
            msp.sendMessage(.MSP_ANALOG, data: nil)
        }
    }
    
    func receivedSensorData() {
        let sensorData = SensorData.theSensorData
        theView.attitudeIndicator.roll = sensorData.rollAngle
        theView.attitudeIndicator.pitch = sensorData.pitchAngle
        theView.attitudeIndicator.setNeedsDisplay()
        
        theView.headingIndicator.heading = sensorData.heading
        theView.headingIndicator.setNeedsDisplay()
        
        // Use baro/sonar altitude if present, otherwise use GPS altitude
        let config = Configuration.theConfig
        theView.altitudeLabel.text = formatWithUnit(config.isBarometerActive() || config.isSonarActive() ? sensorData.altitude : Double(GPSData.theGPSData.altitude), unit: "m")
    }
    
    private func setModeLabel(label: UILabel, on: Bool) {
        if on {
            label.backgroundColor = UIColor.greenColor()
            label.textColor = UIColor.blackColor()
        } else {
            label.backgroundColor = UIColor.clearColor()
            label.textColor = UIColor.lightGrayColor()
        }
    }
    
    func receivedData() {
        let config = Configuration.theConfig
        let settings = Settings.theSettings
        
        setModeLabel(theView.modeArmedLabel, on: settings.isModeOn(Mode.ARM, forStatus: config.mode))
        setModeLabel(theView.modeAngleLabel, on: settings.isModeOn(Mode.ANGLE, forStatus: config.mode))
        setModeLabel(theView.modeHorizonLabel, on: settings.isModeOn(Mode.HORIZON, forStatus: config.mode))
        setModeLabel(theView.modeBaroLabel, on: settings.isModeOn(Mode.BARO, forStatus: config.mode))
        setModeLabel(theView.modeMagLabel, on: settings.isModeOn(Mode.MAG, forStatus: config.mode))
        setModeLabel(theView.modeGpsHomeLabel, on: settings.isModeOn(Mode.GPSHOME, forStatus: config.mode))
        setModeLabel(theView.modeGpsHoldLabel, on: settings.isModeOn(Mode.GPSHOLD, forStatus: config.mode))
        setModeLabel(theView.modeBeeperLabel, on: settings.isModeOn(Mode.BEEPER, forStatus: config.mode))
        setModeLabel(theView.modeOsdLabel, on: settings.isModeOn(Mode.OSDSW, forStatus: config.mode))

        theView.voltLabel.text = String(format: "%.1fV", locale: NSLocale.currentLocale(), config.voltage)
        VoiceMessage.theVoice.checkAlarm(BatteryLowAlarm())
        
        theView.rssiLabel.text = String(format: "%d%%", locale: NSLocale.currentLocale(), config.rssi)
        
        theView.accSensor.image = config.isGyroAndAccActive() ? accSensorOn : accSensorOff
        theView.gyroSensor.image = config.isGyroAndAccActive() ? gyroSensorOn : gyroSensorOff
        theView.magSensor.image = config.isMagnetometerActive() ? magSensorOn : magSensorOff
        theView.baroSensor.image = config.isBarometerActive() ? baroSensorOn : baroSensorOff
        theView.gpsSensor.image = config.isGPSActive() ? gpsSensorOn : gpsSensorOff
        theView.sonarSensor.image = config.isSonarActive() ? sonarSensorOn : sonarSensorOff
    }
    
    func receivedGpsData() {
        let gpsData = GPSData.theGPSData
        if gpsData.fix && gpsData.numSat >= 5 {
            theView.gpsFixImage.image = greenled
            theView.distanceToHomeLabel.text = String(format: "%dm", locale: NSLocale.currentLocale(), gpsData.distanceToHome)
            theView.speedLabel.text = formatWithUnit(gpsData.speed, unit: "km/h")
        } else {
            theView.gpsFixImage.image = redled
            theView.distanceToHomeLabel.text = ""
            theView.speedLabel.text = ""
        }
        VoiceMessage.theVoice.checkAlarm(GPSFixLostAlarm())
    }
    
    @IBAction func disconnectAction(sender: AnyObject) {
        if let comm = msp.commChannel {
            comm.close()
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func startRecording() {
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let fileURL = documentsURL.URLByAppendingPathComponent(String(format: "record-%f.rec", NSDate.timeIntervalSinceReferenceDate()))
        
        do {
            if NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: nil, attributes: nil) {
                let file = try NSFileHandle(forWritingToURL: fileURL)
                file.seekToEndOfFile()
                msp.datalog = file
                msp.datalogStart = NSDate()
            }
        } catch let error as NSError {
            NSLog("Cannot open %@: %@", fileURL, error)
        }
    }
    
    func stopRecording() {
        if let file = msp.datalog {
            msp.datalog = nil
            msp.datalogStart = nil
            file.closeFile()
        }
    }
    @IBAction func recordAction(sender: AnyObject) {
        if msp.datalog != nil {
            stopRecording()
            (sender as! UIButton).setTitle("Record", forState: .Normal)
        } else {
            startRecording()
            (sender as! UIButton).setTitle("Stop Recording", forState: .Normal)
        }
    }
    @IBAction func followMeSwitchChanged(sender: UISwitch) {
        if sender.on {
            if locationManager == nil {
                locationManager = CLLocationManager()
            }
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest      // kCLLocationAccuracyBestForNavigation?
            locationManager!.requestAlwaysAuthorization()
            locationManager!.startUpdatingLocation()
            
        } else {
            locationManager?.stopUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if lastFollowMeUpdate == nil || -lastFollowMeUpdate!.timeIntervalSinceNow >= followMeUpdatePeriod {
                self.lastFollowMeUpdate = NSDate()
                let longitude = location.coordinate.longitude
                let latitude = location.coordinate.latitude
                NSLog("Sending follow me location %.4f / %.4f", latitude, longitude)
                msp.sendWaypoint(16, latitude: latitude, longitude: longitude, altitude: 0, callback: { success in
                    if !success {
                        self.lastFollowMeUpdate = nil
                    } else {
                        
                    }
                })
            }
        }
    }
}
