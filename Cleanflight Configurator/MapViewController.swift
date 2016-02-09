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
    //var lat = 48.886212 // Debug
    var locationManager: CLLocationManager?
    var gpsPositions = 0
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var batteryLabel: BatteryVoltageLabel!
    @IBOutlet weak var rssiLabel: RssiLabel!
    @IBOutlet weak var gpsLabel: BlinkingLabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var headingLabel: UILabel!
    
    var annotationView: MKAnnotationView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.layoutMargins = UIEdgeInsets(top: 85, left: 0, bottom: 0, right: 0)     // Display the compass below the right-handside instrument panel
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        batteryLabel.text = "?"
        rssiLabel.text = "?"
        gpsLabel.text = "?"
        timeLabel.text = "00:00"
        speedLabel.text = "?"
        altitudeLabel.text = "?"
        //headingLabel.text = "?"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        msp.addDataListener(self)
        receivedData()
        receivedAltitudeData()
        receivedGpsData()
        
        var coordinate = MapViewController.getAircraftCoordinates()
        if coordinate == nil {
            coordinate = mapView.userLocation.coordinate
            if coordinate?.latitude == 0 && coordinate?.longitude == 0 {
                coordinate = nil
            }
        }
        if coordinate != nil {
            // Zoom in if the map shows more than 2km x 2km. Otherwise just center
            let currentSpan = mapView.region.span
            var region = MKCoordinateRegionMakeWithDistance(coordinate!, 2000, 2000)
            if currentSpan.latitudeDelta > region.span.latitudeDelta || currentSpan.longitudeDelta > region.span.longitudeDelta {
                region = MKCoordinateRegionMakeWithDistance(coordinate!, 200, 200)
                mapView.setRegion(region, animated: true)
            } else {
                mapView.setCenterCoordinate(coordinate!, animated: true)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        msp.removeDataListener(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    class func getAircraftCoordinates() -> CLLocationCoordinate2D? {
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
        
        batteryLabel.voltage = config.voltage
        
        rssiLabel.rssi = config.rssi
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let armedTime = Int(round(appDelegate.totalArmedTime))
        timeLabel.text = String(format: "%02d:%02d", armedTime / 60, armedTime % 60)
    }
    
    func received3drRssiData() {
        let config = Configuration.theConfig
        
        rssiLabel.sikRssi = config.sikQuality
    }
    
    func receivedAltitudeData() {
        let sensorData = SensorData.theSensorData
        let config = Configuration.theConfig
        
        if config.isBarometerActive() || config.isSonarActive() {
            altitudeLabel.text = formatAltitude(sensorData.altitude)
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
            if gpsData.positions.count != gpsPositions {
                gpsPositions = gpsData.positions.count
                
                mapView.removeOverlays(mapView.overlays)
                let polyline = MKPolyline(coordinates: UnsafeMutablePointer(gpsData.positions), count: gpsData.positions.count)
                mapView.addOverlay(polyline)
                
                if let annotation = mapView.annotations.filter({ annot in
                    return annot is MKPointAnnotation
                }).first as? MKPointAnnotation {
                    UIView.animateWithDuration(0.1, animations: {
                        annotation.coordinate = MapViewController.getAircraftCoordinates()!
                    })
                    annotationView?.setNeedsDisplay()
                } else {
                    let annotation = MKPointAnnotation()
                    annotation.title = "Aircraft"
                    annotation.coordinate = MapViewController.getAircraftCoordinates()!
                    mapView.addAnnotation(annotation)
                }
                
            }
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.title ?? "" == "Aircraft" {
            annotationView = MKAircraftView(annotation: annotation, reuseIdentifier: nil)
            return annotationView
        }
        
        return nil
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.lineWidth = 3.0
        renderer.strokeColor = UIColor.redColor()
        return renderer
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
}

class MKAircraftView : MKAnnotationView {
    let Size: CGFloat = 26.0
    
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
    
    override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        CGContextSaveGState(ctx)
        
        CGContextTranslateCTM(ctx, Size / 2, Size / 2)
        var rotation = SensorData.theSensorData.heading
        if rotation > 180 {
            rotation -= 360
        }
        CGContextRotateCTM(ctx, CGFloat(rotation * M_PI / 180))
        
        let actualSize = Size - 4
        UIColor.whiteColor().colorWithAlphaComponent(0.8).setFill()
        let dx = actualSize * CGFloat(sin(M_PI_4 / 2))
        CGContextMoveToPoint(ctx, 0, -actualSize / 2)
        CGContextAddLineToPoint(ctx, -dx, actualSize / 2)
        CGContextAddLineToPoint(ctx, 0, actualSize / 2 - 4)
        CGContextAddLineToPoint(ctx, dx, actualSize / 2)
        CGContextClosePath(ctx)
        CGContextFillPath(ctx)
        
        //        UIColor.whiteColor().setFill()
        //        CGContextFillEllipseInRect(ctx, bounds)
        //        let centerRect = bounds.insetBy(dx: 3.5, dy: 3.5)
        //        UIColor.redColor().setFill()
        //        CGContextFillEllipseInRect(ctx, centerRect)
        
        CGContextRestoreGState(ctx)
    }
}
