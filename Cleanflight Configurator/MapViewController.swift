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

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, MSPCommandSender {
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
    @IBOutlet weak var uploadButton: UIButton!
    
    var altitudeEventHandler: Disposable?
    var rssiEventHandler: Disposable?
    var navigationEventHandler: Disposable?
    var flightModeEventHandler: Disposable?
    var batteryEventHandler: Disposable?
    var gpsEventHandler: Disposable?

    var annotationView: MKAnnotationView?
    
    var aircraftLocation: MKPointAnnotation?
    var homeLocation: MKPointAnnotation?
    var posHoldLocation: MKPointAnnotation?
    
    private var waypointList = MKWaypointList()
    
    var aircraftLocationsOverlay: MKOverlay?
    var waypointsOverlay: MKOverlay?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.layoutMargins = UIEdgeInsets(top: 85, left: 0, bottom: 0, right: 0)     // Display the compass below the right-handside instrument panel
        mapView.delegate = self
        
        batteryLabel.text = "?"
        rssiLabel.text = "?"
        gpsLabel.text = "?"

        speedLabel.text = "?"
        altitudeLabel.text = "?"
        
        waypointList.modifiedEvent.addHandler(self, handler: MapViewController.waypointsModified)
        waypointList.waypointCreatedEvent.addHandler(self, handler: MapViewController.waypointAdded)
        waypointList.waypointDeletedEvent.addHandler(self, handler: MapViewController.waypointDeleted)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        timeLabel.appear()

        receivedBatteryData()
        receivedAltitudeData()
        receivedGpsData()
        receivedRssiData()
        receivedNavigationData()
        flightModeChanged()
        
        mapView.showsUserLocation = true
        
        var coordinate = MapViewController.getAircraftCoordinates()
        if coordinate == nil {
            coordinate = mapView.userLocation.coordinate
            if coordinate?.latitude == 0 && coordinate?.longitude == 0 {
                coordinate = nil
            }
        }
        // FIXME This is annoying when returning from WaypointVC
        /*
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
         */
        rssiImg.image = UIImage(named: appDelegate.showBtRssi ? "btrssi" : "signal")
        
        altitudeEventHandler = msp.altitudeEvent.addHandler(self, handler: MapViewController.receivedAltitudeData)
        rssiEventHandler = msp.rssiEvent.addHandler(self, handler: MapViewController.receivedRssiData)
        navigationEventHandler = msp.navigationEvent.addHandler(self, handler: MapViewController.receivedNavigationData)
        flightModeEventHandler = msp.flightModeEvent.addHandler(self, handler: MapViewController.flightModeChanged)
        batteryEventHandler = msp.batteryEvent.addHandler(self, handler: MapViewController.receivedBatteryData)
        gpsEventHandler = msp.gpsEvent.addHandler(self, handler: MapViewController.receivedGpsData)
        
        appDelegate.addMSPCommandSender(self)

        let gpsData = GPSData.theGPSData
        if Configuration.theConfig.isINav && gpsData.waypoints.isEmpty {
            msp.loadMission() { success in
                self.msp.fetchINavWaypoints(gpsData) { success in
                    dispatch_async(dispatch_get_main_queue(), {
                        if success {
                            self.waypointList.setWaypoints(gpsData.waypoints)
                        } else {
                            SVProgressHUD.showErrorWithStatus("Error downloading waypoints")
                            gpsData.waypoints.removeAll()   // So we try to reload them when we appear next time
                        }
                    })
                }
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        timeLabel.disappear()
        
        altitudeEventHandler?.dispose()
        rssiEventHandler?.dispose()
        navigationEventHandler?.dispose()
        flightModeEventHandler?.dispose()
        batteryEventHandler?.dispose()
        gpsEventHandler?.dispose()
        
        appDelegate.removeMSPCommandSender(self)
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
    
    private func addWaypointsOverlay() {
        var locations = [CLLocationCoordinate2D]()
        if homeLocation != nil {
            locations.append(homeLocation!.coordinate)
        }
        for wpAnnot in waypointList {
            if wpAnnot.returnToHome {
                if homeLocation != nil {
                    locations.append(homeLocation!.coordinate)
                }
            } else {
                locations.append(wpAnnot.coordinate)
            }
        }
        if waypointsOverlay != nil {
            mapView.removeOverlay(waypointsOverlay!)
        }
        waypointsOverlay = MKPolyline(coordinates: UnsafeMutablePointer(locations), count: locations.count)
        mapView.addOverlay(waypointsOverlay!)
    }

    func waypointsModified() {
        uploadButton.hidden = false
        addWaypointsOverlay()
    }
    
    func waypointAdded(data: MKWaypoint) {
        if !data.returnToHome {
            mapView.addAnnotation(data)
        }
        addWaypointsOverlay()
    }

    func waypointDeleted(data: MKWaypoint) {
        if !data.returnToHome {
            mapView.removeAnnotation(data)
        }
        addWaypointsOverlay()
    }
    
    func sendMSPCommands() {
        let settings = Settings.theSettings
        let config = Configuration.theConfig
        if settings.armed && config.isINav {
            msp.sendMessage(.MSP_NAV_STATUS, data: nil)
        }
    }

    // MARK: Event Handlers
    
    func receivedBatteryData() {
        let config = Configuration.theConfig
        
        batteryLabel.voltage = config.voltage
        
    }
    
    func flightModeChanged() {
        if !Settings.theSettings.isModeOn(.GPSHOLD, forStatus: Configuration.theConfig.mode) && posHoldLocation != nil {
            mapView.removeAnnotation(posHoldLocation!)
            posHoldLocation = nil
        }
    }
    
    func receivedRssiData() {
        let config = Configuration.theConfig
        
        rssiLabel.rssi = appDelegate.showBtRssi ? config.btRssi : config.rssi
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
                
                if aircraftLocationsOverlay != nil {
                    mapView.removeOverlay(aircraftLocationsOverlay!)
                }
                aircraftLocationsOverlay = MKPolyline(coordinates: UnsafeMutablePointer(gpsData.positions), count: gpsData.positions.count)
                mapView.addOverlay(aircraftLocationsOverlay!)
                
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
                addWaypointsOverlay()
            }
            
        }
    }
    
    func receivedNavigationData() {
        let gpsData = GPSData.theGPSData
        let config = Configuration.theConfig
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
        let inavConfig = INavConfig.theINavConfig
        let activeWaypoint: MKWaypoint?
        if inavConfig.activeWaypoint >= 1 && inavConfig.activeWaypoint + 1 < waypointList.count {
            activeWaypoint = waypointList.waypointAt(inavConfig.activeWaypoint - 1)
        } else {
            activeWaypoint = nil
        }
        if activeWaypoint != waypointList.activeWaypoint {
            if let previousActive = waypointList.activeWaypoint {
                (mapView.viewForAnnotation(previousActive) as? MKWaypointView)?.didSelect()
            }
            waypointList.activeWaypoint = activeWaypoint
            if activeWaypoint != nil {
                (mapView.viewForAnnotation(activeWaypoint!) as? MKWaypointView)?.didSelect()
            }
        }
    }

    // MARK: MKMapViewDelegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let wpAnnot = annotation as? MKWaypoint {
            if wpAnnot.returnToHome {
                return nil
            }
            let view = MKWaypointView(annotation: annotation, reuseIdentifier: nil)
            view.parentViewController = self
            view.waypointList = waypointList
            return view
        } else if annotation.title ?? "" == "Aircraft" {
            annotationView = MKAircraftView(annotation: annotation, reuseIdentifier: nil)
            return annotationView
        } else if annotation === homeLocation {
            let view = MKHomeLocationView(annotation: annotation, reuseIdentifier: nil)
            return view
        } else if annotation === posHoldLocation {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "posHoldAnnotationView")
            view.canShowCallout = true
            view.pinColor = MKPinAnnotationColor.Purple
            return view
        }
        
        return nil
    }
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let waypointView = view as? MKWaypointView {
            waypointView.didSelect()
        }
    }
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        if let waypointView = view as? MKWaypointView {
            waypointView.didSelect()
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        if self.aircraftLocationsOverlay != nil && overlay === self.aircraftLocationsOverlay! {
            renderer.lineWidth = 3.0
            renderer.strokeColor = UIColor.redColor()
        } else {
            // Waypoints
            renderer.lineWidth = 2.0
            renderer.strokeColor = UIColor.whiteColor()
        }
        return renderer
    }

    // MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
    // MARK: Actions
    
    @IBAction func longPressOnMap(sender: UILongPressGestureRecognizer) {
        if msp.replaying {
            return
        }
        let config = Configuration.theConfig
        let settings = Settings.theSettings
        if sender.state == .Began {
            if config.isINav && !settings.armed {
                if waypointList.count >= 15 {
                    let alertController = UIAlertController(title: "Waypoint", message: "Maximum of 15 waypoints reached", preferredStyle: UIAlertControllerStyle.Alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    alertController.popoverPresentationController?.sourceView = mapView
                    presentViewController(alertController, animated: true, completion: nil)
                } else {
                    let point = sender.locationInView(mapView)
                    let coordinates = mapView.convertPoint(point, toCoordinateFromView: mapView)
                    let waypoint = Waypoint(position: GPSLocation(latitude: coordinates.latitude, longitude: coordinates.longitude), altitude: 0, speed: 0)
                    waypointList.append(waypoint)
                }
                return
            }
            
            if !settings.isModeOn(.GPSHOLD, forStatus: config.mode) {
                let alertController = UIAlertController(title: "Waypoint", message: "Enable GPS HOLD mode to enable waypoint navigation", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                alertController.popoverPresentationController?.sourceView = mapView
                presentViewController(alertController, animated: true, completion: nil)
                
                return
            }
            let point = sender.locationInView(mapView)
            let coordinates = mapView.convertPoint(point, toCoordinateFromView: mapView)
            
            let message = String(format: "Navigate to location %@ %.04f, %@ %.04f ?", locale: NSLocale.currentLocale(), coordinates.latitude >= 0 ? "N" : "S", abs(coordinates.latitude), coordinates.longitude >= 0 ? "E" : "W", abs(coordinates.longitude))
            let alertController = UIAlertController(title: "Waypoint", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { alertController in
                // TODO allow to set altitude
                self.msp.setGPSHoldPosition(latitude: coordinates.latitude, longitude: coordinates.longitude, altitude: 0, callback: nil)
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
    
    @IBAction func uploadWaypoints(sender: AnyObject) {
        let gpsData = GPSData.theGPSData
        gpsData.waypoints.removeAll()
        for (i, wpAnnot) in waypointList.enumerate() {
            var wp = wpAnnot.waypoint
            wp.number = i + 1
            wp.last = i == waypointList.count - 1
            gpsData.waypoints.append(wp)
        }
        let commands: [SendCommand] = [
            { callback in
                self.msp.sendINavWaypoints(gpsData, callback: callback)
            },
            { callback in
                self.msp.saveMission(callback)
            }
        ]
        chainMspSend(commands) { success in
            dispatch_async(dispatch_get_main_queue()) {
                if success {
                    SVProgressHUD.showInfoWithStatus("Waypoints uploaded")
                    self.uploadButton.hidden = true
                } else {
                    SVProgressHUD.showErrorWithStatus("Error uploading waypoints")
                }
            }
        }
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
