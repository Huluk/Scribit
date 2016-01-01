//
//  Line.swift
//  Scribit
//
//  Created by Lars Hansen on 2015-12-29.
//  Copyright © 2015 Lars Hansen. All rights reserved.
//

import Cocoa

class Line: NSObject, NSCoding {

    var segments = [LineSegment]()
    var color: NSColor
    
    init(color: NSColor) {
        self.color = color
    }
    
    required init(coder: NSCoder) {
        let codedSegments = coder.decodeObject() as! [LineSegment.CodingHelper]
        self.segments = codedSegments.map {$0.get()}
        self.color = coder.decodeObject() as! NSColor
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(segments.map {LineSegment.CodingHelper(segment: $0)})
        coder.encodeObject(color)
    }
    
    func addSegment(segment: LineSegment) {
        segments.append(segment)
    }
    
    func bezierPath() -> NSBezierPath {
        let path = NSBezierPath()
        path.lineCapStyle = NSLineCapStyle.RoundLineCapStyle
        for segment in segments {
            path.moveToPoint(segment.start)
            path.lineToPoint(segment.end)
        }
        return path
    }
}
