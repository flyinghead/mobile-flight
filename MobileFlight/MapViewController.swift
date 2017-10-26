//
//  MapViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 22/12/15.
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
import MapKit
import SVProgressHUD
import Firebase

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
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
    
    fileprivate var waypointList = MKWaypointList()
    
    var aircraftLocationsOverlay: MKOverlay?
    var previousAircraftLocationsOverlay: MKOverlay?
    var waypointsOverlay: MKOverlay?
    
    var mapCenterDone = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.layoutMargins = UIEdgeInsets(top: 85, left: 0, bottom: 0, right: 0)     // Display the compass below the right-handside instrument panel
        mapView.delegate = self
        
        batteryLabel.text = "?"
        rssiLabel.text = "?"
        gpsLabel.text = "?"

        speedLabel.text = "?"
        altitudeLabel.text = "?"
        
        _ = waypointList.modifiedEvent.addHandler(self, handler: MapViewController.waypointsModified)
        _ = waypointList.waypointCreatedEvent.addHandler(self, handler: MapViewController.waypointAdded)
        _ = waypointList.waypointDeletedEvent.addHandler(self, handler: MapViewController.waypointDeleted)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        timeLabel.appear()

        receivedBatteryData()
        receivedAltitudeData()
        receivedGpsData()
        receivedRssiData()
        receivedNavigationData()
        flightModeChanged()
        
        mapView.showsUserLocation = true
        
        centerOrZoomTheMap()
        
        rssiImg.image = UIImage(named: appDelegate.showBtRssi ? "btrssi" : "signal")
        
        altitudeEventHandler = msp.altitudeEvent.addHandler(self, handler: MapViewController.receivedAltitudeData)
        rssiEventHandler = msp.rssiEvent.addHandler(self, handler: MapViewController.receivedRssiData)
        navigationEventHandler = msp.navigationEvent.addHandler(self, handler: MapViewController.receivedNavigationData)
        flightModeEventHandler = msp.flightModeEvent.addHandler(self, handler: MapViewController.flightModeChanged)
        batteryEventHandler = msp.batteryEvent.addHandler(self, handler: MapViewController.receivedBatteryData)
        gpsEventHandler = msp.gpsEvent.addHandler(self, handler: MapViewController.receivedGpsData)
        
        if Configuration.theConfig.isINav && !msp.simulating {
            let inavState = INavState.theINavState
            if inavState.waypoints.isEmpty {
                downloadWaypoints()
            } else if msp.replaying {
                self.waypointList.setWaypoints(inavState.waypoints)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timeLabel.disappear()
        
        altitudeEventHandler?.dispose()
        rssiEventHandler?.dispose()
        navigationEventHandler?.dispose()
        flightModeEventHandler?.dispose()
        batteryEventHandler?.dispose()
        gpsEventHandler?.dispose()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    fileprivate func centerOrZoomTheMap() {
        if mapCenterDone {
            // Do it once
            return
        }
        var coordinate = MapViewController.getAircraftCoordinates()
        if coordinate == nil {
            coordinate = mapView.userLocation.coordinate
            if coordinate?.latitude == 0 && coordinate?.longitude == 0 {
                coordinate = nil
            }
        }
        if coordinate != nil {
            let region = MKCoordinateRegionMakeWithDistance(coordinate!, 300, 300)
            mapView.setRegion(region, animated: true)
            // Don't do this more than once
            mapCenterDone = true
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
    
    fileprivate func downloadWaypoints() {
        SVProgressHUD.show(withStatus: "Downloading waypoints")
        appDelegate.stopTimer()
        INavState.theINavState.waypoints.removeAll()
        msp.sendMessage(.msp_WP_GETINFO, data: nil, retry: 2) { success in
            self.msp.loadMission() { success in
                let inavState = INavState.theINavState
                self.msp.fetchINavWaypoints(inavState) { success in
                    DispatchQueue.main.async(execute: {
                        self.appDelegate.startTimer()
                        if success {
                            self.waypointList.setWaypoints(inavState.waypoints)
                            SVProgressHUD.dismiss()
                        } else {
                            SVProgressHUD.showError(withStatus: "Error downloading waypoints")
                            inavState.waypoints.removeAll()   // So we try to reload them when we appear next time
                        }
                    })
                }
            }
        }
    }
    
    fileprivate func addWaypointsOverlay() {
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
            mapView.remove(waypointsOverlay!)
        }
        waypointsOverlay = MKPolyline(coordinates: UnsafeMutablePointer(mutating: locations), count: locations.count)
        mapView.add(waypointsOverlay!)
    }

    func waypointsModified() {
        uploadButton.isHidden = false
        addWaypointsOverlay()
    }
    
    func waypointAdded(_ data: MKWaypoint) {
        if !data.returnToHome {
            mapView.addAnnotation(data)
        }
        addWaypointsOverlay()
    }

    func waypointDeleted(_ data: MKWaypoint) {
        if !data.returnToHome {
            mapView.removeAnnotation(data)
        }
        addWaypointsOverlay()
    }

    // MARK: Event Handlers
    
    func receivedBatteryData() {
        let config = Configuration.theConfig
        
        batteryLabel.voltage = config.voltage
        
    }
    
    func flightModeChanged() {
        if !Settings.theSettings.positionHoldMode && posHoldLocation != nil {
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
                gpsLabel.textColor = UIColor.black
            } else {
                gpsLabel.textColor = UIColor.orange
            }
            if !config.isBarometerActive() && !config.isSonarActive() {
                altitudeLabel.text = formatAltitude(Double(gpsData.altitude))
            }
            speedLabel.text = formatSpeed(gpsData.speed)
        } else {
            if config.isGPSActive() {
                gpsLabel.blinks = true
                gpsLabel.textColor = UIColor.red
            }
            speedLabel.text = ""
            if !config.isBarometerActive() && !config.isSonarActive() {
                altitudeLabel.text = ""
            }
        }
        if gpsData.lastKnownGoodLatitude != 0 || gpsData.lastKnownGoodLongitude != 0 {
            if gpsData.positions.count != gpsPositions {
                gpsPositions = gpsData.positions.count
                
                // Keep previous overlay to prevent flashing
                if previousAircraftLocationsOverlay != nil {
                    mapView.remove(previousAircraftLocationsOverlay!)
                }
                previousAircraftLocationsOverlay = aircraftLocationsOverlay
                aircraftLocationsOverlay = MKPolyline(coordinates: UnsafeMutablePointer(mutating: gpsData.positions), count: gpsData.positions.count)
                mapView.add(aircraftLocationsOverlay!)
            }
            let coordinate = MapViewController.getAircraftCoordinates()!
            if aircraftLocation != nil {
                if (aircraftLocation!.coordinate.latitude != coordinate.latitude || aircraftLocation!.coordinate.longitude != coordinate.longitude) {
                    UIView.animate(withDuration: 0.1, animations: {
                        self.aircraftLocation!.coordinate = coordinate
                    })
                    annotationView?.setNeedsDisplay()
                }
            } else {
                aircraftLocation = MKPointAnnotation()
                aircraftLocation!.title = "Aircraft"
                aircraftLocation!.coordinate = coordinate
                mapView.addAnnotation(aircraftLocation!)
                centerOrZoomTheMap()
            }
        }
        if let homePosition = gpsData.homePosition {
            if homeLocation == nil {
                homeLocation = MKPointAnnotation()
                homeLocation!.coordinate = homePosition.toCLLocationCoordinate2D()
                homeLocation!.title = "Home"
                mapView.addAnnotation(homeLocation!)
                addWaypointsOverlay()
            } else if homeLocation!.coordinate.latitude != homePosition.latitude || homeLocation!.coordinate.longitude != homePosition.longitude {
                homeLocation!.coordinate = homePosition.toCLLocationCoordinate2D()
                addWaypointsOverlay()
            }
        }
    }
    
    func receivedNavigationData() {
        let gpsData = GPSData.theGPSData
        if gpsData.posHoldPosition != nil && Settings.theSettings.positionHoldMode {
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
        let inavState = INavState.theINavState
        let activeWaypoint: MKWaypoint?
        if inavState.activeWaypoint >= 1 && inavState.activeWaypoint + 1 < waypointList.count {
            activeWaypoint = waypointList.waypointAt(inavState.activeWaypoint - 1)
        } else {
            activeWaypoint = nil
        }
        if activeWaypoint != waypointList.activeWaypoint {
            if let previousActive = waypointList.activeWaypoint {
                (mapView.view(for: previousActive) as? MKWaypointView)?.didSelect()
            }
            waypointList.activeWaypoint = activeWaypoint
            if activeWaypoint != nil {
                (mapView.view(for: activeWaypoint!) as? MKWaypointView)?.didSelect()
            }
        }
    }

    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
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
            view.pinColor = MKPinAnnotationColor.purple
            return view
        }
        
        return nil
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let waypointView = view as? MKWaypointView {
            waypointView.didSelect()
        }
    }
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let waypointView = view as? MKWaypointView {
            waypointView.didSelect()
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        if overlay === self.aircraftLocationsOverlay || overlay === self.previousAircraftLocationsOverlay {
            renderer.lineWidth = 3.0
            renderer.strokeColor = UIColor.red
        } else {
            // Waypoints
            renderer.lineWidth = 2.0
            renderer.strokeColor = UIColor.white
        }
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        centerOrZoomTheMap()
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
    // MARK: Actions
    
    @IBAction func longPressOnMap(_ sender: UILongPressGestureRecognizer) {
        if msp.replaying {
            return
        }
        let config = Configuration.theConfig
        let settings = Settings.theSettings
        if sender.state == .began {
            if config.isINav && !settings.armed {
                let inavConfig = INavConfig.theINavConfig
                if waypointList.count >= inavConfig.maxWaypoints {
                    let message = String(format: "Maximum of %d waypoints reached", inavConfig.maxWaypoints)
                    let alertController = UIAlertController(title: "Waypoint", message: message, preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    alertController.popoverPresentationController?.sourceView = mapView
                    present(alertController, animated: true, completion: nil)
                } else {
                    let point = sender.location(in: mapView)
                    let coordinates = mapView.convert(point, toCoordinateFrom: mapView)
                    let waypoint = Waypoint(position: GPSLocation(latitude: coordinates.latitude, longitude: coordinates.longitude), altitude: 0, speed: 0)
                    waypointList.append(waypoint)
                    Analytics.logEvent("waypoint_added", parameters: nil)
                }
                return
            }
            
            var title: String? = nil
            var message: String? = nil
            if config.isINav {
                if !settings.isModeOn(.GCS_NAV, forStatus: config.mode) {
                    title = "GCS Mode"
                    message = "Enable GCS NAV mode to enable direct-to navigation"
                }
            } else {
                if !settings.positionHoldMode {
                    title = "Waypoint"
                    message = "Enable GPS HOLD mode to enable waypoint navigation"
                }
            }
            if message != nil {
                let alertController = UIAlertController(title: title, message: message!, preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                alertController.popoverPresentationController?.sourceView = mapView
                present(alertController, animated: true, completion: nil)
                
                return
            }
            
            let point = sender.location(in: mapView)
            let coordinates = mapView.convert(point, toCoordinateFrom: mapView)
            
            message = String(format: "Navigate to location %@ %.04f, %@ %.04f ?", locale: Locale.current, coordinates.latitude >= 0 ? "N" : "S", abs(coordinates.latitude), coordinates.longitude >= 0 ? "E" : "W", abs(coordinates.longitude))
            let alertController = UIAlertController(title: "Waypoint", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { alertController in
                // TODO allow to set altitude
                self.msp.setGPSHoldPosition(latitude: coordinates.latitude, longitude: coordinates.longitude, altitude: 0, callback: nil)
                Analytics.logEvent("waypoint_goto", parameters: nil)
            }))
            alertController.popoverPresentationController?.sourceView = mapView
            present(alertController, animated: true, completion: nil)

        }
    }
    
    @IBAction func rssiViewTapped(_ sender: Any) {
        appDelegate.showBtRssi = !appDelegate.showBtRssi
        rssiImg.image = UIImage(named: appDelegate.showBtRssi ? "btrssi" : "signal")
        let config = Configuration.theConfig
        rssiLabel.rssi = appDelegate.showBtRssi ? config.btRssi : config.rssi
    }
    
    @IBAction func uploadWaypoints(_ sender: Any) {
        appDelegate.stopTimer()
        SVProgressHUD.show(withStatus: "Uploading waypoints")
        let inavState = INavState.theINavState
        inavState.waypoints.removeAll()
        for (i, wpAnnot) in waypointList.enumerate() {
            var wp = wpAnnot.waypoint
            wp.number = i + 1
            wp.last = i == waypointList.count - 1
            inavState.waypoints.append(wp)
        }
        let commands: [SendCommand] = [
            { callback in
                self.msp.sendINavWaypoints(inavState, callback: callback)
            },
            { callback in
                self.msp.saveMission() { success in
                    // Save waypoints to eeprom support may not be compiled in (Naze)
                    callback(true)
                }
            }
        ]
        chainMspSend(commands) { success in
            DispatchQueue.main.async {
                if success {
                    self.uploadButton.isHidden = true
                    Analytics.logEvent("waypoints_uploaded", parameters: ["count" : inavState.waypoints.count])
                    self.downloadWaypoints()
                } else {
                    self.appDelegate.startTimer()
                    SVProgressHUD.showError(withStatus: "Error uploading waypoints")
                    Analytics.logEvent("waypoints_upload_failed", parameters: ["count" : inavState.waypoints.count])
                }
            }
        }
    }
}

class MKAircraftView : MKAnnotationView {
    let Size: CGFloat = 26.0
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.frame.size.width = Size
        self.frame.size.height = Size
        
        self.isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.frame.size.width = Size
        self.frame.size.height = Size
        
        self.isOpaque = false
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        
        ctx.translateBy(x: Size / 2, y: Size / 2)
        var rotation = SensorData.theSensorData.heading
        if rotation > 180 {
            rotation -= 360
        }
        ctx.rotate(by: CGFloat(rotation * .pi / 180))
        
        let actualSize = Size - 4
        UIColor.white.withAlphaComponent(0.8).setFill()
        let dx = actualSize * CGFloat(sin(Float.pi / 8))
        ctx.move(to: CGPoint(x: 0, y: -actualSize / 2))
        ctx.addLine(to: CGPoint(x: -dx, y: actualSize / 2))
        ctx.addLine(to: CGPoint(x: 0, y: actualSize / 2 - 4))
        ctx.addLine(to: CGPoint(x: dx, y: actualSize / 2))
        ctx.closePath()
        ctx.fillPath()
        
        //        UIColor.whiteColor().setFill()
        //        CGContextFillEllipseInRect(ctx, bounds)
        //        let centerRect = bounds.insetBy(dx: 3.5, dy: 3.5)
        //        UIColor.redColor().setFill()
        //        CGContextFillEllipseInRect(ctx, centerRect)
        
        ctx.restoreGState()
    }
}
