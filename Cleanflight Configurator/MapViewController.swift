//
//  MapViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 22/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import MapKit
import SVProgressHUD

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UseMAVLinkVehicle {
    var locationManager: CLLocationManager?
    
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
        
        vehicle.batteryVolts.addObserver(self, listener: { newValue in
            self.batteryLabel.voltage = newValue
        })
        
        vehicle.rssi.addObserver(self, listener: { newValue in
            if newValue == nil {
                self.rssiLabel.text = "?"
            } else {
                self.rssiLabel.rssi = newValue!
            }
        })
        
        vehicle.sikRssi.addObserver(self, listener: { newValue in
            if newValue != nil {
                self.rssiLabel.sikRssi = newValue!
            }
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
        
        vehicle.waypointPosition.addObserver(self, listener: { newValue in
            if self.posHoldLocation != nil {
                self.mapView.removeAnnotation(self.posHoldLocation!)
                self.posHoldLocation = nil
            }
            if newValue != nil {
                self.posHoldLocation = MKPointAnnotation()
                self.posHoldLocation!.coordinate = newValue!.position2d.toCLLocationCoordinate2D()
                self.posHoldLocation!.title = "Current Waypoint"
                self.mapView.addAnnotation(self.posHoldLocation!)
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
        // Update armed time
        stopwatchTimer(self)
        
        vehicle.positions.addObserver(self, listener: { newValue in
            if newValue != nil {
                self.mapView.removeOverlays(self.mapView.overlays)
                var coordinates = [CLLocationCoordinate2D]()
                for p in newValue! {
                    coordinates.append(p.position2d.toCLLocationCoordinate2D())
                }
                let polyline = MKPolyline(coordinates: UnsafeMutablePointer(coordinates), count: coordinates.count)
                self.mapView.addOverlay(polyline)
            }
        })
        
        if vehicle is MSPVehicle {
            mspvehicle.gpsHoldMode.addObserver(self, listener: { newValue in
                if !newValue && self.posHoldLocation != nil {
                    self.mapView.removeAnnotation(self.posHoldLocation!)
                    self.posHoldLocation = nil
                }
            })
        }

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
        
        vehicle.batteryVolts.removeObserver(self)
        vehicle.rssi.removeObserver(self)
        vehicle.sikRssi.removeObserver(self)
        vehicle.altitude.removeObserver(self)
        vehicle.gpsNumSats.removeObserver(self)
        vehicle.gpsFix.removeObserver(self)
        vehicle.speed.removeObserver(self)
        vehicle.lastKnownGoodPosition.removeObserver(self)
        vehicle.homePosition.removeObserver(self)
        vehicle.waypointPosition.removeObserver(self)
        vehicle.armed.removeObserver(self)
        vehicle.positions.removeObserver(self)

        if vehicle is MSPVehicle {
            mspvehicle.gpsHoldMode.removeObserver(self)
        }
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
    private func stopwatchTimer(sender: AnyObject) {
        let armedTime = Int(round(vehicle.totalArmedTime))
        timeLabel.text = String(format: "%02d:%02d", armedTime / 60, armedTime % 60)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.title ?? "" == "Aircraft" {
            annotationView = MKAircraftView(annotation: annotation, reuseIdentifier: nil, vehicle: vehicle)
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
        let point = sender.locationInView(mapView)
        if vehicle is MSPVehicle && !mspvehicle.gpsHoldMode.value {
            let alertController = UIAlertController(title: "Waypoint", message: "Activate GPS HOLD mode to enable waypoint navigation", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            alertController.popoverPresentationController?.sourceView = mapView
            presentViewController(alertController, animated: true, completion: nil)
            
            return
        }
        if sender.state == .Began {
            let coordinates = mapView.convertPoint(point, toCoordinateFromView: mapView)
            
            let message = String(format: "Navigate to location %@ %.04f, %@ %.04f ?", locale: NSLocale.currentLocale(), coordinates.latitude >= 0 ? "N" : "S", abs(coordinates.latitude), coordinates.longitude >= 0 ? "E" : "W", abs(coordinates.longitude))
            let alertController = UIAlertController(title: "Waypoint", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { alertController in
                // TODO allow to set altitude
                if self.vehicle is MSPVehicle {
                    self.msp.sendWaypoint(16, latitude: coordinates.latitude, longitude: coordinates.longitude, altitude: 0) { success in
                        if !success {
                            SVProgressHUD.showErrorWithStatus("Command failed")
                        }
                    }
                } else {
                    // MAVLink
                    if self.mavlinkVehicle.flightMode.value != .GUIDED {
                        self.mavlinkProtocolHandler.setFlightMode(.GUIDED)
                    }
                    let targetPosition = Position3D(position2d: Position(latitude: coordinates.latitude, longitude: coordinates.longitude), altitude: self.vehicle.altitude.value)
                    self.mavlinkProtocolHandler.navigateToPosition(targetPosition.position2d) { success in
                        if !success {
                            SVProgressHUD.showErrorWithStatus("Command failed")
                        } else {
                            self.vehicle.waypointPosition.value = targetPosition
                        }
                    }
                }
            }))
            alertController.popoverPresentationController?.sourceView = mapView
            presentViewController(alertController, animated: true, completion: nil)
            
        }
    }
}

class MKAircraftView : MKAnnotationView {
    let Size: CGFloat = 26.0
    var vehicle: Vehicle! = nil
    
    init(annotation: MKAnnotation?, reuseIdentifier: String?, vehicle: Vehicle) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.vehicle = vehicle
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
        var rotation = vehicle.heading.value
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
