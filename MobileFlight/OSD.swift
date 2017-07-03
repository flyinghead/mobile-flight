//
//  OSD.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 14/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

enum VideoMode : Int {
    case Auto = 0
    case PAL = 1
    case NTSC = 2
    
    var lines: Int {
        switch self {
        case NTSC:
            return NTSC_LINES
        default:
            return PAL_LINES
        }
    }
    
    static let descriptions = [ "Auto", "PAL", "NTSC" ]
}

enum UnitMode : Int {
    case Imperial = 0
    case Metric = 1
    
    static let descriptions = [ "Imperial", "Metric" ]
}

class OSD {
    static var theOSD = OSD()
    
    var supported = false
    var videoMode = VideoMode.Auto
    var unitMode = UnitMode.Imperial
    var elements = [OSDElementPosition]()
    var fontDefinition: FontDefinition!
    var fontName: String!
    
    var rssiAlarm = 20
    var capacityAlarm = 2200
    var minutesAlarm = 10
    var altitudeAlarm = 100
    
    init() {
        loadFont(UserDefault.OSDFont.stringValue ?? "digital")
        
        // For Debug
        /*
        elements = [OSDElementPosition]()
        for e in OSDElement.Elements {
            let (x, y, visible, _) = e.defaultPosition()
            let position = OSDElementPosition()
            position.element = e
            position.visible = visible
            position.x = x
            position.y = y
            elements.append(position)
        }
         */
    }

    func loadFont(name: String) {
        if fontName != nil && fontName == name {
            return
        }
        let url = NSBundle.mainBundle().URLForResource(name, withExtension: "mcm")!
        fontDefinition = FontDefinition.load(url)
        fontName = name
        UserDefault.OSDFont.setValue(name)
    }
}
