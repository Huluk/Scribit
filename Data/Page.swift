//
//  Page.swift
//  Scribit
//
//  Created by Lars Hansen on 2015-12-29.
//  Copyright © 2015 Lars Hansen. All rights reserved.
//

import Cocoa

class Page: NSObject, NSCoding {
    var bounds: NSRect
    var backgroundColor: NSColor
    var lines = [Line]()
    
    init(pageRect: NSRect, backgroundColor: NSColor) {
        self.bounds = pageRect
        self.backgroundColor = backgroundColor
    }
    
    required init(coder: NSCoder) {
        bounds = coder.decodeRect()
        backgroundColor = coder.decodeObject() as! NSColor
        lines = coder.decodeObject() as! [Line]
    }
    
    func addLine(line: Line) {
        lines.append(line)
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeRect(bounds)
        coder.encodeObject(backgroundColor)
        coder.encodeObject(lines)
    }
    
    func size() -> NSSize {
        return bounds.size
    }
}
