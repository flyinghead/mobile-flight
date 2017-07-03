//
//  MKHomeLocationView.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 10/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import MapKit
import SwiftSVG

class MKHomeLocationView: MKAnnotationView {
    private let svgHeight: CGFloat = 46.412
    private var svgShapeLayer: CAShapeLayer!

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        localInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        localInit()
    }

    private func localInit() {
        self.frame.size.width = svgHeight * 1.5
        self.frame.size.height = svgHeight * 1.5
        
        self.opaque = false
        self.centerOffset = CGPoint(x: 0, y: -self.frame.size.height / 2)
        self.calloutOffset = CGPoint(x: 0, y: 0.333 * self.frame.size.height)
        self.draggable = false
        self.canShowCallout = true
        
        let svgUrl = NSBundle.mainBundle().URLForResource("home-waypoint", withExtension: "svg")!

        svgShapeLayer = CAShapeLayer(SVGURL: svgUrl)
        svgShapeLayer.transform = CATransform3DMakeTranslation(svgHeight * 0.25, svgHeight * 0.5, 0)
        //svgShapeLayer.fillColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.8).CGColor
        layer.addSublayer(svgShapeLayer)
    }
}
