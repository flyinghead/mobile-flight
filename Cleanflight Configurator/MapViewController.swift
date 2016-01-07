//
//  MapViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 22/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, FlightDataListener, CLLocationManagerDelegate {
    let TimerPeriod = 0.1
    var timer: NSTimer?
    var slowTimer: NSTimer?
    //var lat = 48.886212 // Debug
    var locationManager: CLLocationManager?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var batteryLabel: BlinkingLabel!
    @IBOutlet weak var rssiLabel: BlinkingLabel!
    @IBOutlet weak var gpsLabel: BlinkingLabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var headingLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.showsUserLocation = true
        
        msp.addDataListener(self)
        
        batteryLabel.text = "?"
        rssiLabel.text = "?"
        gpsLabel.text = "?"
        timeLabel.text = "00:00"
        speedLabel.text = "?"
        altitudeLabel.text = "?"
        //headingLabel.text = "?"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (timer == nil) {
            timer = NSTimer.scheduledTimerWithTimeInterval(TimerPeriod, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        }
        if (slowTimer == nil) {
            slowTimer = NSTimer.scheduledTimerWithTimeInterval(0.333, target: self, selector: "slowTimerDidFire:", userInfo: nil, repeats: true)
        }
        var coordinate = getAircraftCoordinates()
        if coordinate == nil {
            coordinate = mapView.userLocation.coordinate
            if coordinate?.latitude == 0 && coordinate?.longitude == 0 {
                coordinate = nil
            }
        }
        if coordinate != nil {
            let region = MKCoordinateRegionMakeWithDistance(coordinate!, 200, 200)
            mapView.setRegion(region, animated: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer?.invalidate()
        timer = nil
        slowTimer?.invalidate()
        slowTimer = nil
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    func timerDidFire(sender: AnyObject) {
        msp.sendMessage(.MSP_RAW_GPS, data: nil)
        msp.sendMessage(.MSP_COMP_GPS, data: nil)       // distance to home, direction to home
        msp.sendMessage(.MSP_ALTITUDE, data: nil)
        msp.sendMessage(.MSP_ATTITUDE, data: nil)
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let armedTime = Int(round(appDelegate.armedTime))
        timeLabel.text = String(format: "%02d:%02d", armedTime / 60, armedTime % 60)
    }
    
    func slowTimerDidFire(sender: AnyObject) {
        msp.sendMessage(.MSP_ANALOG, data: nil)
    }
    
    func getAircraftCoordinates() -> CLLocationCoordinate2D? {
        let gpsData = GPSData.theGPSData
        if gpsData.lastKnownGoodLatitude == 0.0 && gpsData.lastKnownGoodLongitude == 0 {
            return nil
        }
        // 48.886212, 2.305796
        //let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: 2.305796)
        //lat += 0.000002
        let coordinates = CLLocationCoordinate2D(latitude: gpsData.lastKnownGoodLatitude, longitude: gpsData.lastKnownGoodLongitude)
        
        return coordinates
    }

    func receivedData() {
        let config = Configuration.theConfig
        
        batteryLabel.blinks = false
        batteryLabel.text = String(format:"%.1fV", locale: NSLocale.currentLocale(), config.voltage)
        rssiLabel.blinks = false
        rssiLabel.text = String(format:"%d%%", locale: NSLocale.currentLocale(), config.rssi)
    }
    
    func receivedSensorData() {
        let sensorData = SensorData.theSensorData
        let config = Configuration.theConfig
        
        if config.isBarometerActive() || config.isSonarActive() {
            altitudeLabel.text = formatAltitude(sensorData.altitude)
        }
        
        if config.isMagnetometerActive() {
            //headingLabel.text = String(format: "%.0f°", locale: NSLocale.currentLocale(), sensorData.heading)
        }
    }
    
    func receivedGpsData() {
        let gpsData = GPSData.theGPSData
        let config = Configuration.theConfig
        
        gpsLabel.text = String(format:"%d", locale: NSLocale.currentLocale(), gpsData.numSat)
        if gpsData.fix {
            gpsLabel.blinks = false
            if gpsData.numSat >= 5 {
                gpsLabel.textColor = UIColor.blackColor()
            } else {
                gpsLabel.textColor = UIColor.orangeColor()
            }
            if !config.isBarometerActive() && !config.isSonarActive() {
                altitudeLabel.text = formatAltitude(Double(gpsData.altitude))
            }
            speedLabel.text = formatSpeed(gpsData.speed)
            if !config.isMagnetometerActive() {
                //headingLabel.text = String(format:"%.0f°", locale: NSLocale.currentLocale(), gpsData.headingOverGround)
            }
        } else {
            if config.isGPSActive() {
                gpsLabel.blinks = true
                gpsLabel.textColor = UIColor.redColor()
            }
            speedLabel.text = ""
            if !config.isMagnetometerActive() {
                //headingLabel.text = ""
            }
            if !config.isBarometerActive() && !config.isSonarActive() {
                altitudeLabel.text = ""
            }
        }
        if gpsData.lastKnownGoodLatitude != 0 || gpsData.lastKnownGoodLongitude != 0 {
            if let annotation = mapView.annotations.filter({ annot in
                return annot is MKPointAnnotation
            }).first as? MKPointAnnotation {
                UIView.animateWithDuration(TimerPeriod, animations: {
                    annotation.coordinate = self.getAircraftCoordinates()!
                })
            } else {
                let annotation = MKPointAnnotation()
                annotation.title = "Aircraft"
                annotation.coordinate = getAircraftCoordinates()!
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.title ?? "" == "Aircraft" {
            let annotationView = MKAircraftView(annotation: annotation, reuseIdentifier: "Drone")
            return annotationView
        }
        
        return nil
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
}

class MKAircraftView : MKAnnotationView {
    let Size: CGFloat = 22.0
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame.size.width = Size
        self.frame.size.height = Size
        
        self.opaque = false
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.frame.size.width = Size
        self.frame.size.height = Size
        
        self.opaque = false
    }
    
    override func drawRect(var rect: CGRect) {
        UIColor.whiteColor().setFill()
        CGContextFillEllipseInRect(UIGraphicsGetCurrentContext(), rect)
        rect.insetInPlace(dx: 3.5, dy: 3.5)
        UIColor.redColor().setFill()
        CGContextFillEllipseInRect(UIGraphicsGetCurrentContext(), rect)
    }
}