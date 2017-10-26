//
//  OSDElementView.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 14/05/17.
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

class OSDElementView: UIView {
    var position: OSDElementPosition

    var selected = false {
        didSet {
            if selected {
                self.layer.borderWidth = 2
                self.layer.borderColor = UIColor.red.cgColor
            } else {
                self.layer.borderWidth = 0
            }
            setNeedsDisplay()
        }
    }
    var dragged = false {
        didSet {
            if dragged {
                self.layer.borderWidth = 4
                self.layer.borderColor = UIColor.red.cgColor
            } else if selected {
                self.layer.borderWidth = 2
                self.layer.borderColor = UIColor.red.cgColor
            } else {
                self.layer.borderWidth = 0
            }
            setNeedsDisplay()
        }
    }
    
    init(frame: CGRect, position: OSDElementPosition) {
        self.position = position
        super.init(frame: frame)
        localInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.position = OSDElementPosition() // Not used
        super.init(coder: aDecoder)
        localInit()
    }

    fileprivate func localInit() {
        self.isOpaque = false
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        
        ctx.clip(to: bounds.insetBy(dx: layer.borderWidth, dy: layer.borderWidth))
        ctx.saveGState()
        switch position.element! {
        case .horizonSidebars:
            let charWidth = superview!.bounds.width / CGFloat(CHARS_PER_LINE)
            let charHeight = superview!.bounds.height / CGFloat(OSD.theOSD.videoMode.lines)
            for (x, y, string) in position.element.multiplePreviews()! {
                drawString(ctx, x: CGFloat(x - 7) * charWidth, y: CGFloat(y - 3) * charHeight, string: string)
            }
        default:
            drawString(ctx, x: 0, y: 0, string: position.element.preview)
        }
        
        ctx.restoreGState()
    }
    
    fileprivate func drawString( _ ctx: CGContext, x: CGFloat, y: CGFloat, string: String) {
        let viewSize = superview!.bounds.size
        let pixelSize = CGSize(width: viewSize.width / CGFloat(CHARS_PER_LINE) / CGFloat(CharDefinition.Width), height: viewSize.height / CGFloat(OSD.theOSD.videoMode.lines) / CGFloat(CharDefinition.Height))

        var xCopy = CGFloat(x)
        for c in string.characters {
            let s = String(c).unicodeScalars
            let asciiCode = Int(s[s.startIndex].value)
            let charDef = OSD.theOSD.fontDefinition.chars[asciiCode]
            for line in 0 ..< CharDefinition.Height {
                for col in 0 ..< CharDefinition.Width {
                    let pixel = charDef.pixels[line][col]
                    switch pixel {
                    case .black:
                        ctx.setFillColor(UIColor.black.cgColor)
                    case .white:
                        ctx.setFillColor(UIColor.white.cgColor)
                    case .transparent:
                        continue
                    }
                    ctx.fill(CGRect(x: xCopy + CGFloat(col) * pixelSize.width, y: y + CGFloat(line) * pixelSize.height, width: pixelSize.width, height: pixelSize.height))
                }
            }
            xCopy += CGFloat(CharDefinition.Width) * pixelSize.width
        }
    }
}
