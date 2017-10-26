//
//  MKHomeLocationView.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 10/05/17.
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

class MKHomeLocationView: MKAnnotationView {
    fileprivate let svgHeight: CGFloat = 46.412
    fileprivate var svgShapeLayer: CAShapeLayer!

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
        self.isDraggable = false
        self.canShowCallout = true
        
        let svgUrl = Bundle.main.url(forResource: "home-waypoint", withExtension: "svg")!
        do {
            let string = try String(contentsOf: svgUrl)
            let svgShapeLayer = CAShapeLayer(pathString: string)
            svgShapeLayer.transform = CATransform3DMakeTranslation(svgHeight * 0.25, svgHeight * 0.5, 0)
            //svgShapeLayer.fillColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.8).CGColor
            layer.addSublayer(svgShapeLayer)
        } catch {
            NSLog("Cannot load HomeLocation svg")
        }
    }
}
