//
//  Line.swift
//  Scribit
//
//  Created by Lars Hansen on 2015-12-29.
//  Copyright © 2015 Lars Hansen. All rights reserved.
//

import Cocoa

class Line: NSObject, NSCoding {

    var start: NSPoint
    var end: NSPoint
    var color: NSColor
    
    init(from: NSPoint, to: NSPoint, color: NSColor) {
        self.start = from
        self.end = to
        self.color = color
    }
    
    required init(coder: NSCoder) {
        self.start = coder.decodePoint()
        self.end = coder.decodePoint()
        self.color = coder.decodeObject() as! NSColor
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodePoint(start)
        coder.encodePoint(end)
        coder.encodeObject(color)
    }
}
