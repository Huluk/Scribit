//
//  LineView.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-02-27.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

import Cocoa

class LineView: NSView {
    unowned var line: Line
    var content: [(NSColor, NSBezierPath, NSRect)]
    
    init(line: Line, frame: NSRect) {
        self.line = line
        self.content = line.drawingContent(fromIndex: 0)
        super.init(frame: frame)
        setBoundsOrigin()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update() {
        content.appendContentsOf(line.drawingContent(fromIndex: content.count))
        needsDisplay = true
    }
    
    func refresh() {
        content = line.drawingContent(fromIndex: 0)
        needsDisplay = true
        setBoundsOrigin()
    }
    
    func setBoundsOrigin() {
        let center = line.coordTransformLocalToGlobal.transformPoint(NSPoint())
        setBoundsOrigin(NSMakePoint(-center.x, -center.y))
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        let brushSize = line.widestSize / 2
        let expandedDirtyRect = NSMakeRect(
            dirtyRect.origin.x - brushSize,
            dirtyRect.origin.y - brushSize,
            dirtyRect.width + 2*brushSize,
            dirtyRect.height + 2*brushSize)
        for (color, path, bounds) in content {
            if NSIntersectsRect(bounds, expandedDirtyRect) {
                color.set()
                path.stroke()
            }
        }
    }
}
