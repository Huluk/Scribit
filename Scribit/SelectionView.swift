//
//  SelectionView.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-04-13.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

import Cocoa

class SelectionView: NSView {
    let borderColor = NSColor.blueColor()
    let fillColor = NSColor.clearColor()
    var dashPattern:CGFloat = 5
    
    var origin = NSPoint()
    var selection = NSRect()
    
    func selectTo(point: NSPoint) {
        let minX = min(origin.x, point.x)
        let minY = min(origin.y, point.y)
        selection = NSMakeRect(minX, minY, max(origin.x, point.x)-minX, max(origin.y, point.y)-minY)
        needsDisplay = true
    }
    
    override func drawRect(dirtyRect: NSRect) {
        let path = NSBezierPath(rect: selection)
        path.setLineDash(&dashPattern, count: 1, phase: 0)
        borderColor.setStroke()
        path.stroke()
        fillColor.setFill()
        path.fill()
    }
    
}
