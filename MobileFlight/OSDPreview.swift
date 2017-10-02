//
//  OSDPreview.swift
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

class OSDPreview: UIView, UIGestureRecognizerDelegate {
    let image = UIImage(named: "OSD-background")!
    
    var backgroundView: UIImageView!
    var tapGesture: UITapGestureRecognizer!
    var dragGesture: UIPanGestureRecognizer!
    var draggedView: OSDElementView?
    var dragStartDelta: CGSize?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        localInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        localInit()
    }
    
    private func localInit() {
        backgroundView = UIImageView(image: image)
        backgroundView.contentMode = .ScaleAspectFit
        backgroundView.frame = bounds
        addSubview(backgroundView)

        createElementViews()
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        dragGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrag))
        dragGesture.maximumNumberOfTouches = 1
        dragGesture.delegate = self
        addGestureRecognizer(dragGesture)
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        if size.height / size.width > image.size.height / image.size.width {
            return CGSize(width: size.width, height: size.width * image.size.height / image.size.width)
        } else {
            return CGSize(width: size.height * image.size.width / image.size.height, height: size.height)
        }
    }
    
    private func calcSubviewFrame(elem: OSDElement, x: Int, y: Int) -> CGRect {
        let charWidth = bounds.width / CGFloat(CHARS_PER_LINE)
        let charHeight = bounds.height / CGFloat(OSD.theOSD.videoMode.lines)
        switch elem {
        case .HorizonSidebars:
            return CGRect(x: 7 * charWidth, y: 3 * charHeight, width: 15 * charWidth, height: 7 * charHeight)
        case .ArtificialHorizon, .Crosshairs:
            return CGRect(x: CGFloat(elem.defaultPosition().x) * charWidth, y: CGFloat(elem.defaultPosition().y) * charHeight, width: CGFloat(elem.preview.characters.count) * charWidth, height: charHeight)
        default:
            return CGRect(x: CGFloat(x) * charWidth, y: CGFloat(y) * charHeight, width: CGFloat(elem.preview.characters.count) * charWidth, height: charHeight)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        for v in subviews {
            if let elemView = v as? OSDElementView {
                let e = elemView.position.element
                elemView.frame = calcSubviewFrame(e, x: elemView.position.x, y: elemView.position.y)
            }
            else {
                v.frame = bounds
            }
        }
    }
    
    @objc private func handleTap(tapGesture: UITapGestureRecognizer) {
        if tapGesture.state == .Ended {
            let location = tapGesture.locationInView(self)
            let subView = hitTest(location, withEvent: nil)
            selectElement(subView)
        }
    }
    
    private func selectElement(selection: UIView?) {
        for view in subviews {
            if let elemView = view as? OSDElementView {
                if elemView === selection && elemView.position.element.positionable {
                    elemView.selected = true
                } else {
                    elemView.selected = false
                }
            }
        }
    }
    
    @objc private func handleDrag(tapGesture: UITapGestureRecognizer) {
        let location = tapGesture.locationInView(self)
        
        if tapGesture.state == .Began {
            if let elemView = hitTest(location, withEvent: nil) as? OSDElementView where elemView.position.element.positionable && elemView.selected {
                draggedView = elemView
                elemView.dragged = true
                dragStartDelta = CGSize(width: location.x - elemView.frame.minX, height: location.y - elemView.frame.minY)
            }
        }
        if draggedView != nil {
            var origin = CGPoint(x: location.x - dragStartDelta!.width, y: location.y - dragStartDelta!.height)
            // Snap to character grid
            let charSize = CGSize(width: bounds.width / CGFloat(CHARS_PER_LINE), height: bounds.height / CGFloat(OSD.theOSD.videoMode.lines))
            draggedView!.position.x = Int(round(origin.x / charSize.width))
            draggedView!.position.y = Int(round(origin.y / charSize.height))
            origin.x = CGFloat(draggedView!.position.x) * charSize.width
            origin.y = CGFloat(draggedView!.position.y) * charSize.height
            draggedView!.frame.origin = origin
        }
        if tapGesture.state == .Ended {
            draggedView?.dragged = false
            draggedView = nil
        }
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer !== dragGesture {
            return true
        }
        let location = gestureRecognizer.locationInView(self)
        if let elemView = hitTest(location, withEvent: nil) as? OSDElementView where elemView.position.element.positionable && elemView.selected {
            return true
        } else {
            return false
        }
    }
    
    func createElementViews() {
        let osd = OSD.theOSD
        for e in osd.elements {
            let frame = calcSubviewFrame(e.element, x: e.x, y: e.y)
            let view = OSDElementView(frame: frame, position: e)
            view.hidden = !e.visible
            addSubview(view)
        }
        // Send non selectionable views to the back so they don't capture taps
        for v in subviews {
            if let elemView = v as? OSDElementView where !elemView.position.element.positionable {
                sendSubviewToBack(elemView)
            }
        }
        // Background needs to be at the very back
        sendSubviewToBack(backgroundView)
    }
    
    func updateVisibleViews() {
        for view in subviews {
            if let elemView = view as? OSDElementView {
                if elemView.hidden == elemView.position.visible {
                    elemView.hidden = !elemView.position.visible
                    selectElement(elemView)
                }
                elemView.setNeedsDisplay()
            }
        }
    }
}
