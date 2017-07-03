//
//  CharDefinition.swift
//  Mobile Flight
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
    
    func writeToOsd(msp: MSPParser, index: Int, callback: ((Bool) -> Void)?) {
        var data = [UInt8]()
        for line in 0 ..< pixels.count {
            var shift = UInt8(6)
            var byte = UInt8(0)
            for col in 0 ..< pixels[line].count {
                var pixel: UInt8
                switch pixels[line][col] {
                case .Black:
                    pixel = 0
                case .Transparent:
                    pixel = 1
                case .White:
                    pixel = 2
                }
                pixel <<= shift
                byte |= pixel
                if shift == 0 {
                    shift = 6
                    data.append(byte)
                    byte = 0
                } else {
                    shift -= 2
                }
            }
        }
        msp.sendOsdChar(index, data: data, callback: callback)
    }
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
    
    func writeToOsd(msp: MSPParser, progressCallback: ((Float) -> Void)?, callback: ((Bool) -> Void)?) {
        writeCharToOsd(msp, index: 0, progressCallback: progressCallback, callback: callback)
    }
    
    private func writeCharToOsd(msp: MSPParser, index: Int, progressCallback: ((Float) -> Void)?, callback: ((Bool) -> Void)?) {
        if index >= chars.count {
            callback?(true)
            return
        }
        chars[index].writeToOsd(msp, index: index) { success in
            if success {
                progressCallback?(Float(index + 1) / Float(self.chars.count))
                self.writeCharToOsd(msp, index: index + 1, progressCallback: progressCallback, callback: callback)
            } else {
                callback?(false)
            }
        }
    }
}
