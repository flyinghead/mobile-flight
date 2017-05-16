//
//  CharDefinition.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 14/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

let FONTS = [ "default", "digital", "cleanflight", "bold", "large", "extra_large" ]

enum PixelColor : Int {
    case Black = 0
    case Transparent = 1
    case White = 2
}

class CharDefinition {
    static let Height = 18
    static let Width = 12
    
    var pixels = [[PixelColor]]()
}

class FontDefinition {
    var chars = [CharDefinition]()
    
    class func load(url: NSURL) -> FontDefinition? {
        do {
            let string = try String(contentsOfURL: url)
            let lines: [String]
            if string.containsString("\r\n") {
                lines = string.componentsSeparatedByString("\r\n")
            } else {
                lines = string.componentsSeparatedByString("\n")
            }
                
            if lines.isEmpty || "MAX7456" != lines.first! {
                return nil
            }
            let fontDef = FontDefinition()
            var charDef = CharDefinition()
            var curLine = [PixelColor]()
            var skipLines = 0
            for line in lines.dropFirst() {
                if line.characters.count < 8 {
                    continue
                }
                if skipLines > 0 {
                    skipLines -= 1
                    continue
                }
                var index = line.startIndex
                for _ in 0 ..< 4 {
                    let endIndex = index.advancedBy(2)
                    let pixel = Int(line.substringWithRange(index ..< endIndex), radix: 2)!
                    curLine.append(PixelColor(rawValue: pixel)!)
                    index = endIndex
                }
                if curLine.count == CharDefinition.Width {
                    charDef.pixels.append(curLine)
                    curLine = [PixelColor]()
                    if charDef.pixels.count == CharDefinition.Height {
                        fontDef.chars.append(charDef)
                        charDef = CharDefinition()
                        skipLines = 10
                    }
                }
            }
            
            return fontDef
        } catch let error as NSError {
            NSLog("Error loading font file %@", error)
            return nil
        }
    }
}
