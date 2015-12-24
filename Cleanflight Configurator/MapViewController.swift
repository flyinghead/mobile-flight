//
//  MapViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 22/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, FlightDataListener {
    let TimerPeriod = 0.1
    var timer: NSTimer?
    var slowTimer: NSTimer?
    var lat = 48.886212 // FIXME Debug
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var batteryLabel: BlinkingLabel!
    @IBOutlet weak var rssiLabel: BlinkingLabel!
    @IBOutlet weak var gpsLabel: BlinkingLabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var headingLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.showsUserLocation = true
        
        msp.addDataListener(self)
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
        }
        let region = MKCoordinateRegionMakeWithDistance(coordinate!, 200, 200)
        mapView.setRegion(region, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer?.invalidate()
        timer = nil
        slowTimer?.invalidate()
        slowTimer = nil
    }
    
    func timerDidFire(sender: AnyObject) {
        msp.sendMessage(.MSP_RAW_GPS, data: nil)
        msp.sendMessage(.MSP_COMP_GPS, data: nil)       // distance to home, direction to home
        msp.sendMessage(.MSP_ALTITUDE, data: nil)
    }
    
    func slowTimerDidFire(sender: AnyObject) {
        msp.sendMessage(.MSP_ANALOG, data: nil)
    }
    
    func getAircraftCoordinates() -> CLLocationCoordinate2D? {
        let gpsData = GPSData.theGPSData
        // 48.886212, 2.305796
        let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: 2.305796)
        lat += 0.000002
        //let coordinates = CLLocationCoordinate2D(latitude: gpsData.lastKnownGoodLatitude, longitude: gpsData.lastKnownGoodLongitude)
        
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
        
        if (config.isBarometerActive() || config.isSonarActive()) && sensorData.altitude != 0 {
            altitudeLabel.text = String(format:"%.1fm", locale: NSLocale.currentLocale(), sensorData.altitude)
        }
        
        // TODO Heading based on magnetometer?
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
            if (!config.isBarometerActive() && !config.isSonarActive()) || SensorData.theSensorData.altitude == 0.0 {
                altitudeLabel.text = String(format:"%dm", locale: NSLocale.currentLocale(), gpsData.altitude)
            }
            speedLabel.text = String(format:"%.1fkm/h", locale: NSLocale.currentLocale(), gpsData.speed)
            headingLabel.text = String(format:"%.0f°", locale: NSLocale.currentLocale(), gpsData.headingOverGround)
        } else {
            gpsLabel.blinks = true
            gpsLabel.textColor = UIColor.redColor()
            speedLabel.text = ""
            headingLabel.text = ""
            if !config.isBarometerActive() && !config.isSonarActive() {
                altitudeLabel.text = ""
            }
        }
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
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.title ?? "" == "Aircraft" {
            let annotationView = MKAircraftView(annotation: annotation, reuseIdentifier: "Drone")
            return annotationView
        }
        
        return nil
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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