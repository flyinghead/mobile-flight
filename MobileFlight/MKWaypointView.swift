//
//  MKWaypointView.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 02/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
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
import SwiftSVG

class MKWaypointView : MKAnnotationView {
    fileprivate let svgHeight: CGFloat = 46.412
    fileprivate var svgShapeLayer: CAShapeLayer!
    
    weak var parentViewController: MapViewController!
    weak var waypointList: MKWaypointList!
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        localInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        localInit()
    }
    
    fileprivate func localInit() {
        self.frame.size.width = svgHeight * 1.5
        self.frame.size.height = svgHeight * 1.5
        
        self.isOpaque = false
        self.centerOffset = CGPoint(x: 0, y: -self.frame.size.height / 2)
        self.calloutOffset = CGPoint(x: 0, y: 0.333 * self.frame.size.height)
        self.isDraggable = true
        self.canShowCallout = true
        
        let button = UIButton(type: .detailDisclosure)
        button.addTarget(self, action: #selector(detailButtonTapped), for: .touchUpInside)
        rightCalloutAccessoryView = button
        
        svgShapeLayer = CAShapeLayer(pathString: "M39.652,16.446C39.652,7.363,32.289,0,23.206,0C14.124,0,6.761,7.363,6.761,16.446c0,1.775,0.285,3.484,0.806,5.086h0 c0,0,1.384,6.212,15.536,24.742c8.103-10.611,12.018-17.178,13.885-20.857C38.67,22.836,39.652,19.756,39.652,16.446z M23.024,27.044c-5.752,0-10.416-4.663-10.416-10.416c0-5.752,4.664-10.415,10.416-10.415s10.416,4.663,10.416,10.415 C33.439,22.381,28.776,27.044,23.024,27.044z M23.206,46.412c-0.036-0.047-0.07-0.092-0.105-0.139c-0.036,0.047-0.07,0.091-0.106,0.139H23.206z")
        svgShapeLayer.transform = CATransform3DMakeTranslation(svgHeight * 0.25, svgHeight * 0.5, 0)
        layer.addSublayer(svgShapeLayer)
        didSelect()
    }
    
    func didSelect() {
        if waypointList?.activeWaypoint == annotation as? MKWaypoint {
            svgShapeLayer.fillColor = UIColor.red.cgColor
        } else if isHighlighted || isSelected || dragState == .dragging {
            svgShapeLayer.fillColor = UIColor.white.cgColor
        } else {
            svgShapeLayer.fillColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.8).cgColor
        }
        setNeedsDisplay()
    }
    
    override func setDragState(_ newDragState: MKAnnotationViewDragState, animated: Bool) {
        switch newDragState {
        case .starting:
            dragState = .dragging
            didSelect()
            svgShapeLayer.transform = CATransform3DMakeScale(1.5, 1.5, 1)
        case .canceling, .ending:
            dragState = .none
            didSelect()
            svgShapeLayer.transform = CATransform3DMakeTranslation(svgHeight * 0.25, svgHeight * 0.5, 0)
        default:
            super.setDragState(newDragState, animated: animated)
        }
    }
    
    @objc fileprivate func detailButtonTapped() {
        let index = waypointList.indexOf(annotation as! MKWaypoint)!
        NSLog("Waypoint %d tapped", index + 1)
        let storyboard = UIStoryboard(name: "Mission", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "WaypointViewController")

        let waypointVC = viewController.childViewControllers.first as! WaypointViewController
        waypointVC.waypointList = waypointList
        waypointList.index = index
        
        self.parentViewController.present(viewController, animated: true, completion: nil)
    }
}
