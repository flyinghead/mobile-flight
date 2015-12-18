//
//  TelemetryViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 07/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import CoreLocation

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
    
    var timerInterval = 0.1     // 100ms by default. Latency for MSP_ATTITUDE is around 40-70 ms
    var timer: NSTimer?
    var timer2: NSTimer?
    var timer3: NSTimer?

    var locationManager: CLLocationManager?
    var lastFollowMeUpdate: NSDate?
    let followMeUpdatePeriod: NSTimeInterval = 2.0      // 2s in ArduPilot MissionPlanner
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        msp.addDataListener(self)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (timer == nil) {
            timer = NSTimer.scheduledTimerWithTimeInterval(timerInterval, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        }
        if (timer2 == nil) {
            timer2 = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: "timer2DidFire:", userInfo: nil, repeats: true)
        }
        if (timer3 == nil) {
            timer3 = NSTimer.scheduledTimerWithTimeInterval(0.6, target: self, selector: "timer3DidFire:", userInfo: nil, repeats: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        timer?.invalidate()
        timer = nil
        timer2?.invalidate()
        timer2 = nil
        timer3?.invalidate()
        timer3 = nil
    }
    
    func timerDidFire(sender: AnyObject) {
        if Settings.theSettings.boxNames != nil {
            msp.sendMessage(.MSP_ATTITUDE, data: nil)
        }
    }
    func timer2DidFire(sender: AnyObject) {
        if Settings.theSettings.boxNames != nil {
            msp.sendMessage(.MSP_STATUS, data: nil)
            msp.sendMessage(.MSP_ALTITUDE, data: nil)
        }
    }
    func timer3DidFire(sender: AnyObject) {
        if Settings.theSettings.boxNames != nil {
            msp.sendMessage(.MSP_RAW_GPS, data: nil)
            msp.sendMessage(.MSP_COMP_GPS, data: nil)
            msp.sendMessage(.MSP_ANALOG, data: nil)
        }
    }
    
    func receivedSensorData() {
        let sensorData = SensorData.theSensorData
        attitudeIndicator.roll = sensorData.kinematicsX
        attitudeIndicator.pitch = sensorData.kinematicsY
        attitudeIndicator.setNeedsDisplay()
        
        // FIXME We should use magnetic compass instead?
        headingIndicator.heading = sensorData.kinematicsZ
        headingIndicator.setNeedsDisplay()
        
        // Use baro/sonar altitude if present, otherwise use GPS altitude
        altitudeLabel.text = String(format: "%.1f m", locale: NSLocale.currentLocale(), Configuration.theConfig.isBarometerActive() ? sensorData.altitude : Double(GPSData.theGPSData.altitude))
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
        
        if config.mode != nil {
            setModeLabel(modeArmedLabel, on: settings.isModeOn(Mode.ARM, forStatus: config.mode!))
            setModeLabel(modeAngleLabel, on: settings.isModeOn(Mode.ANGLE, forStatus: config.mode!))
            setModeLabel(modeHorizonLabel, on: settings.isModeOn(Mode.HORIZON, forStatus: config.mode!))
            setModeLabel(modeBaroLabel, on: settings.isModeOn(Mode.BARO, forStatus: config.mode!))
            setModeLabel(modeMagLabel, on: settings.isModeOn(Mode.MAG, forStatus: config.mode!))
            setModeLabel(modeGpsHomeLabel, on: settings.isModeOn(Mode.GPSHOME, forStatus: config.mode!))
            setModeLabel(modeGpsHoldLabel, on: settings.isModeOn(Mode.GPSHOLD, forStatus: config.mode!))
            setModeLabel(modeBeeperLabel, on: settings.isModeOn(Mode.BEEPER, forStatus: config.mode!))
            setModeLabel(modeOsdLabel, on: settings.isModeOn(Mode.OSDSW, forStatus: config.mode!))
        }
        voltLabel.text = String(format: "%.1f V", locale: NSLocale.currentLocale(), config.voltage)
        rssiLabel.text = String(format: "%d %%", locale: NSLocale.currentLocale(), config.rssi * 100 / 1023)
        
        accSensor.image = config.isGyroAndAccActive() ? accSensorOn : accSensorOff
        gyroSensor.image = config.isGyroAndAccActive() ? gyroSensorOn : gyroSensorOff
        magSensor.image = config.isMagnetometerActive() ? magSensorOn : magSensorOff
        baroSensor.image = config.isBarometerActive() ? baroSensorOn : baroSensorOff
        gpsSensor.image = config.isGPSActive() ? gpsSensorOn : gpsSensorOff
        sonarSensor.image = config.isSonarActive() ? sonarSensorOn : sonarSensorOff
    }
    
    func receivedGpsData() {
        let gpsData = GPSData.theGPSData
        if gpsData.fix && gpsData.numSat >= 5 {
            gpsFixImage.image = greenled
            distanceToHomeLabel.text = String(format: "%d m", locale: NSLocale.currentLocale(), gpsData.distanceToHome)
            speedLabel.text = String(format: "%d cm/s", locale: NSLocale.currentLocale(), gpsData.speed)
        } else {
            gpsFixImage.image = redled
            distanceToHomeLabel.text = ""
            speedLabel.text = ""
        }
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
