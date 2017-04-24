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
    var locationManager: CLLocationManager?
    var gpsPositions = 0
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var batteryLabel: BatteryVoltageLabel!
    @IBOutlet weak var rssiLabel: RssiLabel!
    @IBOutlet weak var gpsLabel: BlinkingLabel!
    @IBOutlet weak var timeLabel: ArmedTimer!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var rssiImg: UIImageView!
    
    var annotationView: MKAnnotationView?
    
    var aircraftLocation: MKPointAnnotation?
    var homeLocation: MKPointAnnotation?
    var posHoldLocation: MKPointAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.layoutMargins = UIEdgeInsets(top: 85, left: 0, bottom: 0, right: 0)     // Display the compass below the right-handside instrument panel
        mapView.delegate = self
        
        batteryLabel.text = "?"
        rssiLabel.text = "?"
        gpsLabel.text = "?"

        speedLabel.text = "?"
        altitudeLabel.text = "?"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        timeLabel.appear()
        msp.addDataListener(self)
        receivedData()
        receivedAltitudeData()
        receivedGpsData()
        
        mapView.showsUserLocation = true
        
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
        rssiImg.image = UIImage(named: appDelegate.showBtRssi ? "btrssi" : "signal")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        timeLabel.disappear()
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
        let coordinates = CLLocationCoordinate2D(latitude: gpsData.lastKnownGoodLatitude, longitude: gpsData.lastKnownGoodLongitude)
        
        return coordinates
    }
    
    func receivedData() {
        let config = Configuration.theConfig
        
        batteryLabel.voltage = config.voltage
        
        rssiLabel.rssi = appDelegate.showBtRssi ? config.btRssi : config.rssi
        
        if !Settings.theSettings.isModeOn(.GPSHOLD, forStatus: config.mode) && posHoldLocation != nil {
            mapView.removeAnnotation(posHoldLocation!)
            posHoldLocation = nil
        }
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
        
        gpsLabel.text = String(format:"%d", gpsData.numSat)
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
        } else {
            if config.isGPSActive() {
                gpsLabel.blinks = true
                gpsLabel.textColor = UIColor.redColor()
            }
            speedLabel.text = ""
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
                
                let coordinate = MapViewController.getAircraftCoordinates()!
                if aircraftLocation != nil {
                    if (aircraftLocation!.coordinate.latitude != coordinate.latitude || aircraftLocation!.coordinate.longitude != coordinate.longitude) {
                        UIView.animateWithDuration(0.1, animations: {
                            self.aircraftLocation!.coordinate = coordinate
                        })
                        annotationView?.setNeedsDisplay()
                    }
                } else {
                    aircraftLocation = MKPointAnnotation()
                    aircraftLocation!.title = "Aircraft"
                    aircraftLocation!.coordinate = coordinate
                    mapView.addAnnotation(aircraftLocation!)
                }
            }
        }
        if gpsData.homePosition != nil {
            var addAnnot = true
            if homeLocation != nil {
                if homeLocation!.coordinate.latitude == gpsData.homePosition!.latitude && homeLocation!.coordinate.longitude == gpsData.homePosition!.longitude {
                    addAnnot = false
                } else {
                    mapView.removeAnnotation(homeLocation!)
                }
            }
            if addAnnot {
                homeLocation = MKPointAnnotation()
                homeLocation!.coordinate = gpsData.homePosition!.toCLLocationCoordinate2D()
                homeLocation!.title = "Home"
                mapView.addAnnotation(homeLocation!)
            }
            
        }
        if gpsData.posHoldPosition != nil && Settings.theSettings.isModeOn(.GPSHOLD, forStatus: config.mode) {
            var addAnnot = true
            if posHoldLocation != nil {
                if posHoldLocation!.coordinate.latitude == gpsData.posHoldPosition!.latitude && posHoldLocation!.coordinate.longitude == gpsData.posHoldPosition!.longitude {
                    addAnnot = false
                } else {
                    mapView.removeAnnotation(posHoldLocation!)
                }
            }
            if addAnnot {
                posHoldLocation = MKPointAnnotation()
                posHoldLocation!.coordinate = gpsData.posHoldPosition!.toCLLocationCoordinate2D()
                posHoldLocation!.title = "Position Hold"
                mapView.addAnnotation(posHoldLocation!)
            }
            
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.title ?? "" == "Aircraft" {
            annotationView = MKAircraftView(annotation: annotation, reuseIdentifier: nil)
            return annotationView
        } else if annotation === homeLocation {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "homeAnnotationView")
            view.canShowCallout = true
            view.pinColor = MKPinAnnotationColor.Green
            return view
        } else if annotation === posHoldLocation {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "posHoldAnnotationView")
            view.canShowCallout = true
            view.pinColor = MKPinAnnotationColor.Purple
            return view
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
    
    @IBAction func longPressOnMap(sender: UILongPressGestureRecognizer) {
        if msp.replaying {
            return
        }
        if !Settings.theSettings.isModeOn(.GPSHOLD, forStatus: Configuration.theConfig.mode) {
            let alertController = UIAlertController(title: "Waypoint", message: "Enable GPS HOLD mode to enable waypoint navigation", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            alertController.popoverPresentationController?.sourceView = mapView
            presentViewController(alertController, animated: true, completion: nil)

            return
        }
        let point = sender.locationInView(mapView)
        if sender.state == .Began {
            let coordinates = mapView.convertPoint(point, toCoordinateFromView: mapView)
            
            let message = String(format: "Navigate to location %@ %.04f, %@ %.04f ?", locale: NSLocale.currentLocale(), coordinates.latitude >= 0 ? "N" : "S", abs(coordinates.latitude), coordinates.longitude >= 0 ? "E" : "W", abs(coordinates.longitude))
            let alertController = UIAlertController(title: "Waypoint", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { alertController in
                // TODO allow to set altitude
                self.msp.sendWaypoint(16, latitude: coordinates.latitude, longitude: coordinates.longitude, altitude: 0, callback: nil)
            }))
            alertController.popoverPresentationController?.sourceView = mapView
            presentViewController(alertController, animated: true, completion: nil)

        }
    }
    @IBAction func rssiViewTapped(sender: AnyObject) {
        appDelegate.showBtRssi = !appDelegate.showBtRssi
        rssiImg.image = UIImage(named: appDelegate.showBtRssi ? "btrssi" : "signal")
        let config = Configuration.theConfig
        rssiLabel.rssi = appDelegate.showBtRssi ? config.btRssi : config.rssi
    }
}

class MKAircraftView : MKAnnotationView {
    let Size: CGFloat = 26.0
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.frame.size.width = Size
        self.frame.size.height = Size
        
        self.opaque = false
    }
    
    override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
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
