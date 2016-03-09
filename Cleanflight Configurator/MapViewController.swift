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
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var headingLabel: UILabel!
    
    var annotationView: MKAnnotationView?
    
    var aircraftLocation: MKPointAnnotation?
    var homeLocation: MKPointAnnotation?
    var posHoldLocation: MKPointAnnotation?
    
    private var stopwatchTimer: NSTimer?
    
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
        //receivedAltitudeData()
        receivedGpsData()
        
        vehicle.batteryVolts.addObserver(self, listener: { newValue in
            self.batteryLabel.voltage = newValue
        })
        
        vehicle.rssi.addObserver(self, listener: { newValue in
            self.rssiLabel.rssi = newValue!
        })
        
        vehicle.altitude.addObserver(self, listener: { newValue in
            self.altitudeLabel.text = formatAltitude(newValue)
        })
        
        vehicle.gpsNumSats.addObserver(self, listener: { newValue in
            if self.vehicle.gpsFix.value != nil {
                self.gpsLabel.text = String(format:"%d", locale: NSLocale.currentLocale(), newValue)
            }
        })
        
        vehicle.gpsFix.addObserver(self, listener: { newValue in
            if newValue == nil {
                // No GPS present
                self.gpsLabel.blinks = false
                self.gpsLabel.text = ""
            } else {
                self.gpsLabel.text = String(format:"%d", locale: NSLocale.currentLocale(), self.vehicle.gpsNumSats.value)
                if newValue! {
                    self.gpsLabel.blinks = false
                    if self.vehicle.gpsNumSats.value >= 5 {               // FIXME
                        self.gpsLabel.textColor = UIColor.blackColor()
                    } else {
                        self.gpsLabel.textColor = UIColor.orangeColor()
                    }
                } else {
                    self.gpsLabel.blinks = true
                    self.gpsLabel.textColor = UIColor.redColor()
                }
            }
        })
        
        vehicle.speed.addObserver(self, listener: { newValue in
            self.speedLabel.text = formatSpeed(newValue)
        })
        
        vehicle.lastKnownGoodPosition.addObserver(self, listener: { newValue in
            if newValue != nil {
                if self.aircraftLocation != nil {
                    UIView.animateWithDuration(0.1, animations: {
                        self.aircraftLocation!.coordinate = newValue!.toCLLocationCoordinate2D()
                    })
                    self.annotationView?.setNeedsDisplay()
                } else {
                    self.aircraftLocation = MKPointAnnotation()
                    self.aircraftLocation!.title = "Aircraft"
                    self.aircraftLocation!.coordinate = newValue!.toCLLocationCoordinate2D()
                    self.mapView.addAnnotation(self.aircraftLocation!)
                }
            }
        })
        
        vehicle.homePosition.addObserver(self, listener: { newValue in
            if self.homeLocation != nil {
                self.mapView.removeAnnotation(self.homeLocation!)
                self.homeLocation = nil
            }
            if newValue != nil {
                self.homeLocation = MKPointAnnotation()
                self.homeLocation!.coordinate = newValue!.position2d.toCLLocationCoordinate2D()
                self.homeLocation!.title = "Home"
                self.mapView.addAnnotation(self.homeLocation!)
            }
        })
        
        vehicle.armed.addObserver(self, listener: { newValue in
            if newValue {
                self.stopwatchTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "stopwatchTimer:", userInfo: nil, repeats: true)
            } else {
                self.stopwatchTimer?.invalidate()
                self.stopwatchTimer = nil
            }
        })

        var coordinate = vehicle.position.value?.toCLLocationCoordinate2D()
        if coordinate == nil || (coordinate?.latitude == 0 && coordinate?.longitude == 0) {
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
        vehicle.batteryVolts.removeObserver(self)
        vehicle.rssi.removeObserver(self)
        vehicle.altitude.removeObserver(self)
        vehicle.gpsNumSats.removeObserver(self)
        vehicle.gpsFix.removeObserver(self)
        vehicle.speed.removeObserver(self)
        vehicle.lastKnownGoodPosition.removeObserver(self)
        vehicle.homePosition.removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    @objc
    private func stopwatchTimer(timer: NSTimer) {
        let armedTime = Int(round(vehicle.totalArmedTime))
        timeLabel.text = String(format: "%02d:%02d", armedTime / 60, armedTime % 60)
    }
    
    func receivedData() {
        let config = Configuration.theConfig
        
        if !Settings.theSettings.isModeOn(.GPSHOLD, forStatus: config.mode) && posHoldLocation != nil {
            mapView.removeAnnotation(posHoldLocation!)
            posHoldLocation = nil
        }
    }
    
    func received3drRssiData() {
        let config = Configuration.theConfig
        
        rssiLabel.sikRssi = config.sikQuality
    }

    func receivedGpsData() {
        let gpsData = GPSData.theGPSData
        let config = Configuration.theConfig

        if gpsData.lastKnownGoodLatitude != 0 || gpsData.lastKnownGoodLongitude != 0 {
            if gpsData.positions.count != gpsPositions {
                gpsPositions = gpsData.positions.count
                
                mapView.removeOverlays(mapView.overlays)
                let polyline = MKPolyline(coordinates: UnsafeMutablePointer(gpsData.positions), count: gpsData.positions.count)
                mapView.addOverlay(polyline)
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
        if vehicle.replaying.value {
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
        
        CGContextRestoreGState(ctx)
    }
}
