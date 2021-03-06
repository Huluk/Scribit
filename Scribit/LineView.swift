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
        let newContent = line.drawingContent(fromIndex: content.count)
        content.appendContentsOf(newContent)
        let contentRect = newContent.reduce(NSRect(), combine: {NSUnionRect($0, $1.2)})
        setNeedsDisplayInRect(line.rectWithDrawingMargin(contentRect))
    }
    
    func refresh() {
        content = line.drawingContent(fromIndex: 0)
        setBoundsOrigin()
    }
    
    func setBoundsOrigin() {
        let center = line.coordTransformGlobalToLocal.transformPoint(NSPoint())
        setBoundsOrigin(center)
        needsDisplay = true
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        let expandedDirtyRect = line.rectWithDrawingMargin(dirtyRect)
        for (color, path, bounds) in content {
            if NSIntersectsRect(bounds, expandedDirtyRect) {
                color.set()
                path.stroke()
            }
        }
    }
}
